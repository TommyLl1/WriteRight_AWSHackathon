from typing import Optional
from uuid import UUID
from pydantic import BaseModel
from models.helpers import UnicodeInt, ChineseChar, UnixTimestamp


class UserWrongChar(BaseModel):
    word: ChineseChar
    last_wrong_at: UnixTimestamp
    wrong_count: int
    word_id: UnicodeInt
    priority: Optional[float] = None
