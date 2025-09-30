import os
from enum import Enum
from typing import Optional
from utils.database.base import DatabaseService
from utils.database.supabase_service import SupabaseService
from utils.database.pgdb import get_pgdb_singleton
from utils.logger import setup_logger

logger = setup_logger(__name__, level="INFO")


class DatabaseType(str, Enum):
    SUPABASE = "supabase"
    POSTGRESQL = "postgresql"


class DatabaseFactory:
    """
    Factory class to create database service instances based on configuration.
    """

    _db_type: Optional[DatabaseType] = None

    @staticmethod
    def get_db_type() -> DatabaseType:
        """
        Get the database type, fetching from environment only once.
        """
        if DatabaseFactory._db_type is None:
            db_type_str = os.getenv("DATABASE_TYPE", "supabase").lower()
            try:
                DatabaseFactory._db_type = DatabaseType(db_type_str)
            except ValueError:
                logger.warning(
                    f"Unknown database type '{db_type_str}', defaulting to Supabase"
                )
                DatabaseFactory._db_type = DatabaseType.SUPABASE
        return DatabaseFactory._db_type

    @staticmethod
    def create_database_service(
        db_type: Optional[DatabaseType] = None, **kwargs
    ) -> DatabaseService:
        """
        Create a database service instance based on the specified type.

        :param db_type: The type of database service to create
        :param kwargs: Additional arguments for the database service
        :return: A database service instance
        """
        db_type = db_type or DatabaseFactory.get_db_type()

        logger.debug(f"Creating database service of type: {db_type}")
        if db_type == DatabaseType.SUPABASE:
            return SupabaseService(
                url=kwargs.get("url", os.getenv("SUPABASE_URL")),
                key=kwargs.get("key", os.getenv("SUPABASE_SERVICE_KEY")),
            )
        elif db_type == DatabaseType.POSTGRESQL:
            dsn = kwargs.get("dsn")
            if not dsn:
                # Build DSN from environment variables
                host = os.getenv("POSTGRES_HOST", "localhost")
                port = os.getenv("POSTGRES_PORT", "5432")
                database = os.getenv("POSTGRES_DB", "writeright")
                user = os.getenv("POSTGRES_USER", "postgres")
                password = os.getenv("POSTGRES_PASSWORD", "")
                dsn = f"postgresql://{user}:{password}@{host}:{port}/{database}"
            return get_pgdb_singleton(dsn=dsn)
        else:
            raise ValueError(f"Unsupported database type: {db_type}")


# Convenience function for getting the default database service
def get_database_service() -> DatabaseService:
    """Get the default database service based on environment configuration."""
    return DatabaseFactory.create_database_service()
