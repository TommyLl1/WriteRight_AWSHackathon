"""
Generic Queue Manager for Batching Function Calls

This module provides a queue manager that batches inputs before passing them to functions
in bulk, optimizing performance by reducing the number of function calls. It guarantees
that no item waits longer than a specified maximum time (max_wait).

Compatible with FastAPI and supports both sync and async functions.
"""

if __name__ == "__main__":
    import sys
    import os

    sys.path.append(os.path.dirname(os.path.dirname(__file__)))

import asyncio
import time
from typing import (
    Any,
    Callable,
    Dict,
    List,
    Optional,
    TypeVar,
    Generic,
    Union,
    Awaitable,
)
from dataclasses import dataclass, field
from pydantic import BaseModel
import logging
from concurrent.futures import Future
from utils.logger import setup_logger

logger = setup_logger(__name__, level="DEBUG")

T = TypeVar("T")  # Input type
R = TypeVar("R")  # Result type


@dataclass
class QueueItem(Generic[T, R]):
    """Represents an item in the queue with its associated future for result retrieval."""

    input_data: T
    future: asyncio.Future[R]
    timestamp: float
    args: tuple = ()
    kwargs: dict = field(default_factory=dict)


class BatchProcessor(Generic[T, R]):
    """Generic batch processor that can handle any function with batching."""

    def __init__(
        self,
        batch_function: Callable[[List[T]], Union[List[R], Awaitable[List[R]]]],
        batch_size: int = 10,
        max_wait: float = 2.0,
        queue_name: str = "default",
    ):
        """
        Initialize the batch processor.

        Args:
            batch_function: Function that processes a list of inputs and returns a list of results
            batch_size: Maximum number of items to batch together before processing
            max_wait: Maximum time (in seconds) an item can wait in the queue
            queue_name: Name for this queue (for logging purposes)
        """
        logger.debug(f"Initializing BatchProcessor with queue_name: {queue_name}")
        self.batch_function = batch_function
        self.batch_size = batch_size
        self.max_wait = max_wait
        self.queue_name = queue_name

        self.queue: List[QueueItem[T, R]] = []
        self.lock = asyncio.Lock()
        self.is_processing = False
        self._background_task: Optional[asyncio.Task] = None
        self._shutdown = False
        # Putting the loop as attribute to avoid garbage collected
        self.loop = asyncio.get_running_loop()

        # Start the background monitoring task
        self._start_monitor()

    def _start_monitor(self):
        """Start the background task that monitors for timeouts."""
        if not self._background_task or self._background_task.done():
            try:
                self._background_task = self.loop.create_task(self._monitor_timeouts())
            except RuntimeError:
                # No event loop running, will start when needed
                logger.debug(
                    f"No event loop running for queue {self.queue_name}, monitor will start when needed"
                )

    async def _monitor_timeouts(self):
        """Background task that processes queue based on timeout."""
        # logger.debug(f"shutdown: {self._shutdown}")
        while not self._shutdown:
            try:
                # logger.debug(
                #     f"Queue {self.queue_name}: Monitoring for timeouts"
                # )
                await asyncio.sleep(0.2)  # Check every 100ms
                # logger.debug("wake")
                if self.queue and not self.is_processing:
                    current_time = time.time()
                    oldest_item_time = self.queue[0].timestamp
                    # logger.debug(
                    #     f"Queue {self.queue_name}: Oldest item timestamp: {oldest_item_time}, current time: {current_time}"
                    # )
                    # Check if the oldest item has exceeded max_wait
                    if current_time - oldest_item_time >= self.max_wait:
                        # logger.debug(
                        #     f"Queue {self.queue_name}: Processing due to timeout"
                        # )
                        await self._process_queue()

            except asyncio.CancelledError:
                logger.debug(
                    f"Queue {self.queue_name}: Monitor task cancelled. Active tasks: {asyncio.all_tasks()}"
                )
                logger.debug(
                    f"Event loop running: {asyncio.get_running_loop().is_running()}"
                )
                raise
            except Exception as e:
                logger.error(f"Error in queue monitor for {self.queue_name}: {e}")
                await asyncio.sleep(1)  # Back off on error

    async def add_item(self, item: T, *args, **kwargs) -> R:
        """
        Add an item to the queue and return the result when processing is complete.

        Args:
            item: The input item to be processed

        Returns:
            The processed result for this specific item
        """
        # Create a future for this item's result
        future: asyncio.Future[R] = asyncio.get_event_loop().create_future()
        queue_item = QueueItem(
            input_data=item,
            future=future,
            timestamp=time.time(),
            args=args,
            kwargs=kwargs or {},
        )

        async with self.lock:
            # logger.debug(
            #     f"Queue {self.queue_name}: Adding item to queue: {item}, locked"
            # )
            self.queue.append(queue_item)

            # If we've reached the batch size, process immediately
            if len(self.queue) >= self.batch_size:
                # logger.debug(
                #     f"Queue {self.queue_name}: Processing due to batch size ({len(self.queue)} items)"
                # )
                # Schedule processing without waiting for it
                asyncio.create_task(self._process_queue())

        # Wait for the result
        # logger.debug(
        #     f"Queue {self.queue_name}: Item added to queue: {item}, awaiting result"
        # )
        result = await future
        # logger.debug(
        #     f"Queue {self.queue_name}: Item processed: {item}, result: {result}"
        # )
        return result

    async def _process_queue(self):
        """Process the current queue in a batch."""
        # logger.debug(f"Queue {self.queue_name}: Starting batch processing")
        async with self.lock:
            if not self.queue or self.is_processing:
                # logger.debug(
                #     f"Queue {self.queue_name}: No items to process or already processing"
                # )
                return

            # Mark as processing and take a snapshot of the queue
            self.is_processing = True
            items_to_process = self.queue.copy()
            self.queue.clear()
        try:
            logger.debug(
                f"Queue {self.queue_name}: processing items: {[item.input_data for item in items_to_process]}"
            )

            # Extract input data
            input_data = [item.input_data for item in items_to_process]

            # Collect all args/kwargs from the batch (use the first item's for now)
            if items_to_process:
                args = items_to_process[0].args
                kwargs = items_to_process[0].kwargs or {}
            else:
                args = ()
                kwargs = {}

            # Call the batch function
            # logger.debug(self.batch_function)
            if asyncio.iscoroutinefunction(self.batch_function):
                results = await self.batch_function(input_data, *args, **kwargs)
            else:
                results = self.batch_function(input_data, *args, **kwargs)

            # Ensure results is a list
            if not isinstance(results, list):
                raise ValueError(
                    f"Batch function must return a list, got {type(results)}"
                )

            # Distribute results back to futures
            if len(results) != len(items_to_process):
                # logger.error(results)
                # error_msg = f"Batch function returned {len(results)} results for {len(items_to_process)} inputs"
                # logger.error(f"Queue {self.queue_name}: {error_msg}")

                # # Set exception for all futures
                # for item in items_to_process:
                #     if not item.future.done():
                #         item.future.set_exception(ValueError(error_msg))

                # TODO: Sometimes will get different length of results, now just extract the first n results
                results = results[: len(items_to_process)]

            # Set results for each future
            for item, result in zip(items_to_process, results):
                if not item.future.done():
                    item.future.set_result(result)
            # logger.debug(
            #     f"Queue {self.queue_name}: Batch processed successfully, results: {results}"
            # )

        except Exception as e:
            # logger.error(f"Queue {self.queue_name}: Error processing batch: {e}")
            # Set exception for all futures
            for item in items_to_process:
                if not item.future.done():
                    item.future.set_exception(e)
        finally:
            async with self.lock:
                self.is_processing = False

    async def flush(self) -> List[R]:
        """
        Immediately process all items currently in the queue and return their results.
        Returns a list of results in the same order as the items in the queue.
        """
        async with self.lock:
            if not self.queue:
                return []
            items_to_process = self.queue.copy()
            self.queue.clear()
        try:
            input_data = [item.input_data for item in items_to_process]
            if items_to_process:
                args = items_to_process[0].args
                kwargs = items_to_process[0].kwargs or {}
            else:
                args = ()
                kwargs = {}
            if asyncio.iscoroutinefunction(self.batch_function):
                results = await self.batch_function(input_data, *args, **kwargs)
            else:
                results = self.batch_function(input_data, *args, **kwargs)
            if not isinstance(results, list):
                raise ValueError(
                    f"Batch function must return a list, got {type(results)}"
                )
            for item, result in zip(items_to_process, results):
                if not item.future.done():
                    item.future.set_result(result)
            return results
        except Exception as e:
            for item in items_to_process:
                if not item.future.done():
                    item.future.set_exception(e)
            raise

    async def shutdown(self):
        """Gracefully shutdown the queue manager."""
        self._shutdown = True

        # Cancel background task
        if self._background_task and not self._background_task.done():
            self._background_task.cancel()
            try:
                await self._background_task
            except asyncio.CancelledError:
                pass

        # Process any remaining items
        if self.queue:
            await self._process_queue()

    def get_queue_size(self) -> int:
        """Get the current size of the queue."""
        return len(self.queue)


