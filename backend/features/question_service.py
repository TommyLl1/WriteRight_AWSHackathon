if __name__ == "__main__":
    import sys
    import os
    from dotenv import load_dotenv

    # Add the workspace root to sys.path
    sys.path.append(os.path.dirname(os.path.dirname(__file__)))
    load_dotenv()  # Load environment variables from .env file


from typing import List, Dict, Optional, Any, Callable, Awaitable
from uuid import UUID
import random
from utils.logger import setup_logger
from utils.config import config
from utils.storage_service import StorageController
from utils.rpc_service import RPCService
import asyncio
import math


# Import models
from models.QnA import *
from models.QnA_builder import QuestionBuilder
from models.services import *
from models.LLM import AIQuestionType
from models.helpers import ChineseChar, get_time, to_unicodeInt_from_char
from models.db.db import SupabaseRPC, SupabaseTable, QuestionEntry
from functools import partial

# Import necessary services
from utils.LLMService import LLMService
from utils.database.base import DatabaseService
from features.word_service import WordService
from features.user_service import UserService
from features.LLM_request_manager import LLMRequestManager
from features.question_generator import QuestionGenerator
from features.enhanced_question_service import EnhancedQuestionService

logger = setup_logger(__name__, level="DEBUG")

# NOTE: This is now a wrapper around the enhanced question service
# The enhanced service implements the comprehensive 6-step question generation logic


