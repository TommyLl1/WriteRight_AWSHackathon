if __name__ == "__main__":
    import sys
    import os

    sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from typing import Optional, List, Tuple
from uuid import UUID
from models.db.db import *
from utils.database.base import DatabaseService
from utils.database.factory import get_database_service
from models.QnA import ChineseChar
from models.db.tasks import Task
from models.helpers import (
    UnicodeInt,
    is_Chinese_char,
    is_Chinese_char_unicode,
    to_unicodeInt_from_char,
    to_char_from_unicode,
)
import asyncio


class RPCService:
    def __init__(self, db: Optional[DatabaseService] = None):
        self.db = db or get_database_service()

    def _ensure_UnicodeInt(
        self, target_word: Optional[ChineseChar | UnicodeInt]
    ) -> Optional[UnicodeInt]:
        """
        Ensures that the target word is of type UnicodeInt.

        Args:
            target_word (Optional[ChineseChar | UnicodeInt]): The target word to check.

        Returns:
            Optional[UnicodeInt]: The target word as UnicodeInt if it is valid, otherwise None.
        """
        if isinstance(target_word, str):
            if is_Chinese_char(target_word):
                return to_unicodeInt_from_char(target_word)
            else:
                raise ValueError(f"Invalid Chinese character: {target_word}")
        elif isinstance(target_word, int):
            if is_Chinese_char_unicode(target_word):
                return target_word
            else:
                raise ValueError(f"Invalid Unicode integer: {target_word}")
        else:
            raise TypeError(
                f"target_word must be a ChineseChar (str) or UnicodeInt (int), got {type(target_word)}"
            )

    async def get_question_statistics_by_type(
        self,
        target_word: Optional[ChineseChar | UnicodeInt] = None,
        question_type: Optional[QuestionType] = None,
    ) -> Dict[str, int]:
        """
        Fetches the count of questions by type, optionally filtered by a target word.

        Args:
            target_word (Optional[ChineseChar | UnicodeInt]): The target word to filter questions.
            question_type (Optional[QuestionType]): The type of question to filter by.

        Returns:
            Dict[QuestionType, int]: A dictionary with question types as keys and their counts as values.
        """
        target_word_unicode = (
            0 if target_word is None else self._ensure_UnicodeInt(target_word)
        )
        assert (
            isinstance(question_type, QuestionType) or question_type is None
        ), "question_type must be a QuestionType enum or None"

        try:
            assert self.db is not None, "Database connection is not initialized"
            result = await self.db.rpc_query(
                SupabaseRPC.COUNT_QUESTION_BY_TYPE,
                {"word_id": target_word_unicode},
            )
            if not result.data:
                return {}
            output = {item["question_type"]: item["count"] for item in result.data}
            if question_type is not None:
                return {question_type.value: output.get(question_type, 0)}
            return {item["question_type"]: item["count"] for item in result.data}
        except Exception as e:
            print(f"Error fetching question statistics: {e}")
            return {}

    async def get_wrong_word_count_by_user(
        self,
        user_id: str,
        target_word: Optional[ChineseChar | UnicodeInt] = None,
        last_wrong_at: Optional[int] = None,
    ) -> Dict[str, Dict[str, int]]:
        """
        Fetches the count of wrong words for a user, optionally filtered by a target word and last wrong time.

        Args:
            user_id (UUID): The ID of the user.
            target_word (Optional[ChineseChar | UnicodeInt]): The target word to filter wrong words.
            last_wrong_at (Optional[int]): The timestamp to filter wrong words by last wrong time.

        Returns:
            Dict[str, int]: A dictionary with the word as key and its wrong count as value.
        """
        target_word_unicode = (
            0 if target_word is None else self._ensure_UnicodeInt(target_word)
        )
        target_last_wrong_at = 0 if last_wrong_at is None else last_wrong_at
        try:
            assert self.db is not None, "Database connection is not initialized"
            result = await self.db.rpc_query(
                SupabaseRPC.GET_USER_WRONG_WORDS_BY_USER_AFTER,
                {
                    "provided_user_id": str(user_id),
                    "provided_timestamp": target_last_wrong_at,
                    "target_word_id": target_word_unicode,
                },
            )
            if not result.data:
                return {}
            return {
                to_char_from_unicode(item["word_id"]): {
                    "word_id": item["wrong_count"],
                    "wrong_at": item["last_wrong_at"],
                }
                for item in result.data
            }
        except Exception as e:
            print(f"Error fetching wrong word count: {e}")
            return {}

    async def add_new_user_handle_exist(
        self,
        name: str,
        email: str,
    ) -> Optional[Tuple[User, bool]]:
        """
        Adds a new user. If the user already exists, returns the existing user data.
        Args:
            name (str): The name of the user.
            email (str): The email of the user.
        Returns:
            Optional[Tuple[User, bool]]: A tuple containing the User object and a boolean indicating if the user already exists.

        Remarks:
            - Returns None if the operation fails
        """
        assert self.db is not None, "Database connection is not initialized"
        exist = False
        try:
            result = await self.db.rpc_query(
                SupabaseRPC.ADD_NEW_USER_HANDLE_EXIST,
                {
                    "p_name": name,
                    "p_email": email,
                },
                mode="json",
            )
            if not result.data:
                return None
            user_data: dict = (
                result.data[0] if isinstance(result.data, list) else result.data
            )
            exist = user_data.get("existing_user", False)
            user = User.model_validate(user_data)
            return (user, exist)
        except Exception as e:
            print(f"Error adding new user or checking existence: {e}")
            return None

    async def get_or_create_today_tasks(self, user_id: UUID) -> List[Task]:
        """
        Calls the get_or_create_today_tasks RPC to fetch current valid tasks for the user, creating today's daily task if needed.
        Returns up to 100 tasks, ordered by priority.
        """
        assert self.db is not None, "Database connection is not initialized"
        try:
            # RPC query hardcoded to limit to 100 tasks, ordered by priority
            result = await self.db.rpc_query(
                SupabaseRPC.GET_OR_CREATE_TODAY_TASKS,
                {"p_user_id": str(user_id)},
                mode="table",
            )
            if not result.data:
                logger.warning(f"No tasks found for user {user_id}.")
                return []
            # Ensure the result is a list of Task objects
            out = [Task.model_validate(item) for item in result.data]
            return out
        except Exception as e:
            logger.warning(f"Error fetching or creating today's tasks: {e}")
            return []

    async def set_task_progress(
        self, user_id: UUIDStr, task_id: UUIDStr, progress: int
    ) -> dict:
        """
        Calls the set_task_progress RPC to update a task's progress and grant exp if completed.
        Returns a dict with 'updated' (bool) and 'granted_exp' (int).
        """
        assert self.db is not None, "Database connection is not initialized"
        try:
            result = await self.db.rpc_query(
                SupabaseRPC.SET_TASK_PROGRESS,
                {
                    "p_user_id": str(user_id),
                    "p_task_id": str(task_id),
                    "p_progress": progress,
                },
                mode="table",
            )
            return (
                result.data[0] if result.data else {"updated": False, "granted_exp": 0}
            )
        except Exception as e:
            print(f"Error setting task progress: {e}")
            return {"updated": False, "granted_exp": 0}

    async def update_user_experience(self, user_id: UUIDStr, gained_exp: int) -> dict:
        """
        Calls the update_user_experience RPC to update exp and level atomically.
        Returns a dict with 'new_exp' and 'new_level'.
        """
        assert self.db is not None, "Database connection is not initialized"
        try:
            result = await self.db.rpc_query(
                SupabaseRPC.UPDATE_USER_EXPERIENCE,
                {"p_user_id": str(user_id), "p_gained_exp": gained_exp},
            )
            return result.data[0] if result.data else {}
        except Exception as e:
            print(f"Error updating user experience: {e}")
            return {}