_global_queue_manager = None


def get_global_queue_manager() -> "QueueManager":
    """
    Get the global instance of QueueManager.
    This is useful for FastAPI dependency injection.
    """
    global _global_queue_manager
    if _global_queue_manager is None:
        _global_queue_manager = QueueManager()
    return _global_queue_manager


class QueueManager:
    """
    Main queue manager that can handle multiple different batch processors.
    Compatible with FastAPI dependency injection.
    """

    def __init__(self):
        # logger.debug("Initializing QueueManager")
        self.processors: Dict[str, BatchProcessor] = {}
        self._shutdown = False

    def create_processor(
        self,
        name: str,
        batch_function: Callable[[List[T]], Union[List[R], Awaitable[List[R]]]],
        batch_size: int = 10,
        max_wait: float = 2.0,
    ) -> BatchProcessor[T, R]:
        """
        Create a new batch processor.

        Args:
            name: Unique name for this processor
            batch_function: Function that processes batches
            batch_size: Maximum batch size
            max_wait: Maximum wait time in seconds

        Returns:
            The created batch processor
        """
        if name in self.processors:
            # logger.error(f"processors: {self.processors.keys()}")
            raise ValueError(f"Processor '{name}' already exists")

        processor = BatchProcessor(
            batch_function=batch_function,
            batch_size=batch_size,
            max_wait=max_wait,
            queue_name=name,
        )

        self.processors[name] = processor
        return processor

    def has_processor(self, name: str) -> bool:
        """
        Check if a processor with the given name exists.

        Args:
            name: Name of the processor

        Returns:
            True if the processor exists, False otherwise
        """
        return name in self.processors

    def get_processor(self, name: str) -> Optional[BatchProcessor]:
        """
        Get an existing processor by name.
        returns None if not found.
        """
        return self.processors.get(name)

    async def add_to_queue(
        self, processor_name: str, item: Any, *args, **kwargs
    ) -> Any:
        """
        Add an item to a specific processor's queue.

        Args:
            processor_name: Name of the processor
            item: Item to process

        Returns:
            The processed result (Return value of processor's batch function)
        """
        # logger.debug(
        #     f"Adding item to queue: {item} for processor '{processor_name}'"
        # )
        processor = self.processors.get(processor_name)
        if not processor:
            raise ValueError(f"Processor '{processor_name}' not found")

        result = await processor.add_item(item, *args, **kwargs)
        # logger.debug("Item added to queue: %s: done", item)
        return result

    async def flush_queue(self, processor_name: str) -> List[Any]:
        """
        Immediately process all items in the specified processor's queue and return their results.
        """
        processor = self.processors.get(processor_name)
        if not processor:
            raise ValueError(f"Processor '{processor_name}' not found")
        return await processor.flush()

    async def shutdown(self):
        """Shutdown all processors."""
        self._shutdown = True

        # Shutdown all processors
        shutdown_tasks = [
            processor.shutdown() for processor in self.processors.values()
        ]

        if shutdown_tasks:
            await asyncio.gather(*shutdown_tasks, return_exceptions=True)

        self.processors.clear()

    def get_stats(self) -> Dict[str, Dict[str, Any]]:
        """Get statistics for all processors."""
        return {
            name: {
                "queue_size": processor.get_queue_size(),
                "is_processing": processor.is_processing,
                "batch_size": processor.batch_size,
                "max_wait": processor.max_wait,
            }
            for name, processor in self.processors.items()
        }


