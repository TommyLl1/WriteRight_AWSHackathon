import asyncpg
import asyncio
import json
from typing import Optional, List, Dict, Any, Union, Type, Literal
from models.db.db import SupabaseTable, SupabaseRPC
from models.helpers import APIResponse, _TableT
from utils.logger import setup_logger
from utils.database.base import DatabaseService
import json

logger = setup_logger(__name__, level="DEBUG")

# Singleton instance for guaranteed pool reuse
_pgdb_singleton: Optional["PgDatabaseService"] = None


# This alone is not enough to ensure singleton behavior across multiple imports,
# but the app startup will ensure that only one instance is created,
# before the app starts handling requests.
def get_pgdb_singleton(dsn: str) -> "PgDatabaseService":
    """Get the module-level singleton instance of PgDatabaseService."""
    logger.debug(f"Getting PgDatabaseService singleton")
    global _pgdb_singleton

    if _pgdb_singleton is None:
        logger.info("Creating new PgDatabaseService singleton instance")
        _pgdb_singleton = PgDatabaseService(dsn)
    else:
        logger.debug("Returning existing PgDatabaseService singleton instance")

    return _pgdb_singleton


class PgDatabaseService(DatabaseService):
    """
    A service class to interact with PostgreSQL for async CRUD operations.
    """

    # Define columns that should be parsed as JSON/arrays based on the schema
    json_columns = {
        "given_material",
        "mc_choices",
        "mc_answers",
        "pairs",  # questions table
        "question_ids",  # game_session table
        "answer",  # game_qa_history table
        "content",  # tasks table
        "settings",  # user_settings table
    }

    def __init__(self, dsn: str):
        self.dsn = dsn
        self.pool: Optional[asyncpg.Pool] = None

    def _prepare_value_for_insert(self, value: Any) -> Any:
        """Convert Python objects to database-compatible format. Dicts to JSON, lists of dicts to list of JSON strings."""
        if isinstance(value, dict):
            return json.dumps(value)
        if isinstance(value, list):
            # If all elements are dicts, convert each to JSON string
            if all(isinstance(v, dict) for v in value):
                return [json.dumps(v) for v in value]
        return value

    def _convert_row_from_db(
        self, row: Dict[str, Any], json_columns: Optional[set] = None
    ) -> Dict[str, Any]:
        """Convert database row values back to Python objects."""
        if json_columns is None:
            json_columns = self.json_columns
        converted = {}
        for key, value in row.items():
            if key in json_columns:
                # If value is a list of strings, parse each as JSON
                if isinstance(value, list) and all(isinstance(v, str) for v in value):
                    try:
                        converted[key] = [json.loads(v) for v in value]
                    except Exception:
                        logger.warning(
                            f"Failed to parse JSON list for column {key}: {value}"
                        )
                        converted[key] = value
                # If value is a string, parse as JSON
                elif isinstance(value, str) and value.strip():
                    try:
                        converted[key] = json.loads(value)
                    except json.JSONDecodeError:
                        logger.warning(
                            f"Failed to parse JSON for column {key}: {value}"
                        )
                        converted[key] = value
                else:
                    converted[key] = value
            elif (
                isinstance(value, str)
                and value.strip().startswith(("[", "{"))
                and value.strip().endswith(("]", "}"))
            ):
                # Fallback: try to parse strings that look like JSON
                try:
                    converted[key] = json.loads(value)
                except json.JSONDecodeError:
                    converted[key] = value
            else:
                converted[key] = value
        return converted

    async def connect(self):
        logger.info(f"Creating PostgreSQL connection pool")
        if self.pool is None:
            try:
                self.pool = await asyncpg.create_pool(
                    dsn=self.dsn,
                    min_size=1,  # Reduced from 2 to minimize connections
                    max_size=6,  # Reduced from 8 to minimize connections
                    max_inactive_connection_lifetime=5 * 60,  # Reduced to 5 minutes
                    command_timeout=30,  # Keep at 30 seconds
                    max_queries=10000,  # Reduced from 50000 to recycle connections more often
                    max_cached_statement_lifetime=60,  # Reduced from 300 to 60 seconds
                    setup=self._setup_connection,
                    server_settings={
                        "application_name": "writeright_backend",
                        "tcp_keepalives_idle": "300",
                        "tcp_keepalives_interval": "30",
                        "tcp_keepalives_count": "3",
                    },
                    # Add connection retry and health check settings
                    # retry_on_failure=True,
                    connection_class=asyncpg.Connection,
                )
                logger.info("PostgreSQL connection pool created successfully")
            except Exception as e:
                logger.error(f"Failed to create connection pool: {e}")
                self.pool = None
                raise RuntimeError(f"Failed to create database connection pool: {e}")
        else:
            logger.debug("Connection pool already exists")

    async def _setup_connection(self, connection):
        """Setup function called for each new connection in the pool."""
        # Set connection-level settings that help with cleanup
        # Join all SET commands into a single SQL statement
        calls = [
            "SET idle_in_transaction_session_timeout = '30s'",
            "SET statement_timeout = '60s'",
            "SET lock_timeout = '30s'",
            "SET tcp_keepalives_idle = '300'",
            "SET tcp_keepalives_interval = '30'",
            "SET tcp_keepalives_count = '3'",
        ]
        await connection.execute("; ".join(calls))

    async def _get_pool(self):
        """
        Get the connection pool. Only performs health check if pool is None or appears unhealthy.
        """
        try:
            # Only check health if pool is None or obviously broken
            if self.pool is None or self.pool.is_closing():
                logger.debug("Pool is None or closing, ensuring healthy pool")
                await self.ensure_healthy_pool()

            if self.pool is None:
                raise RuntimeError("Database connection pool is not initialized.")

            return self.pool

        except Exception as e:
            logger.error(f"Error getting database pool: {e}")
            raise RuntimeError(f"Database connection pool is not available: {e}")

    async def insert_data(
        self,
        table: SupabaseTable,
        data: Union[Dict[str, Any], List[Dict[str, Any]]],
        conn: Optional[asyncpg.Connection] = None,
    ) -> Any:
        return await asyncio.wait_for(
            self._insert_data_impl(table, data, conn), timeout=30.0
        )

    async def _insert_data_impl(
        self,
        table: SupabaseTable,
        data: Union[Dict[str, Any], List[Dict[str, Any]]],
        conn: Optional[asyncpg.Connection] = None,
    ) -> Any:
        if conn is not None:
            # Use provided connection - no acquire/release needed
            return await self._execute_insert_with_conn(table, data, conn)

        # Use pool connection (existing behavior)
        pool = await self._get_pool()
        acquired_conn = await self._acquire_connection_with_timeout(pool)
        try:
            return await self._execute_insert_with_conn(table, data, acquired_conn)
        finally:
            try:
                await pool.release(acquired_conn)
            except Exception as e:
                logger.error(f"Error releasing connection: {e}")
                # Force close the connection if release fails
                try:
                    await acquired_conn.close()
                except:
                    pass

    async def _execute_insert_with_conn(
        self,
        table: SupabaseTable,
        data: Union[Dict[str, Any], List[Dict[str, Any]]],
        conn: asyncpg.Connection,
    ) -> Any:
        """Execute insert operation with a specific connection."""
        if isinstance(data, dict):
            columns = ", ".join(data.keys())
            values = ", ".join(f"${i+1}" for i in range(len(data)))
            # Convert complex types to JSON strings
            prepared_values = [self._prepare_value_for_insert(v) for v in data.values()]

            query = (
                f"INSERT INTO {table.value} ({columns}) VALUES ({values}) RETURNING *"
            )
            result = await conn.fetch(query, *prepared_values)
            return [self._convert_row_from_db(dict(r)) for r in result]
        elif isinstance(data, list):
            if not data:
                return []

            # Get column names from the first row (assuming all rows have same structure)
            first_row = data[0]
            columns = list(first_row.keys())
            columns_str = ", ".join(columns)

            # Build VALUES clause with placeholders for all rows
            values_clauses = []
            all_values = []

            for row_idx, row in enumerate(data):
                # Ensure row has the same structure as first row
                if set(row.keys()) != set(columns):
                    raise ValueError(
                        f"Row {row_idx} has different columns than first row"
                    )

                # Create placeholder string for this row
                row_placeholders = []
                for col in columns:
                    placeholder_idx = len(all_values) + 1
                    row_placeholders.append(f"${placeholder_idx}")
                    all_values.append(self._prepare_value_for_insert(row[col]))

                values_clauses.append(f"({', '.join(row_placeholders)})")

            # Build and execute the bulk insert query
            values_str = ", ".join(values_clauses)
            query = f"INSERT INTO {table.value} ({columns_str}) VALUES {values_str} RETURNING *"

            result = await conn.fetch(query, *all_values)
            return [self._convert_row_from_db(dict(r)) for r in result]

    async def fetch_data(
        self,
        table: SupabaseTable,
        return_type: Type[_TableT],
        conn: Optional[asyncpg.Connection] = None,
    ) -> APIResponse[_TableT]:
        return await asyncio.wait_for(
            self._fetch_data_impl(table, return_type, conn), timeout=30.0
        )

    async def _fetch_data_impl(
        self,
        table: SupabaseTable,
        return_type: Type[_TableT],
        conn: Optional[asyncpg.Connection] = None,
    ) -> APIResponse[_TableT]:
        if conn is not None:
            # Use provided connection
            query = f"SELECT * FROM {table.value}"
            rows = await conn.fetch(query)
            # Convert rows and apply JSON parsing
            converted_rows = [self._convert_row_from_db(dict(r)) for r in rows]
            return APIResponse(
                data=[return_type(**row) for row in converted_rows],
                count=len(converted_rows),
            )

        # Use pool connection (existing behavior)
        pool = await self._get_pool()
        async with pool.acquire() as acquired_conn:
            query = f"SELECT * FROM {table.value}"
            rows = await acquired_conn.fetch(query)
            # Convert rows and apply JSON parsing
            converted_rows = [self._convert_row_from_db(dict(r)) for r in rows]
            return APIResponse(
                data=[return_type(**row) for row in converted_rows],
                count=len(converted_rows),
            )

    async def count_data(
        self,
        table: SupabaseTable,
        condition: Optional[Dict[str, Any]] = None,
        conn: Optional[asyncpg.Connection] = None,
    ) -> int:
        if conn is not None:
            # Use provided connection
            query = f"SELECT COUNT(*) FROM {table.value}"
            values = []
            if condition:
                where_clause = " AND ".join(
                    [f"{k} = ${i+1}" for i, k in enumerate(condition.keys())]
                )
                query += f" WHERE {where_clause}"
                values = list(condition.values())
            row = await conn.fetchrow(query, *values)
            return row[0] if row else 0

        # Use pool connection (existing behavior)
        pool = await self._get_pool()
        async with pool.acquire() as acquired_conn:
            query = f"SELECT COUNT(*) FROM {table.value}"
            values = []
            if condition:
                where_clause = " AND ".join(
                    [f"{k} = ${i+1}" for i, k in enumerate(condition.keys())]
                )
                query += f" WHERE {where_clause}"
                values = list(condition.values())
            row = await acquired_conn.fetchrow(query, *values)
            return row[0] if row else 0

    async def update_data(
        self,
        table: SupabaseTable,
        data: dict,
        condition: Dict[str, Any],
        return_type: Type[_TableT] = dict,
        conn: Optional[asyncpg.Connection] = None,
    ) -> APIResponse[_TableT]:
        if conn is not None:
            # Use provided connection
            set_clause = ", ".join([f"{k} = ${i+1}" for i, k in enumerate(data.keys())])
            cond_offset = len(data)
            where_clause = " AND ".join(
                [f"{k} = ${i+1+cond_offset}" for i, k in enumerate(condition.keys())]
            )
            query = f"UPDATE {table.value} SET {set_clause} WHERE {where_clause} RETURNING *"
            # Convert complex types in update data
            prepared_data = [self._prepare_value_for_insert(v) for v in data.values()]
            values = prepared_data + list(condition.values())
            rows = await conn.fetch(query, *values)
            # Convert rows and apply JSON parsing
            converted_rows = [self._convert_row_from_db(dict(r)) for r in rows]
            return APIResponse(
                data=[return_type(**row) for row in converted_rows],
                count=len(converted_rows),
            )

        # Use pool connection (existing behavior)
        pool = await self._get_pool()
        async with pool.acquire() as acquired_conn:
            set_clause = ", ".join([f"{k} = ${i+1}" for i, k in enumerate(data.keys())])
            cond_offset = len(data)
            where_clause = " AND ".join(
                [f"{k} = ${i+1+cond_offset}" for i, k in enumerate(condition.keys())]
            )
            query = f"UPDATE {table.value} SET {set_clause} WHERE {where_clause} RETURNING *"
            # Convert complex types in update data
            prepared_data = [self._prepare_value_for_insert(v) for v in data.values()]
            values = prepared_data + list(condition.values())
            rows = await acquired_conn.fetch(query, *values)
            # Convert rows and apply JSON parsing
            converted_rows = [self._convert_row_from_db(dict(r)) for r in rows]
            return APIResponse(
                data=[return_type(**row) for row in converted_rows],
                count=len(converted_rows),
            )

    async def delete_data(
        self,
        table: SupabaseTable,
        condition: Dict[str, Any],
        return_type: Type[_TableT] = dict,
        conn: Optional[asyncpg.Connection] = None,
    ) -> APIResponse[_TableT]:
        if conn is not None:
            # Use provided connection
            where_clause = " AND ".join(
                [f"{k} = ${i+1}" for i, k in enumerate(condition.keys())]
            )
            query = f"DELETE FROM {table.value} WHERE {where_clause} RETURNING *"
            values = list(condition.values())
            rows = await conn.fetch(query, *values)
            # Convert rows and apply JSON parsing
            converted_rows = [self._convert_row_from_db(dict(r)) for r in rows]
            return APIResponse(
                data=[return_type(**row) for row in converted_rows],
                count=len(converted_rows),
            )

        # Use pool connection (existing behavior)
        pool = await self._get_pool()
        async with pool.acquire() as acquired_conn:
            where_clause = " AND ".join(
                [f"{k} = ${i+1}" for i, k in enumerate(condition.keys())]
            )
            query = f"DELETE FROM {table.value} WHERE {where_clause} RETURNING *"
            values = list(condition.values())
            rows = await acquired_conn.fetch(query, *values)
            # Convert rows and apply JSON parsing
            converted_rows = [self._convert_row_from_db(dict(r)) for r in rows]
            return APIResponse(
                data=[return_type(**row) for row in converted_rows],
                count=len(converted_rows),
            )

    async def filter_data(
        self,
        table: SupabaseTable,
        condition: Dict[str, Any],
        columns: Optional[List[str]] = None,
        return_type: Type[_TableT] = dict,
        conn: Optional[asyncpg.Connection] = None,
    ) -> APIResponse[_TableT]:
        async def _filter_operation():
            if conn is not None:
                # Use provided connection
                select_cols = ", ".join(columns) if columns else "*"
                where_clause = " AND ".join(
                    [f"{k} = ${i+1}" for i, k in enumerate(condition.keys())]
                )
                query = f"SELECT {select_cols} FROM {table.value} WHERE {where_clause}"
                values = list(condition.values())
                rows = await conn.fetch(query, *values)
                # Convert rows and apply JSON parsing
                converted_rows = [self._convert_row_from_db(dict(r)) for r in rows]
                return APIResponse(
                    data=[return_type(**row) for row in converted_rows],
                    count=len(converted_rows),
                )

            # Use pool connection (existing behavior)
            pool = await self._get_pool()
            async with pool.acquire() as acquired_conn:
                select_cols = ", ".join(columns) if columns else "*"
                where_clause = " AND ".join(
                    [f"{k} = ${i+1}" for i, k in enumerate(condition.keys())]
                )
                query = f"SELECT {select_cols} FROM {table.value} WHERE {where_clause}"
                values = list(condition.values())
                rows = await acquired_conn.fetch(query, *values)
                # Convert rows and apply JSON parsing
                converted_rows = [self._convert_row_from_db(dict(r)) for r in rows]
                return APIResponse(
                    data=[return_type(**row) for row in converted_rows],
                    count=len(converted_rows),
                )

        return await self._execute_with_timeout(_filter_operation)

    async def raw_query(self, query: str, response_type: Type = dict) -> APIResponse:
        pool = await self._get_pool()
        async with pool.acquire() as conn:
            if not query.lower().startswith("select"):
                raise ValueError("Raw query must start with 'SELECT'.")
            rows = await conn.fetch(query)
            # Convert rows and apply JSON parsing
            converted_rows = [self._convert_row_from_db(dict(r)) for r in rows]
            return APIResponse(
                data=[response_type(**row) for row in converted_rows],
                count=len(converted_rows),
            )

    async def rpc_query(
        self,
        rpc: SupabaseRPC,
        params: Dict[str, Any],
        return_type: Type[_TableT] = dict,
        mode: Literal["json", "table"] = "table",
    ) -> APIResponse[_TableT]:
        pool = await self._get_pool()
        async with pool.acquire() as conn:
            # For PostgreSQL, treat RPC as a function call
            param_placeholders = ", ".join([f"${i+1}" for i in range(len(params))])
            query = f"SELECT * FROM {rpc.value}({param_placeholders})"
            values = list(params.values())
            rows = await conn.fetch(query, *values)
            # Use custom json_columns if provided, else default
            if mode == "json":
                out = [json.loads(next(rows[0].values()))] if rows else []
                return APIResponse(
                    data=out,
                    count=len(out),
                )

            converted_rows = [self._convert_row_from_db(dict(r)) for r in rows]
            return APIResponse(
                data=[return_type(**row) for row in converted_rows],
                count=len(converted_rows),
            )

    async def kickstart(self):
        """
        Kickstart the database service by running a dummy query to ensure the connection pool is ready.
        This is useful for ensuring the service is ready before any operations.
        """
        logger.info("Kickstarting PostgreSQL database service")
        pool = await self._get_pool()
        async with pool.acquire() as conn:
            await conn.fetch("SELECT 1")

    async def force_close_active_connections(self):
        """
        Force close any active connections that might be stuck.
        This is a last resort method for cleanup.
        """
        if self.pool is None:
            return

        logger.warning("Force closing active connections")

        # Get all connections from the pool
        connections = []
        try:
            # Try to get all connections
            for _ in range(self.pool.get_size()):
                try:
                    conn = await asyncio.wait_for(self.pool.acquire(), timeout=0.1)
                    connections.append(conn)
                except (asyncio.TimeoutError, Exception):
                    break

            # Close all connections directly
            for conn in connections:
                try:
                    await conn.close()
                except Exception as e:
                    logger.error(f"Error force closing connection: {e}")

            logger.info(f"Force closed {len(connections)} connections")

        except Exception as e:
            logger.error(f"Error during force close: {e}")

    async def prepare_for_shutdown(self, timeout: float = 5.0):
        """
        Prepare the database for shutdown by ensuring all connections are properly released.

        Args:
            timeout: How long to wait for active connections to complete
        """
        if self.pool is None:
            return

        logger.info("Preparing database for shutdown")

        # Check current pool status
        pool_size = self.pool.get_size()
        idle_size = self.pool.get_idle_size()
        active_connections = pool_size - idle_size

        logger.info(
            f"Pool status - Total: {pool_size}, Idle: {idle_size}, Active: {active_connections}"
        )

        if active_connections > 0:
            logger.warning(
                f"Found {active_connections} active connections, waiting {timeout}s for completion"
            )

            # Wait for active connections to complete
            start_time = asyncio.get_event_loop().time()
            while (
                active_connections > 0
                and (asyncio.get_event_loop().time() - start_time) < timeout
            ):
                await asyncio.sleep(0.1)
                if self.pool:
                    new_idle_size = self.pool.get_idle_size()
                    new_pool_size = self.pool.get_size()
                    active_connections = new_pool_size - new_idle_size
                else:
                    break

            if active_connections > 0:
                logger.warning(
                    f"Still {active_connections} active connections after {timeout}s timeout"
                )
            else:
                logger.info("All connections returned to pool")

    async def close(self):
        if self.pool is not None:
            logger.info("Closing PostgreSQL connection pool")
            try:
                # Log pool status before closing
                pool_size = self.pool.get_size()
                idle_size = self.pool.get_idle_size()
                logger.info(
                    f"Pool status before close - Total: {pool_size}, Idle: {idle_size}, Active: {pool_size - idle_size}"
                )

                # Cancel any pending connection acquisitions
                if hasattr(self.pool, "_queue") and self.pool._queue:
                    logger.info("Cancelling pending connection acquisitions")
                    cancelled_count = 0
                    while not self.pool._queue.empty():
                        try:
                            waiter = self.pool._queue.get_nowait()
                            if not waiter.done():
                                waiter.cancel()
                                cancelled_count += 1
                        except:
                            break
                    if cancelled_count > 0:
                        logger.info(
                            f"Cancelled {cancelled_count} pending connection acquisitions"
                        )

                # Try to close active connections gracefully first
                if pool_size > idle_size:
                    logger.warning(
                        f"Found {pool_size - idle_size} active connections during shutdown"
                    )
                    # Give active connections a very short time to complete
                    await asyncio.sleep(0.2)

                    # If still active connections, try to force close them
                    new_pool_size = self.pool.get_size()
                    new_idle_size = self.pool.get_idle_size()
                    if new_pool_size > new_idle_size:
                        logger.warning(
                            "Active connections still present, attempting force close"
                        )
                        await self.force_close_active_connections()

                # First, try to close gracefully with a shorter timeout
                await asyncio.wait_for(self.pool.close(), timeout=3.0)
                logger.info("PostgreSQL connection pool closed gracefully")

            except asyncio.TimeoutError:
                logger.warning("Pool close timed out, forcing termination")
                # Force terminate all connections
                if self.pool:
                    self.pool.terminate()
                logger.info("PostgreSQL connection pool terminated forcefully")

            except Exception as e:
                logger.error(f"Error closing pool: {e}")
                # Force terminate as fallback
                try:
                    if self.pool:
                        self.pool.terminate()
                except Exception as term_e:
                    logger.error(f"Error terminating pool: {term_e}")
            finally:
                self.pool = None

    async def execute_complex_query(
        self,
        query: str,
        params: Optional[Dict[str, Any]] = None,
        return_type: Type[_TableT] = dict,
        fetch_mode: Literal["all", "one", "none"] = "all",
        conn: Optional[asyncpg.Connection] = None,
    ) -> Union[APIResponse[_TableT], Optional[_TableT], int]:
        """
        Execute a complex SQL query with named parameter binding.

        Args:
            query: SQL query with named parameters (e.g., "SELECT * FROM users WHERE id = $user_id")
            params: Dictionary of named parameters to bind to the query
            return_type: Type to cast the returned rows to
            fetch_mode:
                - "all": Return all rows as APIResponse
                - "one": Return single row or None
                - "none": Execute query without returning data (for INSERT/UPDATE/DELETE)

        Returns:
            - APIResponse[_TableT]: For fetch_mode="all"
            - Optional[_TableT]: For fetch_mode="one"
            - int: Number of affected rows for fetch_mode="none"

        Raises:
            ValueError: If query is empty or invalid
            RuntimeError: If database connection fails

        Example:
            # Select with parameters
            result = await db.execute_complex_query(
                "SELECT * FROM questions q WHERE q.target_word_id = $word_id AND q.question_id NOT IN (SELECT fq.question_id FROM flagged_questions fq)",
                params={"word_id": 123},
                return_type=dict,
                fetch_mode="all"
            )

            # Insert with returning
            result = await db.execute_complex_query(
                "INSERT INTO users (name, email) VALUES ($name, $email) RETURNING *",
                params={"name": "John", "email": "john@example.com"},
                fetch_mode="one"
            )

            # Update without returning
            affected_rows = await db.execute_complex_query(
                "UPDATE users SET last_login = NOW() WHERE user_id = $user_id",
                params={"user_id": "123e4567-e89b-12d3-a456-426614174000"},
                fetch_mode="none"
            )
        """
        if not query or not query.strip():
            raise ValueError("Query cannot be empty")

        # Convert named parameters to positional parameters for asyncpg
        if params:
            # Replace named parameters ($param_name) with positional parameters ($1, $2, etc.)
            param_names = list(params.keys())
            param_values = [params[name] for name in param_names]

            # Convert parameters to database-compatible format
            prepared_values = [self._prepare_value_for_insert(v) for v in param_values]

            # Replace named parameters with positional ones
            processed_query = query
            for i, param_name in enumerate(param_names):
                processed_query = processed_query.replace(f"${param_name}", f"${i+1}")
        else:
            processed_query = query
            prepared_values = []

        logger.debug(f"Executing complex query: {processed_query}")
        logger.debug(f"With parameters: {prepared_values}")

        if conn is not None:
            # Use provided connection
            return await self._execute_query_with_conn(
                conn, processed_query, prepared_values, return_type, fetch_mode
            )

        # Use pool connection (existing behavior)
        pool = await self._get_pool()
        async with pool.acquire() as acquired_conn:
            return await self._execute_query_with_conn(
                acquired_conn, processed_query, prepared_values, return_type, fetch_mode
            )

    async def _execute_query_with_conn(
        self,
        conn: asyncpg.Connection,
        query: str,
        params: List[Any],
        return_type: Type[_TableT],
        fetch_mode: Literal["all", "one", "none"],
    ) -> Union[APIResponse[_TableT], Optional[_TableT], int]:
        """Execute a query with a specific connection."""
        try:
            if fetch_mode == "all":
                rows = await conn.fetch(query, *params)
                converted_rows = [self._convert_row_from_db(dict(r)) for r in rows]
                return APIResponse(
                    data=[return_type(**row) for row in converted_rows],
                    count=len(converted_rows),
                )

            elif fetch_mode == "one":
                row = await conn.fetchrow(query, *params)
                if row:
                    converted_row = self._convert_row_from_db(dict(row))
                    return return_type(**converted_row)
                return None

            elif fetch_mode == "none":
                result = await conn.execute(query, *params)
                # Extract number of affected rows from result string like "UPDATE 5"
                if result and result.split():
                    try:
                        return int(result.split()[-1])
                    except (ValueError, IndexError):
                        return 0
                return 0

            else:
                raise ValueError(
                    f"Invalid fetch_mode: {fetch_mode}. Must be 'all', 'one', or 'none'"
                )

        except asyncpg.PostgresError as e:
            logger.error(f"PostgreSQL error executing query: {e}")
            logger.error(f"Query: {query}")
            logger.error(f"Parameters: {params}")
            raise RuntimeError(f"Database query failed: {e}") from e
        except Exception as e:
            logger.error(f"Unexpected error executing query: {e}")
            logger.error(f"Query: {query}")
            logger.error(f"Parameters: {params}")
            raise

    async def execute_complex_query_raw(
        self,
        query: str,
        params: Optional[List[Any]] = None,
        return_type: Type[_TableT] = dict,
        fetch_mode: Literal["all", "one", "none"] = "all",
        conn: Optional[asyncpg.Connection] = None,
    ) -> Union[APIResponse[_TableT], Optional[_TableT], int]:
        """
        Execute a complex SQL query with positional parameter binding.

        This method is for cases where you need direct control over parameter positioning
        or when working with queries that have complex parameter requirements.

        Args:
            query: SQL query with positional parameters (e.g., "SELECT * FROM users WHERE id = $1")
            params: List of parameters to bind to the query in order
            return_type: Type to cast the returned rows to
            fetch_mode: "all", "one", or "none"

        Returns:
            Same as execute_complex_query

        Example:
            result = await db.execute_complex_query_raw(
                "SELECT * FROM questions WHERE target_word_id = $1 AND question_id NOT IN (SELECT question_id FROM flagged_questions)",
                params=[123],
                return_type=dict,
                fetch_mode="all"
            )
        """
        if not query or not query.strip():
            raise ValueError("Query cannot be empty")

        # Prepare parameters
        prepared_values = []
        if params:
            prepared_values = [self._prepare_value_for_insert(v) for v in params]

        logger.debug(f"Executing raw complex query: {query}")
        logger.debug(f"With parameters: {prepared_values}")

        if conn is not None:
            # Use provided connection
            return await self._execute_query_with_conn(
                conn, query, prepared_values, return_type, fetch_mode
            )

        # Use pool connection (existing behavior)
        pool = await self._get_pool()
        async with pool.acquire() as acquired_conn:
            return await self._execute_query_with_conn(
                acquired_conn, query, prepared_values, return_type, fetch_mode
            )

    async def get_connection(self):
        """
        Get a connection from the pool with proper error handling and resource management.

        Use this as an async context manager to ensure connections are properly returned:

        async with db.get_connection() as conn:
            result = await conn.fetch("SELECT * FROM table")
        """
        return DatabaseConnection(self)

    async def _execute_with_timeout(self, operation, timeout: float = 30.0):
        """
        Execute a database operation with timeout protection.

        Args:
            operation: Async function to execute
            timeout: Timeout in seconds

        Returns:
            Result of the operation

        Raises:
            asyncio.TimeoutError: If operation times out
            RuntimeError: If operation fails
        """
        try:
            return await asyncio.wait_for(operation(), timeout=timeout)
        except asyncio.TimeoutError:
            logger.error(f"Database operation timed out after {timeout} seconds")
            # Try to force close and recreate pool if timeout occurs
            try:
                if self.pool:
                    logger.warning("Terminating pool due to timeout")
                    self.pool.terminate()
                    self.pool = None
            except Exception as e:
                logger.error(f"Error terminating pool after timeout: {e}")
            raise RuntimeError(f"Database operation timed out after {timeout} seconds")
        except Exception as e:
            logger.error(f"Database operation failed: {e}")
            raise

    async def health_check(self) -> bool:
        """
        Perform a quick health check on the database connection pool.

        Returns:
            True if the pool is healthy and can execute queries
            False if there are issues
        """
        try:
            if self.pool is None:
                logger.warning("Health check failed: No connection pool")
                return False

            if self.pool.is_closing():
                logger.warning("Health check failed: Pool is closing")
                return False

            # Always do a full connection test
            try:
                async with self.pool.acquire() as conn:
                    await asyncio.wait_for(conn.fetchval("SELECT 1"), timeout=5.0)
                logger.debug("Database health check passed (connection test)")
                return True
            except asyncio.TimeoutError:
                logger.error("Health check timed out")
                return False
            except Exception as e:
                logger.error(f"Health check failed: {e}")
                return False

        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return False

    async def ensure_healthy_pool(self):
        """
        Ensure the connection pool is healthy, recreating it if necessary.
        This method should be called before critical operations.
        """
        try:
            # First, check if we even have a pool
            if self.pool is None:
                logger.info("No connection pool exists, creating new one")
                await self.connect()
                return

            # Only do expensive health check if pool appears to be in bad state
            if self.pool.is_closing():
                logger.warning("Connection pool is closing, recreating")
                self.pool = None
                await self.connect()
                return

            # For existing pools, do a quick lightweight check
            try:
                pool_size = self.pool.get_size()
                if pool_size == 0:
                    logger.warning("Connection pool has no connections, recreating")
                    await self.connect()
                    return
            except Exception as e:
                logger.warning(f"Pool appears corrupted: {e}, recreating")
                self.pool = None
                await self.connect()
                return

        except Exception as e:
            logger.error(f"Failed to ensure healthy pool: {e}")
            raise RuntimeError(f"Database connection pool is not available: {e}")

    async def _acquire_connection_with_timeout(self, pool, timeout: float = 10.0):
        """
        Acquire a connection from the pool with timeout protection.

        Args:
            pool: The connection pool
            timeout: Timeout in seconds for acquiring a connection

        Returns:
            Connection context manager
        """
        try:
            return await asyncio.wait_for(pool.acquire(), timeout=timeout)
        except asyncio.TimeoutError:
            logger.error(f"Failed to acquire connection within {timeout} seconds")
            # Log pool status for debugging only when there's an actual problem
            status = self.get_pool_status()
            logger.error(f"Pool status during timeout: {status}")
            raise RuntimeError(
                f"Failed to acquire database connection within {timeout} seconds"
            )

    def get_pool_status(self) -> dict:
        """
        Get current pool status for debugging purposes.

        Returns:
            Dict with pool statistics or error info
        """
        if self.pool is None:
            return {"status": "no_pool", "error": "Pool not initialized"}

        try:
            pool_size = self.pool.get_size()
            idle_size = self.pool.get_idle_size()
            active_size = pool_size - idle_size

            return {
                "status": "healthy",
                "total_connections": pool_size,
                "idle_connections": idle_size,
                "active_connections": active_size,
                "is_closing": self.pool.is_closing(),
            }
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def log_pool_status_if_needed(self):
        """
        Log pool status only if there are potential issues.
        """
        status = self.get_pool_status()

        if status["status"] == "healthy":
            # Only log warnings for problematic conditions
            if status["idle_connections"] == 0 and status["total_connections"] >= 6:
                logger.warning("Connection pool exhausted - all connections in use")
            elif status["active_connections"] == 0 and status["total_connections"] > 0:
                logger.debug("All connections idle")
        else:
            logger.error(f"Pool status issue: {status}")

    # ...existing code...


class DatabaseConnection:
    """Context manager for database connections that ensures proper cleanup."""

    def __init__(self, db_service: PgDatabaseService):
        self.db_service = db_service
        self.connection = None
        self.pool = None

    async def __aenter__(self):
        self.pool = await self.db_service._get_pool()
        self.connection = await self.pool.acquire()
        return self.connection

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.connection and self.pool:
            try:
                # If there was an exception, rollback any open transaction
                if exc_type:
                    try:
                        await self.connection.execute("ROLLBACK")
                    except:
                        pass  # Ignore rollback errors

                await self.pool.release(self.connection)
            except Exception as e:
                logger.error(f"Error releasing connection: {e}")
                # Force close the connection if release fails
                try:
                    await self.connection.close()
                except:
                    pass
