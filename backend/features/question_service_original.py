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

logger = setup_logger(__name__, level="DEBUG")

# NOTE: The concept is
# Set up a queue for each question type, reach threshold, then send a batch request to the AI question generator
# Set up a repository (question_type * threshold) for words that dont have much questions generated, so that we can generate new questions for them

# Before trying to generate a question, check if the question already exists in the database
# (Dynamically calculate the probablilty of generating a question based on the existing questions count/ question type)


class QuestionService:
    def __init__(
        self,
        db: DatabaseService,
        # llm_service: LLMService,
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

        # Initialize the consolidated question generator
        self.question_generator = QuestionGenerator(
            db=db,
            llm_request_manager=llm_request_manager,
            storage_service=storage_service,
        )

        # Validate configuration values
        self.time_weight = config.get("QuestionGenerator.Weighting.Time", 1.0)
        if not isinstance(self.time_weight, float):
            raise ValueError("time_weight must be a float")

        self.count_weight = config.get("QuestionGenerator.Weighting.Count", 2.0)
        if not isinstance(self.count_weight, float):
            raise ValueError("count_weight must be a float")

        self.is_ai_enabled = config.get("QuestionGenerator.IsAIEnabled", False)
        if not isinstance(self.is_ai_enabled, bool):
            raise ValueError("is_ai_enabled must be a bool")

        self.available_question_types = [
            QuestionType.COPY_STROKE,
            QuestionType.FILL_IN_VOCAB,
            QuestionType.FILL_IN_SENTENCE,
            QuestionType.LISTENING,
            # QuestionType.PAIRING_CARDS,
        ]

        # self.llm_service = llm_service
        self.word_service = word_service
        self.user_service = user_service

    def _calculate_revision_words(
        self, wrong_chars: List[UserWrongChar]
    ) -> List[UserWrongChar]:
        """
        Calculate suitable words for revision based on current time, wrong count, and last wrong at.

        Args:
        - wrong_chars (list of UserWrongChar): List of wrong characters with their details.

        Returns:
        - List of dict: Sorted list of words for revision by priority.
        """
        revision_candidates: list[UserWrongChar] = []

        # For each character data, cauculate their priority based on time and wrong count
        # Then return the sorted list of candidates
        for char_data in wrong_chars:
            time_gap = (get_time() - char_data.last_wrong_at) / 3600  # Convert to hours

            # logger.debug(f"Time gap for word {char_data.word}: {time_gap} hours")
            # logger.debug(
            #     f"Time count for word {char_data.word}: {char_data.wrong_count}"
            # )

            # Calculate priority
            # The priority is a weighted sum of time gap and wrong count
            # Types are safe-guarded in __init__, so we can use type ignore here
            priority = (time_gap * self.time_weight) + (  # type: ignore
                char_data.wrong_count * self.count_weight
            )  # type: ignore
            # logger.debug(
            #     f"Calculated priority for word: {char_data.word} is {priority}"
            # )

            # Append to candidates with its priority
            revision_candidates.append(
                UserWrongChar(
                    word=char_data.word,
                    word_id=char_data.word_id,
                    wrong_count=char_data.wrong_count,
                    last_wrong_at=char_data.last_wrong_at,
                    priority=priority,
                )
            )
            # logger.debug(
            #     f"Added word {char_data.word} with priority {priority} to revision candidates."
            # )

        return revision_candidates

    def _randomize_revision_words(
        self, wrong_chars: List[UserWrongChar]
    ) -> List[UserWrongChar]:
        """
        Randomly selects a subset of words for revision based on the wrong characters.

        Args:
        - wrong_chars (list of UserWrongChar): List of wrong characters with their details.

        Returns:
        - List of UserWrongChar: Randomly selected words for revision.
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
        """
        Balances the probability between AI generation and database fetching.

        Parameters:
        - num_questions (int): Number of questions currently in the database.
        - threshold (int): Number of questions where AI probability is halved.
        - prob_ai (float): Maximum probability of AI generation when the database is empty (default: 1.0).
        - prob_db (float): Minimum probability of AI generation when the database is large (default: 0.001).

        Returns:
        - prob_ai_response (float): Probability of generating an AI response.
        - prob_db_fetch (float): Probability of fetching from the database.
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

    # TODO: fallback mechanism for question generation: delay database storage
    async def _process_item_with_fallback(
        self,
        generators: List[Callable[[], Awaitable]],
        item: ChineseChar,
    ) -> Optional[List[QuestionBase]]:
        logger.debug(f"Processing item: {item} with {len(generators)} generators.")
        result = None

        for generator in generators:
            try:
                logger.debug(f"Attempting generator {generator} for item: {item}")
                # Await the generator to get the result
                result = await generator()
                if not result:
                    logger.warning(
                        f"Generator {generator} returned no result for item: {item}"
                    )
                    continue
                return result  # Return the first successful result
            except asyncio.CancelledError:
                logger.debug(f"Generator {generator} was cancelled for item: {item}")
                continue
            except Exception as e:
                logger.error(f"Error in generator {generator} for item {item}: {e}")
                continue

        logger.error(f"All generators failed for item: {item}")
        return None

        # # Cancel remaining generators if a result is obtained
        # if result:
        #     logger.debug(f"Result obtained for item: {item}. Cancelling remaining generators.")
        #     for generator in generators:
        #         if not generator.done():  # Cancel only if it's still running
        #             generator.cancel()
        #     return result

        # finally:
        #     # Ensure all generators are canceled in case of failure or completion
        #     for generator in generators:
        #         if not generator.done():
        #             generator.cancel()
        #             try:
        #                 await generator  # Await cancellation to handle exceptions properly
        #             except asyncio.CancelledError:
        #                 logger.debug(f"Generator {generator} canceled successfully.")
        #             except Exception as e:
        #                 logger.error(f"Error while canceling generator: {e}")

        # If no result was obtained, raise an exception
        logger.error(f"All generators failed for item: {item}")
        raise Exception(f"All generators failed for item '{item}'")

    #### NOTE: THIS is the the main function to generate questions #####
    async def generate_by_user_id(
        self,
        user_id: UUIDStr,
        count: int = 10,
        priority_function: Optional[
            Callable[[list[UserWrongChar]], list[UserWrongChar]]
        ] = None,
    ) -> List[QuestionBase]:

        # 1. Get User wrong words from db
        wrong_word_dict: list[UserWrongChar] = (
            await self.user_service.get_user_wrong_words(user_id=user_id)
        )

        if not wrong_word_dict:
            logger.warning(f"No wrong words found for user {user_id}.")
            ## Proceeding now
            # return []

        # 2. Calculate priority
        if not priority_function:
            revision_candidates = self._calculate_revision_words(wrong_word_dict)
        else:
            # Prioritized revision candidates
            revision_candidates: List[UserWrongChar] = priority_function(
                wrong_word_dict
            )

        if not revision_candidates:
            logger.warning(f"No revision candidates found for user {user_id}.")

        # logger.debug(
        #     f"Found {len(revision_candidates)} revision candidates for user {user_id}."
        # )
        logger.debug(
            f"Revision candidates: {[char.word for char in revision_candidates]}"
        )

        # Get top N candidates based on priority
        # see https://github.com/microsoft/pyright/discussions/5660
        revision_candidates.sort(key=lambda x: x.priority)  # type: ignore
        # Limit the number of candidates to the specified count
        revision_candidates = revision_candidates[:count]
        logger.info(
            f"Selected {len(revision_candidates)} candidates for question generation."
        )

        ### There should be no more checking with wrong word specific attributes
        ### Should be safe to just format words into UserWrongChar format
        ### if count > len(revision_candidates), get more words randomly
        if count > len(revision_candidates):
            logger.debug(
                f"adding {count - len(revision_candidates)} random words to the candidates"
            )
            # Get random words from the word service
            random_words = await self.word_service.get_random_words(
                count=count - len(revision_candidates)
            )

            # Convert random words to UserWrongChar format
            random_candidates = [
                UserWrongChar(
                    word=word.word,
                    word_id=word.word_id,
                    wrong_count=0,  # Assuming new words have no wrong count
                    last_wrong_at=get_time(),  # Set to current time
                    priority=0.0,  # No priority for new words
                )
                for word in random_words
            ]
            # Append random candidates to the revision candidates
            revision_candidates.extend(random_candidates)

        # 3. Randomly select question types for each word and generate questions
        # Two types of question generation:
        # - if question is not randomly generated, then query the question bank first to ensure unique entry only in db
        # - if question is randomly generated, then generate a new question with save
        #   probablilty is calculated based on existing question count

        tasks: List[Awaitable] = []
        qtypes = random.choices(
            self.available_question_types,
            k=len(revision_candidates),
        )
        # prepare the generators for each word
        char_generators: List[List[Callable[[], Awaitable]]] = []
        words = [char_data.word for char_data in revision_candidates]
        for word, qtype in zip(words, qtypes):
            logger.debug(f"Getting question for word: {word}")
            # pick a random question type from available question types
            generators: List[Callable[[], Awaitable]] = [
                partial(self._get_question_bank_by_word, word, user_id, qtype),
                partial(self._generate_new_question_with_save, word, user_id, qtype),
            ]  # not using task here

            # Try to get the question bank first,
            # then generate a new question for question types like COPY_STROKE and LISTENING
            if not (
                qtype == QuestionType.COPY_STROKE or qtype == QuestionType.LISTENING
            ):
                # Choose if ai first based on the question count
                q_count_dict = await self.question_statistics_service.get_question_statistics_by_type(
                    target_word=word, question_type=qtype
                )
                q_count = q_count_dict.get(qtype.value, 0)
                ai_prob = self.get_choosing_ai_probability(q_count)
                # Put the AI question generation in the first place with probability
                is_ai_first = random.choices(
                    [True, False], weights=[ai_prob, 1 - ai_prob], k=1
                )[0]
                logger.debug("ai_prob: %s, is_ai_first: %s", ai_prob, is_ai_first)
                if is_ai_first:
                    # If AI is chosen first, swap the order of generators
                    generators[0], generators[1] = generators[1], generators[0]

            char_generators.append(generators)

        # Run the generators concurrently for each word
        for generators, word in zip(char_generators, words):
            # TODO: coroutine was never awaited, questions might not be saved to the database
            tasks.append(
                asyncio.ensure_future(
                    self._process_item_with_fallback(generators, word)
                )
            )
        logger.debug(f"Generated {len(tasks)} tasks for question generation.")
        results = await asyncio.gather(*tasks)  # No return exception

        logger.debug("All tasks completed, processing results.")
        # 4. Process the results and handle exceptions
        generated_questions = []
        for char_data, question in zip(revision_candidates, results):
            word = char_data.word
            try:
                # logger.debug(f"Generated question: {question}")
                if question:
                    # If the question is successfully generated, append it to the list
                    generated_questions.append(question)
                    # logger.info(f"Generated question for word: {word}")
                else:
                    logger.warning(f"No question generated for word: {word}")
                    generated_questions.append(None)
            except Exception as e:
                logger.error(f"Error generating question for word '{word}': {e}")

        return generated_questions[:count]

    # async def generate_by_words(
    #     self, words: List[ChineseChar], question_type: Optional[QuestionType] = None
    # ) -> List[QuestionBase]:
    #     """
    #     Generates a list of questions based on a list of words and an optional question type.

    #     NOTE: Usse this function to test the question generation only
    #     """
    #     questions = []
    #     for word in words:
    #         ## If AI is enabled, us AI to generate questions
    #         ## otherwise query the question bank
    #         if self.is_ai_enabled:
    #             question = await self._generate_question_by_word(word, question_type)
    #         else:
    #             logger.warning(
    #                 f"AI is disabled, querying question bank for word: {word}"
    #             )
    #             question = await self._query_question_bank(word, question_type)

    #         if question:
    #             questions.append(question)
    #         else:
    #             logger.warning(f"No question found for word: {word}")

    #     return questions[: self.num_questions]
