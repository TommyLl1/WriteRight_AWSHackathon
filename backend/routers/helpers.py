from fastapi import HTTPException
from typing import Optional
from models.db.db import SupabaseTable, ChineseChar, Word, UUID
from utils.database.base import DatabaseService
from models.helpers import APIResponse, UnicodeInt
from models.word_info import language
from utils.word_info_scraper import WordInfoScraper
from utils.logger import setup_logger

logger = setup_logger(__name__)


async def get_word_id_from_db(
    db: DatabaseService, word: ChineseChar
) -> Optional[UnicodeInt]:
    """
    Helper function to get the word ID from the database.
    Returns None if the word does not exist.
    """
    try:
        logger.info(f"Checking if word exists: {word}")
        response: APIResponse[Word] = await db.filter_data(
            table=SupabaseTable.WORDS, condition={"word": word}, return_type=Word
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error checking word existence: {str(e)}"
        )
    logger.info(f"Response from words db: {response}")
    if not response.data:
        return None
    word_id = response.data[0].word_id
    if not word_id:
        raise HTTPException(
            status_code=404, detail="Word ID not found in the database response"
        )
    logger.info(f"Found existing word ID: {word_id}")
    return word_id


async def add_word_to_db(db: DatabaseService, word: ChineseChar) -> UnicodeInt:
    """
    Helper function to add a new word to the database.
    Returns the newly created word ID.
    """
    # TODO: reuse the word info scraper object
    # Use Word service class -> use dependency
    try:
        scraper = WordInfoScraper()
        logger.info(f"Scraping definition for word: {word}")
        word_info = scraper.get_word_info(word)
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error scraping WordInfo for {word}: {str(e)}"
        )

    # TODO: using english definition for now, need to change later
    new_word = Word(
        word=word,
        description=word_info.english,
        pronunciation_url=scraper.get_pronunciation_url(
            word_info.pingyin.cantonese[0], language.CANTONESE
        ),
        strokes_url=scraper.get_word_stroke_image(word_info),
    )

    try:
        await db.insert_data(
            table=SupabaseTable.WORDS, data=new_word.model_dump(mode="json")
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error creating new word: {str(e)}"
        )
    logger.info(f"Created new word: {new_word.word} with ID: {new_word.word_id}")
    return new_word.word_id
