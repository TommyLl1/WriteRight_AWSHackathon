from fastapi import APIRouter, Depends, HTTPException
from models.helpers import get_time
from utils.database.factory import get_database_service
from utils.database.pgdb import PgDatabaseService
from pydantic import BaseModel

router = APIRouter(prefix="/health", tags=["Health"])


class HealthCheckResponse(BaseModel):
    status: str
    message: str
    at: int


@router.get("", response_model=HealthCheckResponse)
def health_check():
    """
    Health check endpoint to verify the API is running.
    """
    return {"status": "ok", "message": "WriteRight API is running", "at": get_time()}


class DatabaseHealthResponse(BaseModel):
    status: str
    type: str
    pool_size: int | None = None
    idle_connections: int | None = None
    active_connections: int | None = None


@router.get("/database", response_model=DatabaseHealthResponse)
async def check_database_health(db=Depends(get_database_service)):
    try:
        if not isinstance(db, PgDatabaseService):
            return {"status": "healthy", "type": "non-pg"}
        pool = await db._get_pool()
        pool_size = pool.get_size()
        idle_size = pool.get_idle_size()
        healthy = await db.health_check()

        return {
            "status": "healthy" if healthy else "failed",
            "type": "pg",
            "pool_size": pool_size,
            "idle_connections": idle_size,
            "active_connections": pool_size - idle_size,
        }
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Database health check failed: {str(e)}"
        )


def get_git_commit_hash() -> dict[str, str] | tuple[str, bool]:
    """
    Retrieves the current git commit hash of the backend code.
    Returns None if the command fails.
    """
    import subprocess, os
    from utils.logger import logger

    try:
        repo_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        main = (
            subprocess.check_output(
                ["git", "describe", "--always", "--dirty"],
                cwd=repo_dir,
            )
            .strip()
            .decode()
        )
        ai_module = (
            subprocess.check_output(
                ["git", "describe", "--always", "--dirty"],
                cwd=os.path.join(repo_dir, "AI_text_recognition"),
            )
            .strip()
            .decode()
        )
        logger.warning(f"Git commit hash for main: {main}, AI module: {ai_module}")
        return {
            "main": main,
            "ai_module": ai_module,
        }

    except Exception as e:
        return (str(e), False)


class GitCommitHashResponse(BaseModel):
    main: str
    ai_module: str


GIT_COMMIT_HASH = get_git_commit_hash()


@router.get("/git", response_model=GitCommitHashResponse)
def git_commit_hash():
    """
    Returns the current git commit hash of the backend code (cached at server start).
    """
    global GIT_COMMIT_HASH
    if isinstance(GIT_COMMIT_HASH, GitCommitHashResponse):
        return GIT_COMMIT_HASH
    if isinstance(GIT_COMMIT_HASH, tuple):
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve git commit hash: {GIT_COMMIT_HASH[0]}",
        )
    GIT_COMMIT_HASH = GitCommitHashResponse.model_validate(GIT_COMMIT_HASH)
    return GIT_COMMIT_HASH
