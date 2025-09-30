from fastapi import APIRouter, Form, File, UploadFile, HTTPException, Depends, status
from pydantic import BaseModel
from utils.logger import setup_logger
from models.db.db import User
from routers.dependencies import get_user
from models.helpers import UUIDStr


logger = setup_logger(__name__)

router = APIRouter(prefix="/testing", tags=["Testing"])


class CheckHandwriteAnswerResponse(BaseModel):
    user_id: UUIDStr
    filename: str
    content_type: str
    size: int  # Size of the uploaded file in bytes


@router.post("/check-answer", response_model=CheckHandwriteAnswerResponse)
async def upload_file(
    user_id: UUIDStr = Form(...), text: str = Form(...), image: UploadFile = File(...)
):
    if not image:
        raise HTTPException(status_code=400, detail="No file uploaded")

    # Save the uploaded file
    file_location = f"testing/{image.filename}"
    try:
        with open(file_location, "wb") as file:
            file.write(await image.read())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saving file: {str(e)}")

    # Return response with file details
    if not image.filename:
        logger.warning("Uploaded file has no filename, using 'unknown_file'")
    if not image.content_type:
        logger.warning("Uploaded file has no content type, using 'unknown'")

    return CheckHandwriteAnswerResponse(
        user_id=user_id,
        filename=image.filename if image.filename else "unknown_file",
        content_type=image.content_type if image.content_type else "unknown",
        size=len(image.file.read()),
    )

class AuthTemplateResponse(BaseModel):
    message: str
    user_id: UUIDStr
    username: str

@router.get("/auth-template", response_model=AuthTemplateResponse)
async def get_data(
    user: User = Depends(get_user) # Get current user from header
):
    # Check if request is valid
    if user.user_id:
        return AuthTemplateResponse(
            message="User authenticated successfully",
            user_id=user.user_id,
            username=user.name if user.name else "Unknown User"
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not authenticated",
        )


# @router.get("/mcq")
# async def generate_mcq(
#     question_generator: AIQuestionGenerator = Depends(get_ai_question_generator),
# ):
#     """
#     Generates a multiple-choice question based on the provided Chinese character.
#     """
#     try:
#         # 1. Get past wrong words from the database
#         # This part should be replaced with actual logic to get past wrong words

#         sample_characters = [
#             "晴",
#             "銀",
#             "店",
#             # "行",
#             # "吃",
#             "馬",
#             "鳥",
#             "書",
#             "學",
#         ]


#         # # 3. Format into MCQ class
#         # adapted_questions: List[FillInVocabQuestion] = []
#         # for mcq in generated_condensed_mcqs:
#         #     if not isinstance(mcq, FillInVocabFormat):
#         #         logger.warning(f"Generated question is not of type FillInVocabQuestion: {mcq}")
#         #         continue
#         #     adapted_question = Adaptor.fill_in_vocab(mcq)
#         #     # adapted_question = FillInVocabQuestion.model_validate(adapted_question)
#         #     adapted_questions.append(adapted_question)

#         # logger.info(f"Generated {len(adapted_questions)} MCQs")

#         # # 4. Return the adapted questions
#         # return JSONResponse(
#         #     status_code=status.HTTP_200_OK,
#         #     content={"questions": [q.model_dump() for q in adapted_questions]},
#         # )

#     except Exception as e:
#         logger.error(f"Error generating MCQ: {str(e)}")
#         raise HTTPException(status_code=500, detail=f"Error generating MCQ: {str(e)}")
