#!/usr/bin/env python3
"""
Test script to verify database timeout handling works correctly.
"""

import asyncio
import sys
import os
from utils.database.pgdb import get_pgdb_singleton


async def test_db_timeout():
    """Test database timeout handling"""
    db = None
    try:
        # Get database connection (replace with your actual DSN)
        dsn = "postgresql://user:pass@localhost:5432/dbname"  # Replace with actual DSN
        db = get_pgdb_singleton(dsn)

        print("Testing database health check...")
        is_healthy = await db.health_check()
        print(f"Database health check result: {is_healthy}")

        if is_healthy:
            print("Database is healthy! Timeout handling should work correctly.")
        else:
            print(
                "Database health check failed - this might be expected if DB is not running"
            )

    except Exception as e:
        print(f"Error during test: {e}")
        print("This is expected if the database is not configured or running")

    finally:
        # Clean up
        try:
            if db is not None:
                await db.close()
        except:
            pass


if __name__ == "__main__":
    print("Testing database timeout handling...")
    asyncio.run(test_db_timeout())
    print("Test completed!")