class QuestionService:
    """
    Question service that provides backwards compatibility while using the enhanced
    question generation service under the hood.
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
        self.llm_request_manager = llm_request_manager
        self.storage_service = storage_service
        self.question_statistics_service = question_statistics_service

        # Initialize the enhanced question service
        self.enhanced_service = EnhancedQuestionService(
            db=db,
            word_service=word_service,
            user_service=user_service,
            llm_request_manager=llm_request_manager,
            storage_service=storage_service,
            question_statistics_service=question_statistics_service,
        )

        # Keep the old question generator for backwards compatibility
        self.question_generator = QuestionGenerator(
            db=db,
            llm_request_manager=llm_request_manager,
            storage_service=storage_service,
        )

        # Configuration for backwards compatibility
        self.time_weight = config.get("QuestionGenerator.Weighting.Time", 1.0)
        self.count_weight = config.get("QuestionGenerator.Weighting.Count", 2.0)
        self.is_ai_enabled = config.get("QuestionGenerator.IsAIEnabled", False)

        self.available_question_types = [
            QuestionType.COPY_STROKE,
            QuestionType.FILL_IN_VOCAB,
            QuestionType.FILL_IN_SENTENCE,
            QuestionType.LISTENING,
        ]

        self.word_service = word_service
        self.user_service = user_service

    # Backwards compatibility methods (preserved from original implementation)
    def _calculate_revision_words(
        self, wrong_chars: List[UserWrongChar]
    ) -> List[UserWrongChar]:
        """
        Calculate suitable words for revision based on current time, wrong count, and last wrong at.
        (Preserved for backwards compatibility)
        """
        return self.enhanced_service._calculate_revision_words(wrong_chars)

    def _randomize_revision_words(
        self, wrong_chars: List[UserWrongChar]
    ) -> List[UserWrongChar]:
        """
        Randomly selects a subset of words for revision based on the wrong characters.
        (Preserved for backwards compatibility)
        """
        if not wrong_chars:
            return []

        # Randomize priority of each word
        for char in wrong_chars:
            char.priority = random.random()

        return wrong_chars

    def get_choosing_ai_probability(
        self, num_questions, threshold=4, prob_ai=1.0, prob_db=1e-2
    ) -> float:
        # Not used in the enhanced service, but preserved for backwards compatibility
        """
        Balances the probability between AI generation and database fetching.
        (Preserved for backwards compatibility)
        """
        if num_questions < 0:
            raise ValueError("Number of questions must be non-negative.")

        # Calculate decay rate k
        k = math.log(prob_ai / prob_db) / threshold

        # AI probability (decays exponentially as num_questions increases)
        prob_ai_response = prob_ai * math.exp(-k * num_questions)

        return prob_ai_response

    async def _get_question_bank_by_word(
        self,
        word: ChineseChar,
        user_id: UUIDStr,
        question_type: Optional[QuestionType] = None,
    ) -> Optional[QuestionBase]:
        """Get a question from the question bank using the consolidated generator."""
        return await self.question_generator.get_question_from_bank(
            word=word,
            user_id=user_id,
            question_type=question_type,
        )

    async def _generate_new_question_with_save(
        self, char: ChineseChar, user_id: UUIDStr, question_type: QuestionType
    ) -> QuestionBase:
        """
        Generate a new question and save it to the database using the consolidated generator.
        """
        return await self.question_generator.generate_and_save_question(
            char=char,
            user_id=user_id,
            question_type=question_type,
        )

    async def _process_item_with_fallback(
        self,
        generators: List[Callable[[], Awaitable]],
        item: ChineseChar,
    ) -> Optional[List[QuestionBase]]:
        """Legacy fallback processing method (preserved for backwards compatibility)"""
        logger.debug(f"Processing item: {item} with {len(generators)} generators.")
        result = None

        for generator in generators:
            try:
                logger.debug(f"Attempting generator {generator} for item: {item}")
                result = await generator()
                if not result:
                    logger.warning(
                        f"Generator {generator} returned no result for item: {item}"
                    )
                    continue
                return result
            except asyncio.CancelledError:
                logger.debug(f"Generator {generator} was cancelled for item: {item}")
                continue
            except Exception as e:
                logger.error(f"Error in generator {generator} for item {item}: {e}")
                continue

        logger.error(f"All generators failed for item: {item}")
        return None

    #### NOTE: THIS is the main function to generate questions #####
    async def generate_by_user_id(
        self,
        user_id: UUIDStr,
        count: int = 10,
        priority_function: Optional[
            Callable[[list[UserWrongChar]], list[UserWrongChar]]
        ] = None,
    ) -> List[QuestionBase]:
        """
        Main method to generate questions by user ID.
        Now uses the enhanced question service with comprehensive 6-step logic.
        """
        logger.info(
            f"QuestionService.generate_by_user_id called for user {user_id}, count: {count}"
        )

        try:
            # Use the enhanced service for question generation
            questions = await self.enhanced_service.generate_questions_for_user(
                user_id=user_id,
                count=count,
                max_words=None,  # Use default from enhanced service
            )

            logger.info(
                f"Enhanced service generated {len(questions)} questions for user {user_id}"
            )
            return questions

        except Exception as e:
            logger.error(f"Enhanced question generation failed for user {user_id}: {e}")
            logger.warning("Falling back to legacy question generation")

            # Fallback to legacy implementation if enhanced service fails
            return await self._legacy_generate_by_user_id(
                user_id, count, priority_function
            )

    async def _legacy_generate_by_user_id(
        self,
        user_id: UUIDStr,
        count: int = 10,
        priority_function: Optional[
            Callable[[list[UserWrongChar]], list[UserWrongChar]]
        ] = None,
    ) -> List[QuestionBase]:
        """
        Legacy implementation preserved as fallback.
        This is the original implementation from the previous question service.
        """
        logger.warning("Using legacy question generation implementation")

        # 1. Get User wrong words from db
        wrong_word_dict: list[UserWrongChar] = (
            await self.user_service.get_user_wrong_words(user_id=user_id)
        )

        if not wrong_word_dict:
            logger.warning(f"No wrong words found for user {user_id}.")

        # 2. Calculate priority
        if not priority_function:
            revision_candidates = self._calculate_revision_words(wrong_word_dict)
        else:
            revision_candidates: List[UserWrongChar] = priority_function(
                wrong_word_dict
            )

        if not revision_candidates:
            logger.warning(f"No revision candidates found for user {user_id}.")

        logger.debug(
            f"Revision candidates: {[char.word for char in revision_candidates]}"
        )

        # Get top N candidates based on priority
        revision_candidates.sort(key=lambda x: x.priority or 0)
        revision_candidates = revision_candidates[:count]
        logger.info(
            f"Selected {len(revision_candidates)} candidates for question generation."
        )

        # If count > len(revision_candidates), get more words randomly
        if count > len(revision_candidates):
            logger.debug(
                f"adding {count - len(revision_candidates)} random words to the candidates"
            )
            random_words = await self.word_service.get_random_words(
                count=count - len(revision_candidates)
            )

            random_candidates = [
                UserWrongChar(
                    word=word.word,
                    word_id=word.word_id,
                    wrong_count=0,
                    last_wrong_at=get_time(),
                    priority=0.0,
                )
                for word in random_words
            ]
            revision_candidates.extend(random_candidates)

        # 3. Generate questions using legacy logic
        tasks: List[Awaitable] = []
        qtypes = random.choices(
            self.available_question_types,
            k=len(revision_candidates),
        )

        char_generators: List[List[Callable[[], Awaitable]]] = []
        words = [char_data.word for char_data in revision_candidates]

        for word, qtype in zip(words, qtypes):
            logger.debug(f"Getting question for word: {word}")
            generators: List[Callable[[], Awaitable]] = [
                partial(self._get_question_bank_by_word, word, user_id, qtype),
                partial(self._generate_new_question_with_save, word, user_id, qtype),
            ]

            if not (
                qtype == QuestionType.COPY_STROKE or qtype == QuestionType.LISTENING
            ):
                q_count_dict = await self.question_statistics_service.get_question_statistics_by_type(
                    target_word=word, question_type=qtype
                )
                q_count = q_count_dict.get(qtype.value, 0)
                ai_prob = self.get_choosing_ai_probability(q_count)
                is_ai_first = random.choices(
                    [True, False], weights=[ai_prob, 1 - ai_prob], k=1
                )[0]
                logger.debug("ai_prob: %s, is_ai_first: %s", ai_prob, is_ai_first)
                if is_ai_first:
                    generators[0], generators[1] = generators[1], generators[0]

            char_generators.append(generators)

        # Run the generators concurrently for each word
        for generators, word in zip(char_generators, words):
            tasks.append(
                asyncio.ensure_future(
                    self._process_item_with_fallback(generators, word)
                )
            )

        logger.debug(f"Generated {len(tasks)} tasks for question generation.")
        results = await asyncio.gather(*tasks)

        logger.debug("All tasks completed, processing results.")
        generated_questions = []
        for char_data, question in zip(revision_candidates, results):
            word = char_data.word
            try:
                if question:
                    generated_questions.append(question)
                else:
                    logger.warning(f"No question generated for word: {word}")
                    generated_questions.append(None)
            except Exception as e:
                logger.error(f"Error generating question for word '{word}': {e}")

        # Filter out None values and return
        valid_questions = [q for q in generated_questions if q is not None]
        return valid_questions[:count]
