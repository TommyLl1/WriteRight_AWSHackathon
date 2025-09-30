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

# Import necessary services
from utils.LLMService import LLMService
from utils.database.base import DatabaseService
from features.LLM_request_manager import LLMRequestManager

logger = setup_logger(__name__, level="DEBUG")


class QuestionGenerator:
    """
    Consolidated question generator class that handles all question generation logic.
    Uses class methods to provide a clean interface for different question types.
    """

    def __init__(
        self,
        db: DatabaseService,
        llm_request_manager: LLMRequestManager,
        storage_service: StorageController,
    ):
        self.db = db
        self.llm_request_manager = llm_request_manager
        self.storage_service = storage_service

    @classmethod
    def create_copy_stroke_question(
        cls,
        char: ChineseChar,
        user_id: UUIDStr,
        storage_service: StorageController,
        background_image: Optional[str] = None,
    ) -> CopyStrokeQuestion:
        """Generate a copy stroke question for the given character."""
        submit_url = storage_service.get_submit_url(user_id=user_id)

        builder = (
            QuestionBuilder()
            .copy_stroke()
            .set_target_word(char)
            .set_handwrite_target(char)
            .set_submit_url(submit_url)
        )
        if background_image:
            builder = builder.set_background_image(background_image)

        return builder.build()

    @classmethod
    async def create_listening_question(
        cls,
        char: ChineseChar,
        db: DatabaseService,
    ) -> MultiChoiceQuestion:
        """Generate a listening question for the given character."""
        pronunciation = await db.filter_data(
            SupabaseTable.WORDS,
            {"word_id": to_unicodeInt_from_char(char)},
            columns=["word_id", "pronunciation_url"],
        )

        if not pronunciation or not pronunciation.data:
            raise ValueError(f"No pronunciation found for character {char}")

        pronunciation_url = pronunciation.data[0].get("pronunciation_url")
        if not pronunciation_url:
            raise ValueError(f"No pronunciation URL found for character {char}")

        builder = (
            QuestionBuilder()
            .listening()
            .set_target_word(char)
            .add_given_sound(sound_url=pronunciation_url)
            .add_choices(
                choices=[
                    char,
                    ChineseChar("的"),
                    ChineseChar("是"),
                    ChineseChar("草"),
                ],  # Example choices
                is_answers=[
                    True,
                    False,
                    False,
                    False,
                ],  # Assuming the first choice is the correct one
            )
        )
        return builder.build()

    @classmethod
    async def create_ai_question(
        cls,
        char: ChineseChar,
        question_type: QuestionType,
        llm_request_manager: LLMRequestManager,
    ) -> QuestionBase:
        """Generate an AI-powered question for the given character and type."""
        ai_question_types = {qtype.value: qtype for qtype in AIQuestionType}

        if question_type.value not in ai_question_types:
            raise ValueError(
                f"Question type {question_type} is not supported by AI generator"
            )

        logger.debug(f"Queue up: {char} for question type: {question_type}")
        result = await llm_request_manager.enqueue_questions(
            question_type=ai_question_types[question_type.value],
            char=char,
        )
        logger.debug(f"Returned question for {char}, type: {question_type}")
        return result

    async def generate_question(
        self,
        char: ChineseChar,
        user_id: UUIDStr,
        question_type: QuestionType,
        background_image: Optional[str] = None,
    ) -> QuestionBase:
        """
        Main method to generate a question of any type.
        Automatically routes to the appropriate generation method.
        """
        ai_question_types = {qtype.value: qtype for qtype in AIQuestionType}

        if question_type.value in ai_question_types:
            return await self.create_ai_question(
                char=char,
                question_type=question_type,
                llm_request_manager=self.llm_request_manager,
            )
        elif question_type == QuestionType.COPY_STROKE:
            return self.create_copy_stroke_question(
                char=char,
                user_id=user_id,
                storage_service=self.storage_service,
                background_image=background_image,
            )
        elif question_type == QuestionType.LISTENING:
            return await self.create_listening_question(
                char=char,
                db=self.db,
            )
        else:
            raise ValueError(f"Unsupported question type: {question_type}")

    async def generate_and_save_question(
        self,
        char: ChineseChar,
        user_id: UUIDStr,
        question_type: QuestionType,
        background_image: Optional[str] = None,
    ) -> QuestionBase:
        """
        Generate a question and save it to the database.
        Returns the question with the database-assigned question_id.
        """
        # Generate the question
        result = await self.generate_question(
            char=char,
            user_id=user_id,
            question_type=question_type,
            background_image=background_image,
        )

        if not result:
            logger.error(f"Failed to generate question for character: {char}")
            raise ValueError(f"Failed to generate question for character: {char}")

        # Convert and save the question to the database
        try:
            question_entry = QuestionEntry.from_question_base(result)
            insert_result = await self.db.insert_data(
                SupabaseTable.QUESTIONS,
                question_entry.model_dump(exclude_none=False),
            )

            if isinstance(insert_result, list):
                insert_result = insert_result[0]

            # Align the question_id with the database
            result.question_id = insert_result["question_id"]
            logger.debug(
                f"Question for {char} saved to database with ID: {result.question_id}"
            )
            logger.info(f"Question for {char} saved to database successfully.")
        except Exception as e:
            logger.error(f"Error saving question to database: {e}")
            raise

        return result

    async def get_question_from_bank(
        self,
        word: ChineseChar,
        user_id: UUIDStr,
        question_type: Optional[QuestionType] = None,
    ) -> Optional[QuestionBase]:
        """
        Retrieve a question from the question bank for the given word and type.
        """
        logger.debug(
            f"Fetching question bank for word: {word} and type: {question_type}"
        )

        # Build the complex query to fetch questions and exclude flagged ones
        base_query = """
            SELECT q.* 
            FROM questions q 
            WHERE q.target_word_id = $word_id
            AND q.question_id NOT IN (
                SELECT DISTINCT fq.question_id 
                FROM flagged_questions fq
            )
        """

        params: dict[str, Any] = {"word_id": to_unicodeInt_from_char(word)}

        # Add question type filter if specified
        if question_type:
            base_query += " AND q.question_type = $question_type"
            params["question_type"] = question_type.value

        try:
            questions_response = await self.db.execute_complex_query(
                query=base_query, params=params, return_type=dict, fetch_mode="all"
            )
            from models.helpers import APIResponse

            questions: APIResponse = questions_response  # type: ignore
            logger.debug(
                f"Fetched {questions.count} unflagged questions for word: {word} and type: {question_type}"
            )
        except Exception as e:
            logger.error(
                f"Error fetching question bank for word {word} and type {question_type}: {e}"
            )
            return None

        if not questions.data:
            logger.warning(
                f"No unflagged questions found for word: {word} and type: {question_type}"
            )
            return None

        # Randomly select one question from the result
        question_data = random.choice(questions.data)

        # Validate the question
        try:
            question = QuestionEntry.model_validate(question_data)
        except Exception as e:
            logger.error(
                f"question_id: {question_data['question_id']}: Error validating question entry for word {word} and type {question_type}: {e}"
            )
            return None

        # Convert to QuestionBase
        try:
            if question_type == QuestionType.COPY_STROKE:
                submit_url = self.storage_service.get_submit_url(user_id)
                question_base = question.to_question_base(submit_url=submit_url)
            else:
                question_base = question.to_question_base()
        except Exception as e:
            logger.error(question.model_dump())
            logger.error(
                f"question_id: {question.question_id}: Error converting question entry to QuestionBase for word {word} and type {question_type}: {e}"
            )
            return None

        return question_base
