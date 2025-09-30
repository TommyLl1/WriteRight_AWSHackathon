"""
Enhanced Question Generation Service

This service implements a comprehensive question generation system with the following logic:
1. Fetches revision words using existing logic (returns at most N words)
2. Uses a single database call to fetch all unflagged questions for those words (max 50 per word)
3. Scores questions for "goodness" based on age and random factors
4. Uses AI to generate questions if existing ones aren't good enough
5. Falls back to recycling "not good enough" questions if AI fails
6. Uses any non-flagged questions as final fallback, or returns 500 error
"""

from typing import List, Dict, Optional, Any, Callable, Awaitable, Tuple, Set
from uuid import UUID
import random
import asyncio
import math
import numpy as np
from dataclasses import dataclass
from utils.logger import setup_logger
from utils.config import config
from utils.storage_service import StorageController
from utils.rpc_service import RPCService
from features.LLM_request_manager import LLMRequestManager
from features.question_generator import QuestionGenerator

# Import models
from models.QnA import *
from models.services import UserWrongChar
from models.LLM import AIQuestionType
from models.helpers import (
    ChineseChar,
    get_time,
    to_unicodeInt_from_char,
    to_char_from_unicode,
    UUIDStr,
    APIResponse,
)
from models.db.db import SupabaseRPC, SupabaseTable, QuestionEntry

# Import necessary services
from utils.database.base import DatabaseService
from features.word_service import WordService
from features.user_service import UserService

logger = setup_logger(__name__, level="DEBUG")


@dataclass
class ScoredQuestion:
    """Represents a question with its quality score."""

    question_entry: QuestionEntry
    score: float
    word_id: int


@dataclass
class WordQuestionBatch:
    """Represents all questions for a specific word."""

    word_id: int
    word: ChineseChar
    questions: List[QuestionEntry]
    scored_questions: List[ScoredQuestion]
    good_questions: List[ScoredQuestion]
    not_good_questions: List[ScoredQuestion]


NEVER_OUTDATED_QUESTION_TYPES = [
    QuestionType.COPY_STROKE,
]


