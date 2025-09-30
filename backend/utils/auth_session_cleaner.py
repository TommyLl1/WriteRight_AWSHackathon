from utils.rpc_service import SupabaseRPC
from utils.logger import setup_logger
from utils.database.factory import get_database_service

# Setup logger
logger = setup_logger(__name__, level="WARNING")


async def clean_auth_sessions(
    db=get_database_service(),
):
    """
    Function to clean up authentication sessions that are expired or inactive.
    This function should be called by the scheduler.
    """
    try:
        result = await db.rpc_query(
            SupabaseRPC.CLEAN_AUTH_SESSIONS,
            {},
            mode="table",
        )
        assert result.data, "Auth session cleanup returned no data, assume failed"
        expired = result.data[0].get("expired_count", 0)
        deleted = result.data[0].get("deleted_count", 0)
        logger.info(f"Cleaned up auth sessions: {expired} expired, {deleted} deleted.")
    except Exception as e:
        logger.error(f"Error cleaning up auth sessions: {e}")
