from models.helpers import UUIDStr
from pydantic import BaseModel, Field
from models.helpers import get_time, UnixTimestamp
from models.QnA import QuestionBase


# ------ Response Models ------------------------
class condensedUser(BaseModel):
    user_id: UUIDStr
    name: str
    level: int = Field(ge=1)  # User's level, starting from 1
    exp: int = Field(ge=0)  # User's experience points, starting from 0


class GameObject(BaseModel):
    questions: list[QuestionBase]
    generated_at: UnixTimestamp = get_time()
    user_id: UUIDStr
    game_id: UUIDStr