if __name__ == "__main__":
    # Example usage
    service = RPCService()
    user_id = UUID("b2977f0b-b464-4be3-9057-984e7ac4c9a9")  # Example user ID
    # check if they have not replaced the user_id with a real UUID
    # assert user_id != UUID(
    #     "b2977f0b-b464-4be3-9057-984e7ac4c9a9"
    # ), "Please replace user_id with a real UUID"

    async def main():
        # print(
        #     await service.get_question_statistics_by_type(
        #         target_word="草",
        #         # target_word=to_unicodeInt_from_char("草"),
        #         # question_type=QuestionType.FILL_IN_VOCAB,
        #     )
        # )
        # print(
        #     await service.get_wrong_word_count_by_user(
        #         user_id=user_id,
        #         target_word="草",
        #         # target_word=to_unicodeInt_from_char("草"),
        #         last_wrong_at=0,  # Example timestamp, adjust as needed
        #     )
        # )
        # print(
        #     await service.add_new_user_handle_exist(
        #         name="Mr exists",  # He is not in the database yet
        #         email="exists@example.com",
        #     )
        # )
        # He now exists, so re-run again will not create a new user
        print(
            await service.get_or_create_today_tasks(user_id=user_id)
        )  # Fetch or create today's tasks for the user
        # Mark a task as finished (replace with a real task ID)
        # task_id = "your_task_id_here"
        # result = await service.mark_task_finished(user_id=str(user_id), task_id=task_id)
        # print(f"Task finished: {result}")

    asyncio.run(main())

    # You can also test with other parameters as needed
