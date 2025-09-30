from supabase import acreate_client, AsyncClient
import os
from asyncio import run
from typing import Optional, List, Dict, Any, Type, Union, TYPE_CHECKING, Literal
from models.db.db import SupabaseTable, SupabaseRPC
from models.helpers import APIResponse, _TableT
from utils.logger import setup_logger
from utils.database.base import DatabaseService
import asyncio

logger = setup_logger(__name__, level="INFO")


class SupabaseService(DatabaseService):
    """
    [DEPRECATED] A service class to interact with Supabase for async CRUD operations.
    """

    def __init__(
        self,
        url: Optional[str] = os.getenv("SUPABASE_URL"),
        key: Optional[str] = os.getenv("SUPABASE_SERVICE_KEY"),
    ):
        import warnings

        logger.warning(
            "SupabaseService is DEPRECATED and should not be used. Use PgDatabaseService instead."
        )
        warnings.warn(
            "SupabaseService is DEPRECATED and should not be used. Use PgDatabaseService instead.",
            DeprecationWarning,
            stacklevel=2,
        )

        """
        Initialize the Supabase async client.

        :param url: Supabase project URL
        :param key: Supabase API key
        """
        assert url, "Supabase URL must be provided."
        assert key, "Supabase API key must be provided."

        self.client: Optional[AsyncClient] = AsyncClient(
            supabase_key=key, supabase_url=url
        )

    async def count_data(self, table: SupabaseTable, condition: Dict[str, Any] | None = None) -> int:
        await asyncio.sleep(0.1)  # Simulate async operation
        return 0


    async def execute_complex_query(
        self,
        query: str,
        params: Optional[Dict[str, Any]] = None,
        return_type: Type[_TableT] = dict,
        fetch_mode: Literal["all", "one", "none"] = "all",
    ) -> Union[APIResponse[_TableT], Optional[_TableT], int]:
        raise NotImplementedError(
            "SupabaseService does not support complex queries. Use PgDatabaseService instead."
        )

    async def execute_complex_query_raw(
        self,
        query: str,
        params: Optional[List[Any]] = None,
        return_type: Type[_TableT] = dict,
        fetch_mode: Literal["all", "one", "none"] = "all",
    ) -> Union[APIResponse[_TableT], Optional[_TableT], int]:
        raise NotImplementedError(
            "SupabaseService does not support raw complex queries. Use PgDatabaseService instead."
        )

    def _get_client(self) -> AsyncClient:
        """
        Get the Supabase async client.

        :return: Supabase async client
        """
        if not self.client:
            raise RuntimeError("Supabase client is not initialized.")
        return self.client

    async def insert_data(
        self, table: SupabaseTable, data: Union[Dict[str, Any], List[Dict[str, Any]]]
    ) -> Union[Dict[str, Any], List[Dict[str, Any]]]:
        """
        Asynchronously insert data into a specified table.

        :param table: Table name
        :param data: Data to insert (validated by a Pydantic model)
        :return: Response from Supabase as an APIResponse
        """
        assert self.client, "Supabase client is not initialized."
        logger.debug(f"Inserting data into table {table.value}: {data}")
        try:
            # Insert data with `.select("*")` to return the inserted rows
            response = await self.client.table(table.value).insert(data).execute()
            return response.data
        except Exception as e:
            logger.error(f"Failed to insert data into table {table.value}: {e}")
            raise RuntimeError(f"Supabase insert error: {e}")

    async def fetch_data(
        self, table: SupabaseTable, return_type: type[_TableT]
    ) -> APIResponse[_TableT]:
        """
        Asynchronously fetch all rows from a specified table.

        :param table: The table to fetch data from.
        :param return_type: The Pydantic model class representing the row structure.
        :return: An APIResponse containing the fetched rows.
        """
        assert self.client, "Supabase client is not initialized."

        try:
            # Fetch data from the table
            response = await self.client.table(table.value).select("*").execute()

            # Map the raw data to the specified Pydantic model
            rows = [return_type(**row) for row in response.data]  # Validate each row
            return APIResponse(data=rows, count=response.count)

        except Exception as e:
            logger.error(f"Failed to fetch data from table {table.value}: {e}")
            return APIResponse(data=[], count=None)

    async def update_data(
        self,
        table: SupabaseTable,
        data: dict[str, Any],
        condition: Dict[str, Any],
        return_type: type[_TableT] = dict[str, Any],
    ) -> APIResponse[_TableT]:
        """
        Asynchronously update a row in a specified table.

        :param table: Table name
        :param data: Data to update
        :param condition: Condition to match for the update
        :return: Response from Supabase
        """
        assert self.client, "Supabase client is not initialized."

        builder = self.client.table(table.value).update(data)
        if isinstance(condition, dict):
            for key, value in condition.items():
                builder = builder.eq(column=key, value=value)

        try:
            # Execute the update operation
            response = await builder.execute()
            logger.debug(f"Update response: {response}")
        except Exception as e:
            logger.error(f"Failed to update data in table {table.value}: {e}")
            raise RuntimeError(f"Supabase update error: {e}")

        # If a return type is specified, map the response data to the Pydantic model
        return APIResponse(
            data=[return_type(**row) for row in response.data], count=response.count
        )

    async def delete_data(
        self,
        table: SupabaseTable,
        condition: Dict[str, Any],
        return_type: type[_TableT] = dict[str, Any],
    ) -> APIResponse[_TableT]:
        """
        Asynchronously delete a row from a specified table.

        :param table: Table name
        :param condition: Condition to match for the deletion
        :param return_type: The Pydantic model class representing the row structure.
        :return: Response from Supabase

        """
        assert self.client, "Supabase client is not initialized."

        builder = self.client.table(table.value).delete()
        if isinstance(condition, dict):
            for key, value in condition.items():
                builder = builder.eq(column=key, value=value)

        try:
            # Execute the delete operation
            response = await builder.execute()
            logger.debug(f"Delete response: {response}")
        except Exception as e:
            logger.error(f"Failed to delete data from table {table.value}: {e}")
            raise RuntimeError(f"Supabase delete error: {e}")

        # If a return type is specified, map the response data to the Pydantic model
        return APIResponse(
            data=[return_type(**row) for row in response.data], count=response.count
        )

    async def filter_data(
        self,
        table: SupabaseTable,
        condition: Dict[str, Any],
        columns: Optional[List[str]] = None,
        return_type: type[_TableT] = dict[str, Any],
    ) -> APIResponse[_TableT]:
        """
        Asynchronously filter rows in a specified table based on a condition.

        :param table: Table name
        :param condition: Dictionary with a single key-value pair representing the filter condition.
        :param columns: Optional list of columns to select. Defaults to all columns ("*").
        :return: Filtered data from the database.
        :raises ValueError: If the condition is empty or invalid.
        """
        # Validate the condition
        # if not condition or len(condition) != 1:
        #     raise ValueError(
        #         "The 'condition' parameter must contain exactly one key-value pair."
        #     )
        assert self.client, "Supabase client is not initialized."

        # Default to selecting all columns if none are provided
        if not columns:
            columns = ["*"]

        try:
            # Execute the query asynchronously
            builder = self.client.table(table.value).select(",".join(columns))
            if isinstance(condition, dict):
                for key, value in condition.items():
                    builder = builder.eq(column=key, value=value)
            response = await builder.execute()
            logger.debug(f"Filter response: {response}")
            # Map the response data to the specified Pydantic model
            rows = [return_type(**row) for row in response.data]  # Validate each row
            return APIResponse(data=rows, count=response.count)

        except Exception as e:
            # Handle and log exceptions appropriately
            raise RuntimeError(f"Failed to filter data from table '{table.value}': {e}")

    async def raw_query(
        self, query: str, response_type: type = dict[str, Any]
    ) -> APIResponse:
        """
        Asynchronously execute a raw SQL query.
        WARNING: THIS METHOD RUNS A RAW SQL QUERY, NO SANITIZATION IS DONE.
        Use with caution, especially with user input.

        :param query: SQL query string
        :return: Response from Supabase
        """
        assert self.client, "Supabase client is not initialized."

        if not isinstance(query, str):
            raise TypeError("Query must be a string.")
        if not query.strip():
            raise ValueError("Query cannot be empty.")
        if not query.lower().startswith("select"):
            raise ValueError("Raw query must start with 'SELECT'.")
        if query.endswith(";"):
            raise ValueError(
                "Raw query should not end with a semicolon *for this query*."
            )
        try:
            response = await self.client.rpc(
                SupabaseRPC.RUN_RAW_SELECT.value, {"query": query}
            ).execute()
            logger.debug(f"Raw query response: {response}")
        except Exception as e:
            logger.error(f"Failed to execute raw query: {e}")
            raise RuntimeError(f"Supabase raw query error: {e}")

        # Map the response data to the specified Pydantic model
        rows = [response_type(**row) for row in response.data] if response.data else []
        return APIResponse(data=rows, count=response.count)

    async def rpc_query(
        self,
        rpc: SupabaseRPC,
        params: Dict[str, Any],
        return_type: type[_TableT] = dict[str, Any],
        mode: str = "json",  # Unused, satisifies the interface
    ) -> APIResponse[_TableT]:
        assert self.client, "Supabase client is not initialized."

        """
        Asynchronously call a Supabase RPC function.

        :param function_name: Name of the RPC function
        :param params: Parameters to pass to the function
        :return: Response from Supabase
        """
        try:
            response = await self.client.rpc(rpc.value, params).execute()
            logger.debug(f"RPC response: {response}")
        except Exception as e:
            logger.error(f"Failed to call RPC '{rpc.value}': {e}")
            raise RuntimeError(f"Supabase RPC error: {e}")

        # Map the response data to the specified Pydantic model
        rows = [return_type(**row) for row in response.data] if response.data else []
        return APIResponse(data=rows, count=response.count)