async def shutdown_queue_manager():
    """
    Shutdown the global queue manager.
    Should be called during FastAPI shutdown.
    """
    global _global_queue_manager
    if _global_queue_manager:
        await _global_queue_manager.shutdown()
        _global_queue_manager = None


# Example usage and demonstration
if __name__ == "__main__":

    async def sample_batch_function(items: List[str], extra=None) -> List[str]:
        """Sample batch function that processes a list of strings."""
        print(f"{extra} Processing batch of {len(items)} items: {items}")
        await asyncio.sleep(0.5)  # Simulate processing time
        return [f"processed_{item}" for item in items]

    async def main():
        # Create queue manager
        queue_manager = QueueManager()

        # Create a processor
        processor = queue_manager.create_processor(
            name="string_processor",
            batch_function=sample_batch_function,
            batch_size=3,
            max_wait=10.0,
        )

        # Test adding items
        tasks = []
        for i in range(2):
            task = queue_manager.add_to_queue(
                "string_processor", f"item_{i}", extra=chr(i + 65)
            )
            tasks.append(task)

            # # Add some delay between items
            # if i % 2 == 0:
            #     await asyncio.sleep(0.2)

        results = await asyncio.gather(*tasks)

        # Flush the queue to process remaining items
        # demo only, in real case, use asyncio.gather to wait for all tasks
        # # final_few_results = await queue_manager.flush_queue("string_processor")
        # print(f"{final_few_results=}")
        # Wait for all results
        # results = await asyncio.gather(*tasks)
        print("Results:", results)

        # Print stats
        print("Stats:", queue_manager.get_stats())

        # Shutdown
        await queue_manager.shutdown()

    # Run the example
    logging.basicConfig(level=logging.DEBUG)
    asyncio.run(main())
