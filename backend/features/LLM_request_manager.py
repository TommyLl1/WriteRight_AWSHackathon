"""
LLM Request Manager

This module provides a high-level interface for managing LLM requests with automatic batching
and queuing for different AI question types. It uses the generic queue manager to optimize
performance by batching requests and reducing the number of individual LLM calls.
"""

if __name__ == "__main__":
    import sys
    import os

    sys.path.append(os.path.dirname(os.path.dirname(__file__)))

import asyncio
import random
from typing import List, Dict, Any
from utils.queue_manager import QueueManager, get_global_queue_manager
from utils.LLMService import LLMService
from models.LLM import (
    AIQuestionType,
    LLMModels,
)
from models.helpers import ChineseChar
from models.QnA import FillInVocabQuestion, FillInSentenceQuestion, PairingCardsQuestion
from features.AI_question_generator import AIQuestionGenerator
from utils.logger import setup_logger
from utils.config import config
from pydantic import BaseModel
from functools import lru_cache

logger = setup_logger(__name__)


class LLMRequestManager:
    llm_service: LLMService | None = None
    batch_size: int = 5
    max_wait: float = 10.0
    generator = AIQuestionGenerator()

    def __init__(self, batch_size: int = 5, max_wait: float = 6):
        logger.info("init LLMRequestManager")
        self.batch_size = batch_size
        # self.queue_manager = get_queue_manager()
        self.batch_size = batch_size
        ### in seconds
        self.max_wait = max_wait
        self.tasks: Dict[str, list] = {}
        # Create processors for each question type
        self.lock = asyncio.Lock()  # Lock to ensure thread-safe access to shared state
        self.queue_manager = get_global_queue_manager()
        logger.debug(f"__init__ : tasks: {self.tasks}")

    def __del__(self):
        logger.info("LLMRequestManager is being deleted")

    def _create_processors(self):
        """Create batch processors for each AI question type."""
        logger.info("Creating processors for AI question types")
        # Create processor for FILL_IN_VOCAB
        if not self.queue_manager.has_processor(AIQuestionType.FILL_IN_VOCAB.value):
            self.queue_manager.create_processor(
                name=AIQuestionType.FILL_IN_VOCAB.value,
                batch_function=self._batch_process_fill_in_vocab,
                batch_size=self.batch_size,
                max_wait=self.max_wait,
            )
            self.tasks[AIQuestionType.FILL_IN_VOCAB.value] = []

        # Create processor for FILL_IN_SENTENCE
        if not self.queue_manager.has_processor(AIQuestionType.FILL_IN_SENTENCE.value):
            self.queue_manager.create_processor(
                name=AIQuestionType.FILL_IN_SENTENCE.value,
                batch_function=self._batch_process_fill_in_sentence,
                batch_size=self.batch_size,
                max_wait=self.max_wait,
            )
            self.tasks[AIQuestionType.FILL_IN_SENTENCE.value] = []

        # Create processor for PAIRING_CARDS
        if not self.queue_manager.has_processor(AIQuestionType.PAIRING_CARDS.value):
            self.queue_manager.create_processor(
                name=AIQuestionType.PAIRING_CARDS.value,
                batch_function=self._batch_process_pairing_cards,
                batch_size=self.batch_size,
                max_wait=self.max_wait,
            )
            self.tasks[AIQuestionType.PAIRING_CARDS.value] = []

        logger.info(f"avaliable task types: {self.tasks.keys()}")
        logger.info(f"Created processors for 3 question types")

    async def _batch_process_fill_in_vocab(
        self,
        chars: List[ChineseChar],
        max_tokens: int = config.get("QuestionGenerator.Batch.MaxTokens", 300),
        model: LLMModels = LLMModels.DEEPSEEK_V3,
    ) -> List[FillInVocabQuestion]:
        return await self.generator.batch_genq_fill_in_vocab(
            chars=chars,
            max_tokens=max_tokens,
            model=model,
        )

    async def _batch_process_fill_in_sentence(
        self,
        chars: List[ChineseChar],
        max_tokens: int = config.get("QuestionGenerator.Batch.MaxTokens", 300),
        model: LLMModels = LLMModels.DEEPSEEK_V3,
    ) -> List[FillInSentenceQuestion]:
        return await self.generator.batch_genq_fill_in_sentence(
            chars=chars,
            max_tokens=max_tokens,
            model=model,
        )

    async def _batch_process_pairing_cards(
        self,
        chars: List[ChineseChar],
        n: int = 2,
        max_tokens: int = config.get("QuestionGenerator.Batch.MaxTokens", 300),
        model: LLMModels = LLMModels.DEEPSEEK_V3,
    ) -> List[PairingCardsQuestion]:

        return await self.generator.batch_genq_pairing_cards(
            chars=chars,
            max_tokens=max_tokens,
            model=model,
        )

    async def enqueue_questions(
        self,
        question_type: AIQuestionType,
        char: ChineseChar,
        max_tokens: int = config.get("QuestionGenerator.Batch.MaxTokens", 300),
        model: LLMModels = LLMModels.DEEPSEEK_V3,
    ) -> Any:
        """
        Enqueue questions for processing.
        The args of first input will be used for all remaining questions in the queue
        """

        async with self.lock:  # Acquire the lock
            # Enqueue the characters for the specified question type
            # logger.debug(
            #     f"Enqueue request for {question_type} with char: {char}, granted lock"
            # )
            logger.debug(self.tasks.keys())
            # logger.debug(type(question_type))
            # logger.debug(type(self.tasks.keys()))
            if question_type.value not in self.tasks.keys():
                # logger.error(f"Unsupported question type: {question_type}")
                # logger.error(f"available question types: {self.tasks.keys()}")
                raise ValueError(f"Unsupported question type: {question_type}")

            task = self.queue_manager.add_to_queue(
                question_type.value,
                item=char,
                max_tokens=max_tokens,
                model=model,
            )  # This task should return the result of the batch processing
            self.tasks[question_type.value].append(task)
            # logger.debug(f"task dict: {self.tasks}")

        # Released lock
        # Wait for the task to complete and return the result
        # logger.debug(f"Enqueued {char} for {question_type}, waiting for task to complete")
        # logger.debug(f"task: {task}")
        result = await task
        # logger.debug(f"Task for {question_type} completed with result: {result}")

        async with self.lock:  # Acquire the lock again to safely modify shared state
            self.tasks[question_type.value].remove(task)  # Remove the completed task
        return result

    async def flush_queue(self, question_type: AIQuestionType) -> List[Any]:
        """Flush the queue for a specific question type."""
        if question_type not in self.tasks:
            raise ValueError(f"Unsupported question type: {question_type}")

        async with self.lock:  # Acquire the lock
            await self.queue_manager.flush_queue(question_type.value)
            results = await asyncio.gather(*self.tasks[question_type.value])
            self.tasks[question_type.value] = []  # Safely modify shared state
        return results

    async def shutdown(self):
        """Shutdown the queue manager and LLM service."""
        logger.warning(
            "LLMRequestManager.shutdown: This have been deprecated, use queue_manager.shutdown() instead"
        )

        await self.queue_manager.shutdown()

    async def get_stats(self) -> Dict[str, Any]:
        """Get statistics about the queue manager."""
        logger.warning(
            "LLMRequestManager.get_stats: This have been deprecated, use queue_manager.get_stats() instead"
        )
        return self.queue_manager.get_stats()


