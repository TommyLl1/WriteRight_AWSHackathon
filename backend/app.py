## Add path to the root directory
import sys
import os

# # Add /AI_text_recognition to the system path
sys.path.append(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "AI_text_recognition")
)


from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware import Middleware
from routers import auth, game, testing, user, dependencies, file_upload, health
from features.LLM_request_manager import LLMRequestManager
import uvicorn
from dotenv import load_dotenv
from models.helpers import get_time
from contextlib import asynccontextmanager
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from features.game_service import GameService
from features.auth_middleware import AuthMiddleware
from utils.database.factory import get_database_service
from utils.database.pgdb import PgDatabaseService
from utils.logger import setup_logger
from utils.game_session_cleaner import clean_game_sessions
from utils.auth_session_cleaner import clean_auth_sessions
from utils.queue_manager import get_global_queue_manager, shutdown_queue_manager
from AI_text_recognition.main import TextRecognitionService
from AI_text_recognition.utils_m.database.factory import (
    get_database_service as get_text_recognition_database_service,
)
import os

# Setup logger
logger = setup_logger(__name__, level="WARNING")
load_dotenv()  # Load environment variables from .env file


DIRTY_FLAG_ENABLE = False


# This function is called on startup and shutdown of the FastAPI app
@asynccontextmanager
async def lifespan(app: FastAPI):
    # ------ Check and set dirty flag on startup ------
    # Always place the dirty flag in the same dir as app.py
    DIRTY_FLAG = None
    if DIRTY_FLAG_ENABLE:
        DIRTY_FLAG = os.path.join(
            os.path.dirname(os.path.abspath(__file__)), "fastapi_app_dirty.flag"
        )
        if os.path.exists(DIRTY_FLAG):
            logger.warning("Previous shutdown was unclean (dirty bit detected).")
        # Set dirty flag to indicate app is running
        with open(DIRTY_FLAG, "w") as f:
            f.write("dirty")

    # ------ Initialize the database service ------
    db = get_database_service()
    if isinstance(db, PgDatabaseService):
        # Ugly hack to ensure the database service is initialized
        # Thus avoiding possible race conditions to start the db
        await db.kickstart()
    db2 = get_text_recognition_database_service()
    if isinstance(db2, PgDatabaseService):
        await db2.kickstart()

    # ------ Clean up game sessions on startup ------
    # _ = clean_game_sessions()

    db = None  # Clear the reference to the database service
    db2 = None  # Clear the reference to the text recognition database service

    logger.warning(
        "Dont use vscode debugger to stop the app, it will not stop the db properly."
    )

    # ------ Initialize the LLM queue manager ------
    llm_request_manager = LLMRequestManager()
    llm_request_manager._create_processors()
    app.state.llm_request_manager = llm_request_manager

    # ------ Initialize the text recognition service ------
    text_recognition_service = TextRecognitionService(
        llm_batch_size=10,  # TODO: move to config file
        is_simulate_wrong_words=False,  # TODO: move to config file
        monitoring_check_time=0.2,
    )
    await text_recognition_service.init()
    app.state.text_recognition_service = text_recognition_service

    # ------ Start the scheduler ------
    scheduler.start()

    # ------ This is where the app runs --------
    yield

    # ------ Cleanup on shutdown ------
    logger.info("Starting application shutdown...")

    # First, shutdown background services that might be using the database
    logger.info("Shutting down queue manager...")
    await shutdown_queue_manager()

    logger.info("Shutting down text recognition service...")
    await text_recognition_service.shutdown()

    logger.info("Shutting down scheduler...")
    scheduler.shutdown()

    # Now prepare databases for shutdown
    logger.info("Preparing databases for shutdown...")
    db = get_database_service()
    if isinstance(db, PgDatabaseService):
        await db.prepare_for_shutdown(timeout=3.0)
        await db.close()

    db2 = get_text_recognition_database_service()
    if isinstance(db2, PgDatabaseService):
        await db2.prepare_for_shutdown(timeout=3.0)
        await db2.close()

    logger.info("Application shutdown complete.")

    # ------ Clear the dirty flag on shutdown ------
    if DIRTY_FLAG_ENABLE and DIRTY_FLAG:
        if os.path.exists(DIRTY_FLAG):
            os.remove(DIRTY_FLAG)


app = FastAPI(
    title="WriteRight API",
    description="API for WriteRight application",
    version="0.0.1",
    lifespan=lifespan,  # Add lifespan context manager here
)

# Initialize APScheduler
scheduler = AsyncIOScheduler()

# Add a cron job to run every day at 0, 6, 12, and 18 hours
scheduler.add_job(
    clean_game_sessions,
    CronTrigger(hour="*/6"),
    id="clean_game_sessions",
    replace_existing=True,
)

# Add a cron job to clean auth sessions every 12 hours
scheduler.add_job(
    clean_auth_sessions,
    CronTrigger(hour="*/12"),
    id="clean_auth_sessions",
    replace_existing=True,
)


async def refresh_connections(
    db=get_database_service(),
):
    """
    Refresh all connections in the PostgreSQL pool by running a dummy query.
    This prevents connections from timing out due to inactivity.
    """
    if not isinstance(db, PgDatabaseService):
        return  # Only refresh connections for PgDatabaseService
    try:
        await db.kickstart()
    except Exception as e:
        logger.error(f"Error refreshig connections{e}")


scheduler.add_job(
    refresh_connections,
    CronTrigger(minute="*/10"),
    id="refresh_connections",
    replace_existing=True,
)


# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins; restrict this in production
    allow_credentials=True,
    allow_methods=["*"],  # Allows all HTTP methods
    allow_headers=["*"],  # Allows all headers
    expose_headers=[
        "Authorization"
    ],  # TODO: Now is exposing Authorization header, think of a better way to do this
)

# app.add_middleware(AuthMiddleware)  # type: ignore


# Include the routers
app.include_router(auth.router)
app.include_router(game.router)
app.include_router(user.router)
app.include_router(testing.router)
app.include_router(file_upload.router)
app.include_router(health.router)


# Root endpoint
@app.get("/")
def read_root():
    return {"message": "Welcome to the WriteRight API"}


# Entry point for running the app
if __name__ == "__main__":

    uvicorn.run(
        "app:app",  # The app instance to run
        host="0.0.0.0",  # Listens on all network interfaces
        port=8000,  # Application port
        reload=True,  # Enables auto-reload for development
        # lifespan=lifespan,  # Remove this line
    )