class EnhancedQuestionService:
    """
    Enhanced question generation service implementing the 6-step generation logic.
    """

    def __init__(
        self,
        db: DatabaseService,
        word_service: WordService,
        user_service: UserService,
        llm_request_manager: LLMRequestManager,
        storage_service: StorageController,
        question_statistics_service: RPCService,
    ):
        self.db = db
        self.word_service = word_service
        self.user_service = user_service
        self.llm_request_manager = llm_request_manager
        self.storage_service = storage_service
        self.question_statistics_service = question_statistics_service

        # Configuration
        self.time_weight = config.get("QuestionGenerator.Weighting.Time", 1.0)
        self.count_weight = config.get("QuestionGenerator.Weighting.Count", 2.0)
        self.max_words = config.get("QuestionGenerator.MaxWords", 20)
        self.max_questions_per_word = config.get(
            "QuestionGenerator.MaxQuestionsPerWord", 50
        )
        self.question_goodness_threshold = config.get(
            "QuestionGenerator.GoodnessThreshold", 0.6
        )
        self.age_decay_hours = config.get(
            "QuestionGenerator.AgeDecayHours", 168
        )  # 1 week
        self.revision_meu = config.get(
            "QuestionGenerator.RevisionPriority.Randomness", 50
        )
        self.revision_sigma = config.get(
            "QuestionGenerator.RevisionPriority.RandomSigma", 10
        )
        self.question_classify_sigmoid_steepness = config.get(
            "QuestionGenerator.QuestionClassify.SigmoidSteepness", 10
        )
        self.max_never_outdated_questions = config.get(
            "QuestionGenerator.MaxNeverOutdatedQuestions", 3
        )

        # Available question types
        self.available_question_types = [
            QuestionType.COPY_STROKE,
            QuestionType.FILL_IN_VOCAB,
            QuestionType.FILL_IN_SENTENCE,
            QuestionType.LISTENING,
        ]

        # Initialize the consolidated question generator for fallback
        self.question_generator = QuestionGenerator(
            db=db,
            llm_request_manager=llm_request_manager,
            storage_service=storage_service,
        )

    async def get_revision_words(
        self, user_id: UUIDStr, max_words: Optional[int] = None
    ) -> List[UserWrongChar]:
        """
        Step 1: Fetch revision words using probability-based selection.
        Uses priorities as weights for more sophisticated word selection.
        Returns at most N words back.
        """
        if max_words is None:
            max_words = self.max_words

        # Ensure max_words is not None
        assert max_words is not None, "max_words must be set"

        logger.debug(
            f"Fetching revision words for user {user_id}, max_words: {max_words}"
        )

        # Get user's wrong words
        wrong_word_dict = await self.user_service.get_user_wrong_words(user_id=user_id)

        if not wrong_word_dict:
            logger.warning(
                f"No wrong words found for user {user_id}, falling back to random words"
            )
            # If no wrong words, get random words
            random_words = await self.word_service.get_random_words(count=max_words)
            return [
                UserWrongChar(
                    word=word.word,
                    word_id=word.word_id,
                    wrong_count=0,
                    last_wrong_at=get_time(),
                    priority=0.0,
                )
                for word in random_words
            ]

        # Calculate revision candidates using existing logic
        revision_candidates = self._calculate_revision_words(wrong_word_dict)

        # If we have fewer or equal candidates than needed, use all and fill with random
        if len(revision_candidates) <= max_words:
            selected_candidates = revision_candidates[:]

            # Fill remaining slots with random words if needed
            if len(selected_candidates) < max_words:
                remaining_count = max_words - len(selected_candidates)
                existing_word_ids = {char.word_id for char in selected_candidates}

                random_words = await self.word_service.get_random_words(
                    count=remaining_count * 2
                )  # Get extra in case of overlap

                for word in random_words:
                    if (
                        word.word_id not in existing_word_ids
                        and len(selected_candidates) < max_words
                    ):
                        selected_candidates.append(
                            UserWrongChar(
                                word=word.word,
                                word_id=word.word_id,
                                wrong_count=0,
                                last_wrong_at=get_time(),
                                priority=0.0,
                            )
                        )
                        existing_word_ids.add(word.word_id)

            logger.info(
                f"Selected {len(selected_candidates)} revision words for user {user_id} (used all available)"
            )
            return selected_candidates

        # We have more candidates than needed, use probability-based selection
        rng = np.random.default_rng()

        # Extract priorities and handle edge cases
        priorities = [char.priority or 0.0 for char in revision_candidates]

        # Handle negative priorities by shifting to make all non-negative
        min_priority = min(priorities)
        if min_priority < 0:
            priorities = [p - min_priority for p in priorities]

        # Handle case where all priorities are zero
        total_priority = sum(priorities)
        if total_priority == 0:
            # Fall back to uniform selection
            indices = rng.choice(
                len(revision_candidates), size=max_words, replace=False
            )
            selected_candidates = [revision_candidates[i] for i in indices]

            logger.info(
                f"Selected {len(selected_candidates)} revision words for user {user_id} (uniform selection - zero priorities)"
            )
            return selected_candidates

        # Normalize priorities to create proper probability weights
        normalized_weights = [p / total_priority for p in priorities]

        # Create indices array for numpy choice
        indices = np.arange(len(revision_candidates))

        # Select indices based on probability weights (without replacement)
        selected_indices = rng.choice(
            indices, size=max_words, replace=False, p=normalized_weights
        )

        # Get the selected candidates
        selected_candidates = [revision_candidates[i] for i in selected_indices]

        logger.info(
            f"Selected {len(selected_candidates)} revision words for user {user_id} (probability-based selection)"
        )
        return selected_candidates

    async def fetch_questions_for_words(
        self, words: List[UserWrongChar]
    ) -> List[WordQuestionBatch]:
        """
        Step 2: Using a single database call, fetch all unflagged questions for those words.
        Only the first 50 questions of each word should be returned using lateral join.
        """
        if not words:
            return []

        word_ids = [word.word_id for word in words]
        logger.debug(f"Fetching questions for {len(word_ids)} words")

        # Build the lateral join query to get at most max_questions_per_word questions per word
        query = f"""
        SELECT t_limited.*
        FROM (
            SELECT DISTINCT target_word_id
            FROM questions q
            WHERE q.target_word_id = ANY($word_ids)
            AND q.question_id NOT IN (
                SELECT DISTINCT fq.question_id 
                FROM flagged_questions fq
            )
        ) t_groups
        JOIN LATERAL (
            SELECT *
            FROM questions q_all
            WHERE q_all.target_word_id = t_groups.target_word_id
            AND q_all.question_id NOT IN (
                SELECT DISTINCT fq.question_id 
                FROM flagged_questions fq
            )
            ORDER BY q_all.created_at DESC
            LIMIT {self.max_questions_per_word}
        ) t_limited ON true
        ORDER BY t_limited.target_word_id, t_limited.created_at DESC
        """

        try:
            questions_response = await self.db.execute_complex_query(
                query=query,
                params={"word_ids": word_ids},
                return_type=dict,
                fetch_mode="all",
            )

            # Handle the response (following pattern from existing codebase)
            response: APIResponse = questions_response  # type: ignore

            if not response.data:
                logger.warning("No unflagged questions found for any of the words")
                return []

            # Group questions by word_id
            word_questions: Dict[int, List[QuestionEntry]] = {}
            for question_data in response.data:
                try:
                    question = QuestionEntry.model_validate(question_data)
                    word_id = question.target_word_id
                    if word_id not in word_questions:
                        word_questions[word_id] = []
                    word_questions[word_id].append(question)
                except Exception as e:
                    logger.error(f"Error validating question entry: {e}")
                    continue

            # Create WordQuestionBatch objects
            batches = []
            for word in words:
                questions = word_questions.get(word.word_id, [])
                batches.append(
                    WordQuestionBatch(
                        word_id=word.word_id,
                        word=word.word,
                        questions=questions,
                        scored_questions=[],
                        good_questions=[],
                        not_good_questions=[],
                    )
                )

            logger.info(
                f"Fetched questions for {len(batches)} words, total questions: {sum(len(batch.questions) for batch in batches)}"
            )
            return batches

        except Exception as e:
            logger.error(f"Error fetching questions for words: {e}")
            return []

    def score_question(self, question: QuestionEntry) -> float:
        """
        Score a question based on its "goodness".
        Current scoring is based on age and random factor.
        Returns a score between 0 and 1, where higher is better.
        """

        current_time = get_time()
        age_hours = (current_time - question.created_at) / 3600  # Convert to hours

        # Handle never outdated questions - normalize their age factor to prevent bias
        is_never_outdated = question.question_type in NEVER_OUTDATED_QUESTION_TYPES
        if is_never_outdated:
            # Use median age factor to prevent bias toward these questions
            age_factor = math.exp(
                -self.age_decay_hours * 0.5 / self.age_decay_hours
            )  # ~0.61
        else:
            # Age factor: newer questions get higher scores (exponential decay)
            age_factor = math.exp(-age_hours / self.age_decay_hours)

        # Random factor to add variety
        random_factor = random.random()

        # Usage factor: questions used less frequently get higher scores
        # Normalize use_count (assuming max reasonable use_count is 100)
        usage_factor = 1.0 - min(question.use_count / 100.0, 1.0)

        # Accuracy factor: questions with better accuracy get higher scores
        accuracy = question.correct_count / max(question.use_count, 1)
        accuracy_factor = 0.5 + (accuracy * 0.5)  # Scale from 0.5 to 1.0
        accuracy_factor = 1  # Disable accuracy factor for now, until we actually record the use and correct counts

        # Weighted combination
        score = (
            age_factor * 0.3
            + random_factor * 0.2
            + usage_factor * 0.3
            + accuracy_factor * 0.2
        )

        return min(max(score, 0.0), 1.0)  # Clamp to [0, 1]

    def classify_questions_by_goodness(
        self, batches: List[WordQuestionBatch]
    ) -> List[WordQuestionBatch]:
        """
        Step 3: Score and classify questions based on their "goodness".
        Uses probability-based classification where higher scores have higher probability of being classified as good.
        """
        rng = np.random.default_rng()

        # First, randomize the order of batches to prevent bias
        random.shuffle(batches)

        for batch in batches:
            # Score all questions
            for question in batch.questions:
                score = self.score_question(question)
                scored_question = ScoredQuestion(
                    question_entry=question, score=score, word_id=batch.word_id
                )
                batch.scored_questions.append(scored_question)

            # Sort by score (highest first)
            batch.scored_questions.sort(key=lambda x: x.score, reverse=True)

            # Probability-based classification
            # Transform score to probability using sigmoid-like function centered around threshold
            for scored_question in batch.scored_questions:
                # Convert score to probability of being "good"
                # Using sigmoid function: P(good) = 1 / (1 + exp(-k * (score - threshold)))
                # where k (SigmoidSteepness in config.yaml) controls the steepness of the transition
                prob_good = 1 / (
                    1
                    + np.exp(
                        -self.question_classify_sigmoid_steepness
                        * (scored_question.score - self.question_goodness_threshold)
                    )
                )

                # Generate random number and classify based on probability
                if rng.random() < prob_good:
                    batch.good_questions.append(scored_question)
                else:
                    batch.not_good_questions.append(scored_question)

            logger.debug(
                f"Word {batch.word}: {len(batch.good_questions)} good, {len(batch.not_good_questions)} not good questions (probability-based)"
            )

        return batches

    async def generate_ai_questions_for_words(
        self,
        words_needing_questions: List[Tuple[ChineseChar, QuestionType]],
        user_id: UUIDStr,
    ) -> Dict[Tuple[ChineseChar, QuestionType], Optional[QuestionBase]]:
        """
        Step 4: Use AI to generate questions for words that don't have good enough questions.
        Returns a mapping of (word, question_type) to generated questions.
        """
        if not words_needing_questions:
            return {}

        logger.info(
            f"Generating AI questions for {len(words_needing_questions)} word-type combinations"
        )

        # Group by question type for batch processing
        type_groups: Dict[QuestionType, List[ChineseChar]] = {}
        for word, qtype in words_needing_questions:
            if qtype not in type_groups:
                type_groups[qtype] = []
            type_groups[qtype].append(word)

        results: Dict[Tuple[ChineseChar, QuestionType], Optional[QuestionBase]] = {}

        # Create futures for ALL question generation tasks simultaneously
        all_futures = []
        future_mappings = []  # List of (word, qtype) tuples corresponding to futures

        # Process each question type
        for qtype, words in type_groups.items():
            logger.debug(f"Preparing {qtype.value} questions for {len(words)} words")

            if qtype in [QuestionType.COPY_STROKE, QuestionType.LISTENING]:
                # These types are generated individually, not via AI
                for word in words:
                    if qtype == QuestionType.COPY_STROKE:
                        # COPY_STROKE is synchronous, so we can generate it immediately
                        try:
                            question = (
                                self.question_generator.create_copy_stroke_question(
                                    char=word,
                                    user_id=user_id,
                                    storage_service=self.storage_service,
                                )
                            )
                            results[(word, qtype)] = question
                        except Exception as e:
                            logger.error(
                                f"Error generating {qtype.value} question for {word}: {e}"
                            )
                            results[(word, qtype)] = None
                    else:  # LISTENING
                        # LISTENING is async, so create a future
                        future = asyncio.ensure_future(
                            self.question_generator.create_listening_question(
                                char=word,
                                db=self.db,
                            )
                        )
                        all_futures.append(future)
                        future_mappings.append((word, qtype))
            else:
                # AI-generated questions (create futures for all)
                ai_question_types = {qtype.value: qtype for qtype in AIQuestionType}
                if qtype.value in ai_question_types:
                    for word in words:
                        future = asyncio.ensure_future(
                            self.question_generator.create_ai_question(
                                char=word,
                                question_type=qtype,
                                llm_request_manager=self.llm_request_manager,
                            )
                        )
                        all_futures.append(future)
                        future_mappings.append((word, qtype))

        # Wait for ALL futures to complete simultaneously
        if all_futures:
            logger.debug(
                f"Waiting for {len(all_futures)} question generation tasks to complete in parallel"
            )
            generated_results = await asyncio.gather(
                *all_futures, return_exceptions=True
            )

            # Process results and handle exceptions
            for (word, qtype), result in zip(future_mappings, generated_results):
                if isinstance(result, Exception):
                    logger.error(
                        f"Error generating {qtype.value} question for {word}: {result}"
                    )
                    results[(word, qtype)] = None
                else:
                    # result should be a QuestionBase object
                    results[(word, qtype)] = result  # type: ignore

        # Validate generated questions match target words
        validated_results = {}
        for (word, qtype), question in results.items():
            if question and question.target_word == word:
                validated_results[(word, qtype)] = question
            else:
                if question:
                    logger.warning(
                        f"Generated question for {word} doesn't match target word, dropping"
                    )
                validated_results[(word, qtype)] = None

        logger.info(
            f"Successfully generated {sum(1 for q in validated_results.values() if q is not None)} out of {len(words_needing_questions)} AI questions"
        )
        return validated_results

    async def save_generated_questions(
        self,
        generated_questions: Dict[
            Tuple[ChineseChar, QuestionType], Optional[QuestionBase]
        ],
    ) -> Dict[Tuple[ChineseChar, QuestionType], Optional[QuestionBase]]:
        """
        Save generated questions to the database and update their question_ids.
        Optimized to use batch operations for better performance.
        """
        saved_questions = {}

        # Filter out None questions and prepare for batch insert
        valid_questions: List[Tuple[Tuple[ChineseChar, QuestionType], QuestionBase]] = (
            []
        )

        for (word, qtype), question in generated_questions.items():
            if question is None:
                saved_questions[(word, qtype)] = None
                continue
            valid_questions.append(((word, qtype), question))

        if not valid_questions:
            return saved_questions

        # Convert all questions to QuestionEntry objects and prepare batch data
        batch_data = []
        question_mapping = []  # To track which question corresponds to which result

        for (word, qtype), question in valid_questions:
            try:
                question_entry = QuestionEntry.from_question_base(question)
                batch_data.append(question_entry.model_dump(exclude_none=False))
                question_mapping.append(((word, qtype), question))
            except Exception as e:
                logger.error(
                    f"Error converting {qtype.value} question for {word} to QuestionEntry: {e}"
                )
                saved_questions[(word, qtype)] = None

        if not batch_data:
            return saved_questions

        try:
            # Perform batch insert - single database call
            logger.debug(f"Batch inserting {len(batch_data)} questions")
            insert_results = await self.db.insert_data(
                SupabaseTable.QUESTIONS,
                batch_data,
            )

            # Process results and update question_ids
            if insert_results and len(insert_results) == len(question_mapping):
                for i, result in enumerate(insert_results):
                    (word, qtype), question = question_mapping[i]

                    # Update the question_id with the database-assigned ID
                    # Type-safe access to dictionary result
                    if isinstance(result, dict) and "question_id" in result:
                        question.question_id = result["question_id"]
                        saved_questions[(word, qtype)] = question

                        logger.debug(
                            f"Saved {qtype.value} question for {word} with ID: {question.question_id}"
                        )
                    else:
                        logger.error(
                            f"Invalid result format for {qtype.value} question for {word}"
                        )
                        saved_questions[(word, qtype)] = None
            else:
                logger.error(
                    f"Batch insert result count mismatch: expected {len(question_mapping)}, got {len(insert_results) if insert_results else 0}"
                )
                # Fall back to marking all as failed
                for (word, qtype), question in question_mapping:
                    saved_questions[(word, qtype)] = None

        except Exception as e:
            logger.error(f"Error in batch insert operation: {e}")
            # Fall back to marking all as failed
            for (word, qtype), question in question_mapping:
                saved_questions[(word, qtype)] = None

        logger.info(
            f"Successfully saved {sum(1 for q in saved_questions.values() if q is not None)} out of {len(generated_questions)} questions"
        )
        return saved_questions

    def _calculate_revision_words(
        self, wrong_chars: List[UserWrongChar]
    ) -> List[UserWrongChar]:
        """
        Calculate suitable words for revision based on current time, wrong count, and last wrong at.
        This adapts the existing logic from the original question service.
        """
        revision_candidates: List[UserWrongChar] = []

        for char_data in wrong_chars:
            time_gap = (get_time() - char_data.last_wrong_at) / 3600  # Convert to hours

            # Calculate priority
            priority = (
                (time_gap * self.time_weight)
                + (char_data.wrong_count * self.count_weight)
                + random.normalvariate(self.revision_meu, self.revision_sigma)
            )

            # Create new instance with calculated priority
            revision_candidates.append(
                UserWrongChar(
                    word=char_data.word,
                    word_id=char_data.word_id,
                    wrong_count=char_data.wrong_count,
                    last_wrong_at=char_data.last_wrong_at,
                    priority=priority,
                )
            )

        return revision_candidates

    async def get_fallback_questions(
        self, word_ids: List[int], needed_count: int
    ) -> List[QuestionEntry]:
        """
        Step 6: Final fallback - get any non-flagged questions from the database.
        """
        if not word_ids or needed_count <= 0:
            return []

        logger.warning(
            f"Using fallback questions for {len(word_ids)} words, need {needed_count} questions"
        )

        query = """
        SELECT * FROM questions q
        WHERE q.target_word_id = ANY($word_ids)
        AND q.question_id NOT IN (
            SELECT DISTINCT fq.question_id 
            FROM flagged_questions fq
        )
        ORDER BY q.created_at DESC
        LIMIT $needed_count
        """

        try:
            questions_response = await self.db.execute_complex_query(
                query=query,
                params={"word_ids": word_ids, "needed_count": needed_count},
                return_type=dict,
                fetch_mode="all",
            )

            # Handle the response (following pattern from existing codebase)
            response: APIResponse = questions_response  # type: ignore

            if not response.data:
                return []

            questions = []
            for question_data in response.data:
                try:
                    question = QuestionEntry.model_validate(question_data)
                    questions.append(question)
                except Exception as e:
                    logger.error(f"Error validating fallback question: {e}")
                    continue

            logger.info(f"Retrieved {len(questions)} fallback questions")
            return questions

        except Exception as e:
            logger.error(f"Error fetching fallback questions: {e}")
            return []

    def _convert_question_to_base(
        self, question_entry: QuestionEntry, user_id: UUIDStr
    ) -> Optional[QuestionBase]:
        """
        Convert a QuestionEntry to QuestionBase, handling COPY_STROKE questions specially.
        """
        try:
            if question_entry.question_type == QuestionType.COPY_STROKE:
                submit_url = self.storage_service.get_submit_url(user_id)
                return question_entry.to_question_base(submit_url=submit_url)
            else:
                return question_entry.to_question_base()
        except Exception as e:
            logger.error(f"Error converting question entry to QuestionBase: {e}")
            return None

    def _collect_good_existing_questions(
        self, word_batches: List[WordQuestionBatch], user_id: UUIDStr, count: int
    ) -> Tuple[List[QuestionBase], List[WordQuestionBatch]]:
        """
        Collect good existing questions with limits on never outdated questions.
        Returns (collected_questions, remaining_batches).
        """
        final_questions: List[QuestionBase] = []
        used_batches: Set[int] = set()
        never_outdated_count = 0

        for batch in word_batches:
            if len(final_questions) >= count:
                break

            if batch.good_questions:
                best_question = batch.good_questions[0]

                # Check if this is a never outdated question and we've reached the limit
                is_never_outdated = (
                    best_question.question_entry.question_type
                    in NEVER_OUTDATED_QUESTION_TYPES
                )

                if (
                    is_never_outdated
                    and never_outdated_count >= self.max_never_outdated_questions
                ):
                    logger.debug(
                        f"Skipping never outdated question for {batch.word} - limit reached"
                    )
                    continue

                question_base = self._convert_question_to_base(
                    best_question.question_entry, user_id
                )

                if question_base:
                    final_questions.append(question_base)
                    used_batches.add(batch.word_id)

                    if is_never_outdated:
                        never_outdated_count += 1

                    logger.debug(f"Using good existing question for word {batch.word}")

        # Return remaining batches that weren't used
        remaining_batches = [
            batch for batch in word_batches if batch.word_id not in used_batches
        ]

        logger.info(
            f"Collected {len(final_questions)} good existing questions "
            f"({never_outdated_count} never outdated)"
        )

        return final_questions, remaining_batches

    def _identify_words_needing_questions(
        self, remaining_batches: List[WordQuestionBatch], needed_count: int
    ) -> List[Tuple[ChineseChar, QuestionType]]:
        """
        Identify words that need AI-generated questions.
        """
        words_needing_questions: List[Tuple[ChineseChar, QuestionType]] = []

        for batch in remaining_batches:
            if len(words_needing_questions) >= needed_count:
                break

            question_type = random.choice(self.available_question_types)
            words_needing_questions.append((batch.word, question_type))

        return words_needing_questions

    def _collect_ai_generated_questions(
        self,
        ai_questions: Dict[Tuple[ChineseChar, QuestionType], Optional[QuestionBase]],
        needed_count: int,
    ) -> Tuple[List[QuestionBase], List[Tuple[ChineseChar, QuestionType]]]:
        """
        Collect successful AI-generated questions.
        Returns (collected_questions, failed_words).
        """
        collected_questions: List[QuestionBase] = []
        failed_words: List[Tuple[ChineseChar, QuestionType]] = []

        for (word, qtype), question in ai_questions.items():
            if len(collected_questions) >= needed_count:
                break

            if question:
                collected_questions.append(question)
                logger.debug(f"Using new AI question for word {word}")
            else:
                failed_words.append((word, qtype))

        return collected_questions, failed_words

    def _collect_recycled_questions(
        self,
        word_batches: List[WordQuestionBatch],
        failed_words: List[Tuple[ChineseChar, QuestionType]],
        user_id: UUIDStr,
        needed_count: int,
    ) -> List[QuestionBase]:
        """
        Collect recycled questions from not-good questions for words where AI failed.
        """
        collected_questions: List[QuestionBase] = []
        failed_word_set = {word for word, _ in failed_words}

        for batch in word_batches:
            if len(collected_questions) >= needed_count:
                break

            if batch.word in failed_word_set and batch.not_good_questions:
                best_not_good = batch.not_good_questions[0]
                question_base = self._convert_question_to_base(
                    best_not_good.question_entry, user_id
                )

                if question_base:
                    collected_questions.append(question_base)
                    logger.debug(f"Using recycled question for word {batch.word}")

        return collected_questions

    def _collect_final_fallback_questions(
        self, word_batches: List[WordQuestionBatch], user_id: UUIDStr, needed_count: int
    ) -> List[QuestionBase]:
        """
        Collect final fallback questions from database.
        """
        if needed_count <= 0:
            return []

        all_word_ids = [batch.word_id for batch in word_batches]

        logger.warning(f"Still need {needed_count} questions, using final fallback")

        # This is async, so we need to handle it differently
        # For now, return empty list and let the main method handle it
        return []

    async def _handle_fallback_strategy(
        self,
        word_batches: List[WordQuestionBatch],
        failed_words: List[Tuple[ChineseChar, QuestionType]],
        user_id: UUIDStr,
        needed_count: int,
    ) -> List[QuestionBase]:
        """
        Handle fallback strategy: randomly choose between AI generation and recycling.
        """
        collected_questions: List[QuestionBase] = []

        if not failed_words:
            return collected_questions

        # Randomly choose strategy: True for AI retry, False for recycling
        use_ai_retry = random.choice([True, False])

        if use_ai_retry:
            logger.info("Attempting AI retry for failed questions")
            # Try AI generation again for failed words
            ai_questions = await self.generate_ai_questions_for_words(
                failed_words, user_id
            )
            saved_ai_questions = await self.save_generated_questions(ai_questions)

            ai_collected, still_failed = self._collect_ai_generated_questions(
                saved_ai_questions, needed_count
            )
            collected_questions.extend(ai_collected)

            # If AI retry still fails, fall back to recycling
            if len(collected_questions) < needed_count and still_failed:
                logger.info("AI retry failed, falling back to recycling")
                recycled = self._collect_recycled_questions(
                    word_batches,
                    still_failed,
                    user_id,
                    needed_count - len(collected_questions),
                )
                collected_questions.extend(recycled)
        else:
            logger.info("Using recycled questions for failed words")
            # Try recycling first
            recycled = self._collect_recycled_questions(
                word_batches, failed_words, user_id, needed_count
            )
            collected_questions.extend(recycled)

            # If recycling doesn't provide enough, try AI generation
            if len(collected_questions) < needed_count:
                logger.info("Recycling insufficient, attempting AI generation")
                remaining_failed = failed_words[len(collected_questions) :]
                ai_questions = await self.generate_ai_questions_for_words(
                    remaining_failed, user_id
                )
                saved_ai_questions = await self.save_generated_questions(ai_questions)

                ai_collected, _ = self._collect_ai_generated_questions(
                    saved_ai_questions, needed_count - len(collected_questions)
                )
                collected_questions.extend(ai_collected)

        return collected_questions

    async def generate_questions_for_user(
        self,
        user_id: UUIDStr,
        count: int = 10,
        max_words: Optional[int] = None,
    ) -> List[QuestionBase]:
        """
        Main method implementing the 6-step question generation logic.
        Now refactored into smaller, focused methods.
        """
        try:
            logger.info(
                f"Starting question generation for user {user_id}, count: {count}"
            )

            # Step 1: Fetch revision words
            max_words_to_fetch = min(max_words or self.max_words, count * 2)
            revision_words = await self.get_revision_words(user_id, max_words_to_fetch)

            if not revision_words:
                logger.error(f"No revision words available for user {user_id}")
                raise ValueError("No words available for question generation")

            logger.debug(f"Got {len(revision_words)} revision words")

            # Step 2: Fetch questions
            word_batches = await self.fetch_questions_for_words(revision_words)

            # Step 3: Score and classify
            word_batches = self.classify_questions_by_goodness(word_batches)

            # Step 4: Collect good existing questions (with limits)
            final_questions, remaining_batches = self._collect_good_existing_questions(
                word_batches, user_id, count
            )

            # Step 5: Generate AI questions if needed
            if len(final_questions) < count:
                needed_count = count - len(final_questions)
                words_needing_questions = self._identify_words_needing_questions(
                    remaining_batches, needed_count
                )

                if words_needing_questions:
                    logger.info(
                        f"Generating AI questions for {len(words_needing_questions)} words"
                    )
                    ai_questions = await self.generate_ai_questions_for_words(
                        words_needing_questions, user_id
                    )
                    saved_ai_questions = await self.save_generated_questions(
                        ai_questions
                    )

                    ai_collected, failed_words = self._collect_ai_generated_questions(
                        saved_ai_questions, needed_count
                    )
                    final_questions.extend(ai_collected)

                    # Step 6: Handle fallback strategy for failed AI generations
                    if len(final_questions) < count and failed_words:
                        fallback_questions = await self._handle_fallback_strategy(
                            word_batches,
                            failed_words,
                            user_id,
                            count - len(final_questions),
                        )
                        final_questions.extend(fallback_questions)

            # Final database fallback if still needed
            if len(final_questions) < count:
                needed_count = count - len(final_questions)
                all_word_ids = [batch.word_id for batch in word_batches]

                fallback_questions = await self.get_fallback_questions(
                    all_word_ids, needed_count
                )

                for question_entry in fallback_questions:
                    if len(final_questions) >= count:
                        break

                    question_base = self._convert_question_to_base(
                        question_entry, user_id
                    )
                    if question_base:
                        final_questions.append(question_base)

            # Final validation
            if not final_questions:
                logger.error(f"Failed to generate any questions for user {user_id}")
                raise ValueError(
                    "Failed to generate any questions - all fallback mechanisms exhausted"
                )

            # Log summary
            logger.info(f"Question generation summary for user {user_id}:")
            logger.info(f"  - Total questions generated: {len(final_questions)}")
            logger.info(
                f"  - Words processed: {len(word_batches)} out of {len(revision_words)} fetched"
            )

            return final_questions[:count]

        except Exception as e:
            logger.error(f"Error in question generation for user {user_id}: {e}")
            raise