BATCH_SIZE = 5
MAX_WAIT = 1

# async def get_llm_request_manager() -> LLMRequestManager:
#     """
#     Get the global instance of LLMRequestManager.
#     If it doesn't exist, create a new one.
#     """
#     llm_request_manager = LLMRequestManager(batch_size=BATCH_SIZE, max_wait=MAX_WAIT)
#     await llm_request_manager._create_processors()
#     logger.debug("LLMRequestManager created")
#     logger.debug(f"llm manager id: {id(llm_request_manager)}")
#     return llm_request_manager


# async def main():
#     manager =  get_llm_request_manager()

#     # Example usage
#     characters = [
#         "晴",
#         "銀",
#         "店",
#         # "行",
#         # "吃",
#         "馬",
#         "鳥",
#         "書",
#         "學",
#         "問",
#         "說",
#         "走",
#         "跑",
#         "飛",
#     ]
#     random.shuffle(characters)
#     test_count = 8
#     for char in characters[:test_count]:
#         print(f"Enqueuing character: {char}")
#         # Args for first item in batch will be used for all in that batch
#         await manager.enqueue_questions(
#             AIQuestionType.FILL_IN_VOCAB, char, max_tokens=300
#         )
#         await asyncio.sleep(0.3)  # Simulate some delay between requests
#         # manager.enqueue_questions(AIQuestionType.FILL_IN_SENTENCE, char)
#         # manager.enqueue_questions(AIQuestionType.PAIRING_CARDS, char)
#     print(f"Enqueued {len(characters[:test_count])} characters for each question type.")
#     # await asyncio.sleep(12)  # should trigger max_wait and process the queues
#     # Flush the queues
#     vocab_questions: List[FillInVocabQuestion] = await manager.flush_queue(
#         AIQuestionType.FILL_IN_VOCAB
#     )
#     # sentence_questions = await manager.flush_queue(AIQuestionType.FILL_IN_SENTENCE)
#     # pairing_cards_questions = await manager.flush_queue(AIQuestionType.PAIRING_CARDS)

#     print(f"Got {len(vocab_questions)} FillInVocabQuestions from the queue manager.")
#     # _ = (
#     #     [
#     #         print(q.model_dump_json(exclude_unset=True, indent=2))
#     #         for q in vocab_questions
#     #     ],
#     # )
#     # print(f"Sentence Questions: {sentence_questions}")
#     # print(f"Pairing Cards Questions: {pairing_cards_questions}")

#     # Shutdown the manager
#     await manager.shutdown()


# if __name__ == "__main__":
#     # Run the main function in an event loop
#     asyncio.run(main())
#     print("LLM Request Manager example completed.")
