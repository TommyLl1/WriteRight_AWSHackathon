from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import UUID4, BaseModel
from typing import List
from utils.rpc_service import RPCService
from models.helpers import UUIDStr
from models.db.tasks import Task, TaskStatus
from utils.database.base import DatabaseService
from models.db.db import SupabaseTable
from time import time
from routers.dependencies import get_rpc_service, get_database
from uuid import UUID

router = APIRouter(prefix="/tasks", tags=["User Tasks"])


@router.get("/current", response_model=List[Task])
async def get_current_tasks(
    user_id: UUIDStr,  # Accept as UUIDStr from request
    rpc_service: RPCService = Depends(get_rpc_service),
):
    """
    Get the current valid tasks for the user (auto-creates today's daily task if needed).
    """
    try:
        tasks = await rpc_service.get_or_create_today_tasks(UUID(str(user_id)))
        return tasks
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching tasks: {e}")


class SetTaskProgressRequest(BaseModel):
    user_id: UUIDStr
    task_id: UUIDStr
    progress: int


class SetTaskProgressResponse(BaseModel):
    message: str
    granted_exp: int = 0  # XP granted if the task was completed


@router.post("/progress", status_code=status.HTTP_200_OK)
async def set_task_progress(
    req: SetTaskProgressRequest,
    rpc_service: RPCService = Depends(get_rpc_service),
) -> SetTaskProgressResponse:
    """
    Update a task's progress for the user and grant XP if completed using the RPC.
    """
    try:
        result = await rpc_service.set_task_progress(
            req.user_id, req.task_id, req.progress
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error updating task progress: {e}"
        )
    # updated means the task was found and updated
    # Even when it already completed, it will still return updated as True
    # It would still increment the progress
    # XP is only granted if the task changed from ongoing to completed
    if not result.get("updated"):
        raise HTTPException(status_code=404, detail="Task not found")
    return SetTaskProgressResponse(
        message="Task progress updated successfully",
        granted_exp=result.get("granted_exp", 0),  # XP granted if completed
    )
