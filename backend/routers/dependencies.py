from fastapi import Depends, HTTPException, Request
from utils.database.factory import get_database_service
from utils.LLMService import LLMService
from features.user_service import UserService
from features.game_service import GameService
from features.question_service import QuestionService
from features.word_service import WordService
from features.LLM_request_manager import LLMRequestManager
from utils.storage_service import StorageController
from features.LLM_request_manager import LLMRequestManager
from utils.rpc_service import RPCService
from utils.word_info_scraper import WordInfoScraper
from typing import List
from features.auth_service import AuthService, SAMPLE_SESSION_ID, SAMPLE_USER_ID
from models.db.db import User
from utils.database.base import DatabaseService
from utils.config import config
from AI_text_recognition.main import TextRecognitionService

########## Dependencies injection for FastAPI ##########


def get_database():
    """
    Dependency to get a database connection.
    """
    try:
        ## NOTE: Replace with other database if needed
        db = get_database_service()
        return db
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Database connection error: {str(e)}"
        )


def get_word_info_scraper():
    """
    Dependency to get a singleton instance of the WordInfoScraper.
    This avoids creating multiple scraper instances.
    """
    try:
        return WordInfoScraper()
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Word info scraper initialization error: {str(e)}"
        )


def get_rpc_service(
    db: DatabaseService = Depends(get_database),
):
    """Dependency to get an instance of the RPCService.
    This service is used to interact with database RPCs.
    """
    try:
        return RPCService(db=db)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"RPC service initialization error: {str(e)}",
        )


def get_llm():
    """
    Dependency to get an instance of the LLMService.
    """
    try:
        llm_service = LLMService()
        return llm_service
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"LLM service initialization error: {str(e)}"
        )


def get_ai_question_generator():
    """
    Dependency to get an instance of the AIQuestionGenerator.
    """
    from features.AI_question_generator import AIQuestionGenerator

    return AIQuestionGenerator()


def get_word_service(
    db: DatabaseService = Depends(get_database),
    scraper: WordInfoScraper = Depends(get_word_info_scraper),
):
    """
    Dependency to get an instance of the WordService.
    """
    from features.word_service import WordService

    return WordService(db=db, scraper=scraper)


def get_user_service(
    db: DatabaseService = Depends(get_database),
    word_service: WordService = Depends(get_word_service),
    rpc_service: RPCService = Depends(get_rpc_service),
):
    """
    Dependency to get an instance of the UserService.
    """
    from features.user_service import UserService

    return UserService(db=db, word_service=word_service, rpc_service=rpc_service)


def get_game_service(
    db: DatabaseService = Depends(get_database),
    user_service: UserService = Depends(get_user_service),
    word_service: WordService = Depends(get_word_service),
):
    """
    Dependency to get an instance of the GameService.
    """
    from features.game_service import GameService

    return GameService(db=db, user_service=user_service)


def get_storage_service():
    """
    Dependency to get an instance of the S3Service.
    """
    try:
        return StorageController()
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"S3 service initialization error: {str(e)}"
        )


def get_llm_request_manager(request: Request):
    return request.app.state.llm_request_manager


def get_question_statistics_service(
    db: DatabaseService = Depends(get_database),
    user_service: UserService = Depends(get_user_service),
):
    """
    Dependency to get an instance of the RPCService.
    """
    return RPCService(db=db)


def get_question_generator(
    db: DatabaseService = Depends(get_database),
    # llm: LLMService = Depends(get_llm),
    word_service: WordService = Depends(get_word_service),
    user_service: UserService = Depends(get_user_service),
    llm_request_manager: LLMRequestManager = Depends(get_llm_request_manager),
    storage_service: StorageController = Depends(get_storage_service),
    question_statistics_service: RPCService = Depends(get_question_statistics_service),
):
    """
    Dependency to get an instance of the QuestionService.
    """
    from features.question_service import QuestionService

    return QuestionService(
        db=db,
        # llm_service=llm,
        word_service=word_service,
        user_service=user_service,
        llm_request_manager=llm_request_manager,
        storage_service=storage_service,
        question_statistics_service=question_statistics_service,
    )


def get_auth_service(
    db: DatabaseService = Depends(get_database),
):
    """
    Dependency to get an instance of the AuthService.
    """
    from features.auth_service import AuthService

    return AuthService(db=db)


async def get_user(
    request: Request,  # Request object to access headers
    auth_service: AuthService = Depends(get_auth_service),
) -> User:
    """
    Dependency that fetches the current user based on the session key in the Authorization header.
    """
    # Extract the Authorization header
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=401, detail="Authorization header missing or invalid"
        )

    # Extract the session key from the header
    session_id = auth_header[len("Bearer ") :]  # Remove "Bearer " prefix

    # Fetch with sample session ID
    user = await auth_service.fetch_user(SAMPLE_SESSION_ID)
    return user


async def get_text_recognition_service(request: Request) -> TextRecognitionService:
    return request.app.state.text_recognition_service
