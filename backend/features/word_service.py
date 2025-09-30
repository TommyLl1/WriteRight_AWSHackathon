from fastapi import HTTPException
from models.db.db import Word
from utils.logger import setup_logger
from utils.word_info_scraper import WordInfoScraper, language
from utils.database.base import DatabaseService
from models.db.db import SupabaseTable, SupabaseRPC, GetRandomWordsRPC, GetExistingWordsRPC
from models.helpers import ChineseChar, UUIDStr, UnicodeInt

logger = setup_logger(__name__)


class WordService:
    def __init__(self, db: DatabaseService, scraper: WordInfoScraper):
        self.db = db
        self.scraper = scraper

    async def create_new_word_db_entry(self, word: ChineseChar) -> Word:
        # Use the injected scraper instead of creating a new one
        logger.info(f"Scraping definition for word: {word}")
        try:
            word_info = self.scraper.get_word_info(word)
        except ValueError as e:
            logger.error(f"Error scraping word info for {word}: {e}")
            raise HTTPException(
                status_code=400,
                detail=f"Invalid word: {word}. Please provide a valid Chinese character.",
            )
        except Exception as e:
            logger.error(f"Unexpected error while scraping word info: {e}")
            raise HTTPException(
                status_code=500, detail="Error fetching word information."
            )

        new_word = Word(
            word=word,
            description=word_info.english,
            pronunciation_url=self.scraper.get_pronunciation_url(
                word_info.pingyin.cantonese[0], language.CANTONESE
            ),
            strokes_url=self.scraper.get_word_stroke_image(word_info),
        )

        await self.db.insert_data(
            table=SupabaseTable.WORDS, data=new_word.model_dump(mode="json")
        )

        logger.info(f"Created new word: {new_word.word} with ID: {new_word.word_id}")
        return new_word
    
    async def get_random_words(self, count: int) -> list[Word]:
        response = await self.db.rpc_query(
            SupabaseRPC.GET_RANDOM_WORDS,
            params=GetRandomWordsRPC(count=count).model_dump(mode="json"),
            return_type=Word,
        )
        return response.data

    async def get_existing_words(
        self, word_ids: list[UnicodeInt]
    ) -> list[Word]:

        response = await self.db.rpc_query(
            SupabaseRPC.GET_EXISTING_WORDS,
            params=GetExistingWordsRPC(
                word_ids=word_ids
            ).model_dump(mode="json"),

            return_type=Word,
        )
        return response.data