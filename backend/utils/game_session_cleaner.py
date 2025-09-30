from fastapi import Depends
from utils.rpc_service import SupabaseRPC
from utils.logger import setup_logger
from utils.database.factory import get_database_service

# Setup logger
logger = setup_logger(__name__, level="WARNING")


async def clean_game_sessions(
    db=get_database_service(),
):
    """
    Function to clean up game sessions that are older than 24 hours.
    This function should be called by the scheduler.
    """
    try:
        result = await db.rpc_query(
            SupabaseRPC.CLEAN_GAME_SESSIONS,
            {},
            mode="table",
        )
        assert result.data, "Game session cleanup returned no data, assume failed"
        abandoned = result.data[0].get("abandoned_count", 0)
        deleted = result.data[0].get("deleted_count", 0)
        logger.info(
            f"Cleaned up game sessions: {abandoned} abandoned, {deleted} deleted."
        )
    except Exception as e:
        logger.error(f"Error cleaning up game sessions: {e}")
