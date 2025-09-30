from abc import ABC, abstractmethod
from typing import Optional, List, Dict, Any, Union, Type, Literal
from models.db.db import SupabaseTable, SupabaseRPC
from models.helpers import APIResponse, _TableT


class DatabaseService(ABC):
    """
    Abstract base class for database services.
    Defines the interface that both SupabaseService and PgDatabaseService must implement.
    """

    @abstractmethod
    async def insert_data(
        self, table: SupabaseTable, data: Union[Dict[str, Any], List[Dict[str, Any]]]
    ) -> Union[Dict[str, Any], List[Dict[str, Any]]]:
        """Insert data into a specified table."""
        pass

    @abstractmethod
    async def fetch_data(
        self, table: SupabaseTable, return_type: Type[_TableT]
    ) -> APIResponse[_TableT]:
        """Fetch all rows from a specified table."""
        pass

    @abstractmethod
    async def update_data(
        self,
        table: SupabaseTable,
        data: Dict[str, Any],
        condition: Dict[str, Any],
        return_type: Type[_TableT] = dict,
    ) -> APIResponse[_TableT]:
        """Update a row in a specified table."""
        pass

    @abstractmethod
    async def delete_data(
        self,
        table: SupabaseTable,
        condition: Dict[str, Any],
        return_type: Type[_TableT] = dict,
    ) -> APIResponse[_TableT]:
        """Delete a row from a specified table."""
        pass

    @abstractmethod
    async def filter_data(
        self,
        table: SupabaseTable,
        condition: Dict[str, Any],
        columns: Optional[List[str]] = None,
        return_type: Type[_TableT] = dict,
    ) -> APIResponse[_TableT]:
        """Filter rows in a specified table based on a condition."""
        pass

    @abstractmethod
    async def count_data(
        self, table: SupabaseTable, condition: Optional[Dict[str, Any]] = None
    ) -> int:
        """Count rows in a specified table based on a condition."""
        pass

    @abstractmethod
    async def raw_query(self, query: str, response_type: Type = dict) -> APIResponse:
        """Execute a raw SQL query."""
        pass

    @abstractmethod
    async def rpc_query(
        self,
        rpc: SupabaseRPC,
        params: Dict[str, Any],
        return_type: Type[_TableT] = dict,
        mode: Literal["json", "table"] = "json",
    ) -> APIResponse[_TableT]:
        """Call a database RPC function."""
        pass

    @abstractmethod
    async def execute_complex_query(
        self,
        query: str,
        params: Optional[Dict[str, Any]] = None,
        return_type: Type[_TableT] = dict,
        fetch_mode: Literal["all", "one", "none"] = "all",
    ) -> Union[APIResponse[_TableT], Optional[_TableT], int]:
        """Execute a complex SQL query with named parameter binding."""
        pass

    @abstractmethod
    async def execute_complex_query_raw(
        self,
        query: str,
        params: Optional[List[Any]] = None,
        return_type: Type[_TableT] = dict,
        fetch_mode: Literal["all", "one", "none"] = "all",
    ) -> Union[APIResponse[_TableT], Optional[_TableT], int]:
        """Execute a complex SQL query with positional parameter binding."""
        pass
