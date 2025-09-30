from typing import Any
from models.helpers import UUIDStr, ChineseChar, get_time
from models.db.db import *
from utils.database.base import DatabaseService
from utils.config import config
from utils.logger import setup_logger
from models.services import *
from features.word_service import WordService
from math import floor
from utils.rpc_service import RPCService
import asyncio

logger = setup_logger(__name__)

# EXP_required_to_reach_level = 10 * (Level ^ growth_rate)
# Growth rate is 1.5, so the EXP required to reach level n is:
# EXP_required_to_reach_level = 10 * (level ^ 1.5)
# level = floor((exp/10)^(1/growth_rate))
# Each game gain around 50-100 EXP


class UserService:
    def __init__(
        self,
        db: DatabaseService,
        word_service: WordService,
        rpc_service: RPCService,
    ):
        self.db = db
        self.lv_growth_rate = float(str(config.get("User.LvGrowthRate", 1.5)))
        self.inverse_lv_growth_rate = 1 / self.lv_growth_rate
        self.word_service = word_service
        self.rpc_service = rpc_service

    def _calculate_level(self, exp: int) -> int:
        """
        DEPRECATED: Levels are now calculated DB-side via RPC.

        Calculates the user's level based on their experience points.
            exp_required = 10 * (level ^ growth_rate)
        inverse formula to calculate level from exp:
            level = floor((exp / 10) ^ (1 / growth_rate))
        """
        if exp < 0:
            return 1
        return floor((exp / 10) ** self.inverse_lv_growth_rate)

    async def update_experience(self, user_id: UUIDStr, gained_exp: int) -> None:
        """
        Levels are now calculated DB-side via RPC.
        This function serves as a compatibility layer for the old system.

        Updates the user's experience points using the update_user_experience RPC via the rpc service.
        """
        try:
            result = await self.rpc_service.update_user_experience(user_id, gained_exp)
            if result:
                new_exp = result.get("new_exp")
                new_level = result.get("new_level")
                logger.info(
                    f"Updated user {user_id} experience to {new_exp}, level to {new_level}."
                )
            else:
                logger.error(
                    f"No data returned from update_user_experience RPC for user {user_id}."
                )
        except Exception as e:
            logger.error(f"Error updating experience for user {user_id}: {e}")

    async def get_user_wrong_dictionary(
        self,
        user_id: UUIDStr,
        limit: int = int(str(config.get("QuestionGenerator.TopNRecent", 50))),
        offset: int = 0,
        no_paging: bool = False,
    ) -> List[GetPastWrongWordsByUserResponse]:
        """
        Fetches the user's wrong words dictionary from the database.
        """
        try:
            # hard code the limit to 6000 if no_paging is True
            # avoid big query
            if no_paging:
                limit = 6000
                offset = 0
            else:
                assert 0 < limit <= 100, "Limit must be between 1 and 100"
            result = await self.db.rpc_query(
                SupabaseRPC.GET_USER_WRONG_WORDS_BY_USER,
                GetPastWrongWordsByUserRPC(
                    p_user_id=user_id, p_limit=limit, p_offset=offset
                ).model_dump(),
            )
            logger.debug(result)
            if not result.data:
                logger.warning(f"No wrong words found for user {user_id}.")
                return []
            return [
                GetPastWrongWordsByUserResponse.model_validate(item)
                for item in result.data
            ]
        except Exception as e:
            print(f"Error fetching user wrong words: {e}")
            return []

    async def get_user_wrong_words(self, user_id: UUIDStr) -> list[UserWrongChar]:
        """
        Fetches the user's wrong words from the database.
        Returns a list of Chinese characters.
        """
        try:
            response = await self.db.filter_data(
                SupabaseTable.PAST_WRONG_WORDS,
                condition={"user_id": user_id},
                columns=["word_id", "wrong_count", "last_wrong_at"],
            )
        except Exception as e:
            logger.error(f"Error fetching user wrong words: {e}")
            return []
        if not response.data:
            logger.warning(f"No wrong words found for user {user_id}.")
            return []

        # Extract the words from the response
        wrong_words = [
            UserWrongChar(
                word=to_char_from_unicode(item["word_id"]),
                word_id=item["word_id"],
                wrong_count=item["wrong_count"],
                last_wrong_at=item["last_wrong_at"],
            )
            for item in response.data
        ]
        logger.info(f"Fetched {len(wrong_words)} wrong words for user {user_id}.")
        return wrong_words

    # Unused?
    async def update_wrong_word_dictionary(
        self, user_id: UUIDStr, wrong_words: list[ChineseChar]
    ) -> None:
        """
        Use RPC to update the user's wrong word dictionary.
        Seperated with update url, cause sometimes might not update it (Wrong in a game)
        """
        try:
            # Prepare the data for the RPC call
            wrong_words_ids = [to_unicodeInt_from_char(word) for word in wrong_words]
            await self.db.rpc_query(
                SupabaseRPC.INCREMENT_WRONG_COUNT_FOR_USER,
                IncrementWrongCountForUserRPC(
                    p_user_id=user_id, p_word_ids=wrong_words_ids
                ).model_dump(),
            )
            logger.info(f"Updated wrong word dictionary for user {user_id}.")
        except Exception as e:
            logger.error(
                f"Error updating wrong word dictionary for user {user_id}: {e}"
            )

    async def add_wrong_word(
        self, user_id: UUIDStr, word: ChineseChar
    ) -> PastWrongWord:
        """
        Adds a wrong word to the user's wrong word dictionary.
        If the word does not exist, it will be created.
        If the word already exists for the user, it will update the wrong count and last wrong time.
        """

        word_result = await self.db.filter_data(
            SupabaseTable.WORDS,
            condition={"word": word},
            columns=["word_id"],
        )
        if not word_result.data:
            # If the word does not exist, create a new word entry
            new_entry = await self.word_service.create_new_word_db_entry(word)
            word = new_entry.word  # Use the word from the new entry

        # Add the word to the user's wrong word dictionary
        word_id = to_unicodeInt_from_char(word)
        try:
            user_wrong_word = PastWrongWord(
                word_id=word_id,
                user_id=user_id,
            )
            # Check if the word already exists for the user
            existing_wrong_word = await self.db.filter_data(
                SupabaseTable.PAST_WRONG_WORDS,
                condition={
                    "user_id": user_id,
                    "word_id": word_id,
                },
                columns=["word_id", "wrong_count", "last_wrong_at"],
            )
            curr_Time = get_time()
            if existing_wrong_word.data:
                # If the word already exists, update the wrong count and last wrong at to db
                update_result = await self.db.update_data(
                    SupabaseTable.PAST_WRONG_WORDS,
                    condition={
                        "user_id": user_id,
                        "word_id": word_id,
                    },
                    data={
                        "wrong_count": existing_wrong_word.data[0]["wrong_count"] + 1,
                        "last_wrong_at": curr_Time,
                    },
                )
                if not update_result.data:
                    logger.error(
                        f"Failed to update wrong word for user {user_id} and word {word}."
                    )
                    raise Exception("Failed to update wrong word in database.")
                return PastWrongWord(
                    word_id=word_id,
                    user_id=user_id,
                    wrong_count=existing_wrong_word.data[0]["wrong_count"] + 1,
                    last_wrong_at=curr_Time,
                )
            # If the word does not exist, insert a new entry
            new_wrong_word = PastWrongWord(
                word_id=word_id,
                user_id=user_id,
                wrong_count=1,  # Initialize wrong count to 1
                last_wrong_at=curr_Time,  # Set the current time as last wrong time
            )
            await self.db.insert_data(
                SupabaseTable.PAST_WRONG_WORDS,
                data=user_wrong_word.model_dump(),
            )
        except Exception as e:
            logger.error(f"Error adding wrong word: {e}")
            raise

        logger.info(f"Added wrong word: {word} for user {user_id}.")
        return new_wrong_word

    async def add_wrong_words(self, user_id: UUIDStr, words: list[ChineseChar]) -> None:
        """
        Adds a wrong word to the user's wrong word dictionary.
        If the word does not exist, it will be created.
        If the word already exists for the user, it will update the wrong count and last wrong time.
        Same as add_wrong_word, but for multiple words.
        """
        ## Prepare all existing words and new words
        word_ids = [to_unicodeInt_from_char(word) for word in words]
        logger.debug(f"Word IDs to process: {word_ids}")
        existing_words = await self.word_service.get_existing_words(word_ids)
        logger.debug(f"Existing words: {existing_words}")
        not_existing_words = [
            word
            for word in words
            if to_unicodeInt_from_char(word)
            not in [existing_word.word_id for existing_word in existing_words]
        ]
        logger.debug(f"Not existing words: {not_existing_words}")
        add_word_tasks = [
            self.word_service.create_new_word_db_entry(word)
            for word in not_existing_words
        ]
        await asyncio.gather(*add_word_tasks)
        logger.info(f"Added {len(not_existing_words)} new words for user {user_id}.")

        ## Seperate existing and new wrong word items
        try:
            existing_wrong_word_ids_response = await self.db.rpc_query(
                SupabaseRPC.GET_EXISTING_WRONG_WORD_IDS,
                GetExistingWrongWordIdsRPC(
                    p_user_id=user_id, word_ids=word_ids
                ).model_dump(),
                return_type=PastWrongWord,
            )
        except Exception as e:
            logger.error(f"Error fetching existing wrong word IDs: {e}")
            raise
        existing_wrong_words = existing_wrong_word_ids_response.data
        existing_wrong_word_ids = [
            wrong_word.word_id for wrong_word in existing_wrong_words
        ]
        logger.debug(f"Existing wrong word IDs: {existing_wrong_word_ids}")

        await self.db.rpc_query(
            SupabaseRPC.INCREMENT_WRONG_COUNT_FOR_USER,
            IncrementWrongCountForUserRPC(
                p_user_id=user_id, p_word_ids=existing_wrong_word_ids  # type: ignore
            ).model_dump(),
        )

        ## Create new wrong word entries for the new words
        non_existing_wrong_words = [
            PastWrongWord(
                word_id=to_unicodeInt_from_char(word),
                user_id=user_id,
                wrong_count=1,  # Initialize wrong count to 1
                last_wrong_at=get_time(),  # Set the current time as last wrong time
            )
            for word in words
            if to_unicodeInt_from_char(word) not in existing_wrong_word_ids
        ]
        insert_tasks = [
            self.db.insert_data(
                SupabaseTable.PAST_WRONG_WORDS,
                data=wrong_word.model_dump(),
            )
            for wrong_word in non_existing_wrong_words
        ]
        await asyncio.gather(*insert_tasks)
        logger.info(
            f"Added {len(non_existing_wrong_words)} wrong words for user {user_id}."
        )
        return

    async def batch_add_wrong_words_raw(
        self, user_id: UUIDStr, wrong_words: list[PastWrongWord]
    ) -> List[PastWrongWord]:
        """
        Adds or updates a batch of wrong words for the user's wrong word dictionary.
        If a word does not exist, it will be created.
        If a word already exists for the user, it will update the wrong count and last wrong time.

        Args:
            user_id (UUIDStr): The ID of the user.
            wrong_words (list[PastWrongWord]): A list of PastWrongWord objects to process.
        """
        try:
            # Extract word IDs from the input list
            word_ids = [wrong_word.word_id for wrong_word in wrong_words]
            logger.debug(f"Processing word IDs: {word_ids}")

            # Fetch existing words from the database
            existing_words = await self.word_service.get_existing_words(word_ids)
            existing_word_ids = [word.word_id for word in existing_words]
            logger.debug(f"Existing word IDs: {existing_word_ids}")

            # Identify words that do not exist in the database
            not_existing_words = [
                wrong_word
                for wrong_word in wrong_words
                if wrong_word.word_id not in existing_word_ids
            ]
            logger.debug(f"Words to create: {not_existing_words}")

            # Create new word entries for non-existing words
            create_tasks = [
                self.word_service.create_new_word_db_entry(
                    to_char_from_unicode(wrong_word.word_id)
                )
                for wrong_word in not_existing_words
            ]
            await asyncio.gather(*create_tasks)
            logger.info(
                f"Created {len(not_existing_words)} new words for user {user_id}."
            )

            # Fetch existing wrong word entries for the user
            existing_wrong_word_ids_response = await self.db.rpc_query(
                SupabaseRPC.GET_EXISTING_WRONG_WORD_IDS,
                GetExistingWrongWordIdsRPC(
                    p_user_id=user_id, word_ids=word_ids
                ).model_dump(),
                return_type=PastWrongWord,
            )
            existing_wrong_words = existing_wrong_word_ids_response.data
            existing_wrong_word_ids = [
                wrong_word.word_id for wrong_word in existing_wrong_words
            ]
            logger.debug(f"Existing wrong word IDs: {existing_wrong_word_ids}")

            # Update wrong count and last wrong time for existing wrong words
            update_tasks = [
                self.db.update_data(
                    SupabaseTable.PAST_WRONG_WORDS,
                    condition={
                        "user_id": user_id,
                        "word_id": wrong_word.word_id,
                    },
                    data={
                        "wrong_count": wrong_word.wrong_count + 1,
                        "last_wrong_at": get_time(),
                        # FIXME: now is overwriting the old image url, need to delete the old image url?
                        "wrong_image_url": wrong_word.wrong_image_url,
                    },
                    return_type=PastWrongWord,
                )
                for wrong_word in wrong_words
                if wrong_word.word_id in existing_wrong_word_ids
            ]
            responses = await asyncio.gather(*update_tasks)
            updated_past_wrong_words = [
                responses.data[0] for responses in responses if responses.data
            ]

            logger.info(
                f"Updated {len(updated_past_wrong_words)} existing wrong words for user {user_id}."
            )

            # Insert new wrong word entries for non-existing wrong words
            non_existing_wrong_words = [
                wrong_word
                for wrong_word in wrong_words
                if wrong_word.word_id not in existing_wrong_word_ids
            ]
            ## ensure correct data for input
            for wrong_word in non_existing_wrong_words:
                wrong_word.user_id = user_id
                wrong_word.wrong_count = 1  # Initialize wrong count to 1
                wrong_word.last_wrong_at = (
                    get_time()
                )  # Set the current time as last wrong time

            insert_tasks = [
                self.db.insert_data(
                    SupabaseTable.PAST_WRONG_WORDS,
                    data=wrong_word.model_dump(),
                )
                for wrong_word in non_existing_wrong_words
            ]
            await asyncio.gather(*insert_tasks)
            logger.info(
                f"Inserted {len(non_existing_wrong_words)} new wrong words for user {user_id}."
            )
        except Exception as e:
            logger.error(
                f"Error processing batch of wrong words for user {user_id}: {e}"
            )
            raise

        return non_existing_wrong_words + updated_past_wrong_words

    async def get_user_wrong_word_count(self, user_id: UUIDStr) -> int:
        """
        Returns the total count of wrong words for a user.
        """
        try:
            response = await self.db.count_data(
                SupabaseTable.PAST_WRONG_WORDS,
                condition={"user_id": user_id},
            )
            return response
        except Exception as e:
            logger.error(f"Error fetching wrong word count for user {user_id}: {e}")
            return 0
