from enum import Enum
from typing import Optional, List, Self, Dict, Callable, TypeAlias, Union
from pydantic import BaseModel, Field, EmailStr, model_validator
from uuid import uuid4
from models.helpers import *
from models.QnA import *
from models.QnA_builder import *
from utils.logger import setup_logger
import datetime
import pytz

logger = setup_logger(__name__)


class TaskStatus(str, Enum):
    ONGOING = "ongoing"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


class TaskClassTypes(str, Enum):
    DAILY = "daily"
    WORLD = "world"
    # Add more types as needed


class TaskTypeTypes(str, Enum):
    DAILY_ADVENTURE = "daily_adventure"
    WORLD_QUEST = "world_quest"
    # Add more content types as needed


class TaskContentBase(BaseModel):
    description: str


class DailyAdventureTaskContent(TaskContentBase):
    description: str = "每日任務: 完成一次冒險探索"


TaskContents: TypeAlias = (
    DailyAdventureTaskContent  # Extend with Union[...] for more types in future
)


class Task(BaseModel):
    task_id: UUIDStr = Field(default_factory=lambda: uuid4())
    user_id: UUIDStr
    task_class: TaskClassTypes = TaskClassTypes.DAILY
    type: TaskTypeTypes = TaskTypeTypes.DAILY_ADVENTURE
    created_at: UnixTimestamp = Field(default_factory=get_time)
    until: Optional[UnixTimestamp] = None
    status: TaskStatus = TaskStatus.ONGOING
    title: str = "每日任務"
    content: TaskContents
    priority: Optional[int] = 50
    completed_at: Optional[UnixTimestamp] = None
    exp: int = 10
    target: Optional[int] = None  # new field for target
    progress: Optional[int] = None  # new field for progress


def get_today_utc8_end_timestamp() -> int:
    tz = pytz.timezone("Asia/Shanghai")  # UTC+8
    now = datetime.datetime.now(tz)
    end_of_day = now.replace(hour=23, minute=59, second=59, microsecond=0)
    return int(end_of_day.timestamp())


class DailyAdventureTask(Task):
    type: TaskTypeTypes = TaskTypeTypes.DAILY_ADVENTURE
    title: str = "每日任務: 完成一次冒險探索"
    content: DailyAdventureTaskContent = DailyAdventureTaskContent()
    priority: Optional[int] = 100
    until: Optional[int] = Field(default_factory=get_today_utc8_end_timestamp)
