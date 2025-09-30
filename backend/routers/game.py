from fastapi import APIRouter, Depends, HTTPException
from routers.dependencies import *
from features.question_service import QuestionService
from uuid import uuid4
from models.helpers import get_time, UUIDStr
from models.api_response import GameObject
from features.game_service import GameService
from models.db.db import GameData, FlaggedQuestionStatus
from utils.logger import setup_logger
from typing import Optional
from pydantic import BaseModel
from AI_text_recognition.main import TextRecognitionService
from AI_text_recognition.wrong_word_batching import WrongWordEntry

logger = setup_logger(__name__, level="DEBUG")

router = APIRouter(prefix="/game", tags=["Game"])


@router.get("/start/{userId}", response_model=GameObject)
async def start_game(
    userId: UUIDStr,
    qCount: int = 1,
    question_generator: QuestionService = Depends(get_question_generator),
    game_service: GameService = Depends(get_game_service),
):
    """
    Starts a new game session for the specified user.

    Args:
        userId (UUIDStr): The unique identifier of the user.
        qCount (int, optional): The number of questions to generate for the game. Defaults to 1.
        question_generator (QuestionService): Dependency injection for the question generator service.
        game_service (GameService): Dependency injection for the game service.

    Returns:
        GameObject: An object containing the generated questions, game ID, user ID, and timestamp.

    Raises:
        HTTPException: If there is an error generating questions or creating the game session.
    """
    # Validate qCount
    if not isinstance(qCount, int) or not 0 < qCount <= 20:
        raise HTTPException(
            status_code=400,
            detail="qCount must be an integer between 1 and 20",
        )

    # Get the questions first
    try:
        questions = await question_generator.generate_by_user_id(userId, qCount)
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error generating question: {str(e)}"
        )

    if not questions:
        raise HTTPException(
            status_code=404, detail="No questions generated for the user"
        )

    # Create a game session
    try:
        game_id = await game_service.create_game_session(
            userId, [q.question_id for q in questions]
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error creating game session: {str(e)}"
        )
    if not game_id:
        logger.error("Failed to create game session: No game_id returned")
        raise HTTPException(status_code=500, detail="Failed to create game session")

    # Prepare the game object to return
    game_object = GameObject(questions=questions, user_id=userId, game_id=game_id)
    # logger.debug(game_object)
    return game_object


@router.post("/submit-result", response_model=GameData)
async def submit_result(
    result: GameObject,
    game_service: GameService = Depends(get_game_service),
):
    """
    Submits the game results for the specified user and game.
    """
    try:
        # exp_gain = 0
        # for question in result.questions:
        #     if question.is_correct():
        #         exp_gain += question.exp

        out: GameData = await game_service.submit_game_answers(
            result.questions, game_id=result.game_id
        )
        logger.debug(f"Game result submitted: {out}")
        return out
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error submitting result: {str(e)}"
        )


class FlagQuestionRequest(BaseModel):
    question_id: UUIDStr
    user_id: UUIDStr
    reason: Optional[str] = None
    notes: Optional[str] = None


class FlagQuestionResponse(BaseModel):
    flag_id: UUIDStr
    status: FlaggedQuestionStatus


@router.post("/flag-questions", response_model=FlagQuestionResponse, status_code=201)
async def flag_question(
    req: FlagQuestionRequest,
    game_service: GameService = Depends(get_game_service),
):
    """
    Endpoint to flag a problematic question for manual review.
    """
    try:
        result = await game_service.flag_question(
            question_id=req.question_id,
            user_id=req.user_id,
            reason=req.reason,
            notes=req.notes,
        )
        # Ensure flag_id is present in result, else fallback to status only
        assert result.flag_id, "Missing flag_id in the result"
        return FlagQuestionResponse(flag_id=result.flag_id, status=result.status)
    except Exception as e:
        logger.error(f"Error flagging question: {e}")
        raise HTTPException(
            status_code=500, detail=f"Error flagging question: {str(e)}"
        )


class CheckHandwriteAnswerRequest(BaseModel):
    user_id: UUIDStr
    game_id: UUIDStr
    target_word: str
    image_url: str


@router.post("/check-handwrite-answer", response_model=WrongWordEntry)
async def check_handwrite_answer(
    request: CheckHandwriteAnswerRequest,
    text_recognition_service: TextRecognitionService = Depends(
        get_text_recognition_service
    ),
):
    """
    Endpoint to check a handwritten answer against the target word.
    """
    try:
        result = await text_recognition_service.check_handwrite_answer(
            handwrite_image_url=request.image_url,
            target_word=request.target_word,
            user_id=request.user_id,
        )
        return result
    except Exception as e:
        logger.error(f"Error checking handwritten answer: {e}")
        raise HTTPException(
            status_code=500, detail=f"Error checking handwritten answer: {str(e)}"
        )


# @router.get("/get-question/{user_id}", response_model=QuestionResponse)
# async def get_question(
#     user_id: UUID,
#     question_generator: QuestionService = Depends(get_question_generator),
# ):
#     """
#     Fetches a question based on the specified difficulty level.
#     """
#     try:
#         question = await question_generator.generate_by_user_id(user_id)
#         if not question:
#             raise HTTPException(status_code=404, detail="No question found for the user")
#         return question
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"Error fetching question: {str(e)}"
