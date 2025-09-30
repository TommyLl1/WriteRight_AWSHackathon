from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional, List, Dict
from routers.dependencies import (
    get_database,
    get_user_service,
    get_text_recognition_service,
)
from models.db.db import (
    PastWrongWord,
    ChineseChar,
    UUID,
    GetPastWrongWordsByUserResponse,
)
from AI_text_recognition.utils_m.user_service import PastWrongWord_m
from utils.database.base import DatabaseService
from utils.config import config
from features.user_service import UserService
from models.helpers import UUIDStr
from AI_text_recognition.main import TextRecognitionService
from utils.logger import setup_logger

logger = setup_logger(__name__, level="DEBUG")

router = APIRouter(prefix="/wrong-words", tags=["Wrong Words"])


class GetUserWrongWordsResponse(BaseModel):
    items: list[GetPastWrongWordsByUserResponse]  # List of user's wrong words
    page: int  # Current page number
    page_size: int  # Number of items per page
    count: int  # Total number of items in the dictionary


@router.get("", response_model=GetUserWrongWordsResponse)
async def get_user_wrong_word_dictionary(
    user_id: UUIDStr,
    db: DatabaseService = Depends(get_database),
    no_paging: bool = False,  # If true, return all items without paging
    page: int = 1,  # Default to the first page
    page_size: int = config.get(
        "WrongWordDictionary.PageSize", 10
    ),  # Default page size
    user_service: UserService = Depends(get_user_service),
):
    """
    Fetches the user's wrong word dictionary.
    """
    if not (0 < page_size <= 100) and not no_paging:
        raise HTTPException(status_code=400, detail="Invalid page size")
    if page < 1:
        raise HTTPException(
            status_code=400, detail="Page number must be greater than 0"
        )

    try:
        # Fetch the user's wrong words dictionary
        # no_paging hardcoded to 6000, avoid big query
        items = await user_service.get_user_wrong_dictionary(
            user_id, limit=page_size, offset=(page - 1) * page_size, no_paging=no_paging
        )
        return GetUserWrongWordsResponse(
            items=items,
            page=page,
            page_size=page_size,
            count=len(items),  # Assuming items is a list of wrong words
        )
    except HTTPException as e:
        raise e


@router.get(
    "/count",
    response_model=int,
    summary="Get the count of wrong words for a user",
)
async def get_user_wrong_word_count(
    user_id: UUIDStr,
    user_service: UserService = Depends(get_user_service),
):
    """
    Fetches the count of wrong words for a user.
    """
    try:
        # Get the count of wrong words for the user
        count = await user_service.get_user_wrong_word_count(user_id)
        return count
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error fetching wrong word count: {str(e)}"
        )


# Temp function only
class AddWrongWordRequest(BaseModel):
    user_id: UUID
    word: ChineseChar


class AddWrongWordResponse(BaseModel):
    message: str
    data: Optional[PastWrongWord]


@router.post(
    "",
    response_model=AddWrongWordResponse,
    status_code=status.HTTP_201_CREATED,
)
async def user_add_wrong_word(
    add_wrong_word_request: AddWrongWordRequest,
    user_service: UserService = Depends(get_user_service),
):
    """
    Endpoint to add a wrong word for a user.

    Note: This part is in testing, real one should be done with scanning function
    """
    try:
        # Add the wrong word to the user's wrong word dictionary
        response = await user_service.add_wrong_word(
            add_wrong_word_request.user_id, add_wrong_word_request.word
        )
        return AddWrongWordResponse(
            message="Wrong word added successfully", data=response
        )
    except HTTPException as e:
        raise e


class ScanningRequest(BaseModel):
    user_id: UUIDStr
    uploaded_url: str


class ScanningResponse(BaseModel):
    data: List[PastWrongWord_m]  # List of wrong words detected in the image
    not_found: Optional[Dict[ChineseChar, str]] = (
        None  # Words not found in the dictionary
    )


@router.post("/scanning", response_model=ScanningResponse)
async def scanning_wrong_words(
    scanning_request: ScanningRequest,
    text_recognition_service: TextRecognitionService = Depends(
        get_text_recognition_service
    ),
):
    try:
        data, not_found = await text_recognition_service.get_wrong_words(
            scanning_request.uploaded_url, scanning_request.user_id
        )
        result = ScanningResponse.model_validate(
            {
                "data": [item.model_dump() for item in data],
                "not_found": (
                    {item.wrong_char: item.wrong_image_url for item in not_found}
                    if not_found
                    else None
                ),
            }
        )
        logger.info(f"Scanning result: {result}")
        return result
    except HTTPException as e:
        logger.error(f"Error scanning wrong words: {e.detail}")
        raise e
    except Exception as e:
        logger.error(f"Error scanning wrong words: {e}")
        stringify = str(e)
        if "E-422" in stringify:
            raise HTTPException(
                status_code=422, detail="No text detected in the image."
            )
        if "E-413" in stringify:
            raise HTTPException(
                status_code=413,
                detail="Image size is too large to process. Please crop or resize the image.",
            )
        raise HTTPException(
            status_code=500, detail=f"Error scanning wrong words: {str(e)}"
        )

    # # Find the word ID first
    # word_id = await get_word_id_from_db(db, add_wrong_word_request.word)

    # # If no matching word found, create a new word entry
    # if word_id is None:
    #     # Create a new Word instance
    #     word_id = await add_word_to_db(
    #         db,
    #         word=add_wrong_word_request.word,
    #         # definition="Placeholder definition",  # Replace with actual definition logic
    #     )

    # # word_id must be set at this point
    # try:
    #     # Insert the wrong word into the database
    #     new_wrong_word = PastWrongWord(
    #         word_id=word_id,  # Use the found or created word ID
    #         user_id=add_wrong_word_request.user_id,
    #     )
    #     response = await db.insert_data(
    #         table=SupabaseTable.PAST_WRONG_WORDS.value, data=new_wrong_word.model_dump()
    #     )
    # except Exception as e:
    #     raise HTTPException(
    #         status_code=500, detail=f"Error adding wrong word: {str(e)}"
    #     )
    # # Check if the insertion was successful
    # if not response.data:
    #     raise HTTPException(
    #         status_code=400,
    #         detail="Failed to add wrong word to the wrong word database",
    #     )
    # logger.info(f"Added wrong word: {response.data[0]}")

    # # Return the response with the added wrong word
    # return AddWrongWordResponse(
    #     message="Wrong word added successfully", data=response.data[0]
    # )
