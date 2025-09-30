import contextvars
import json
import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

import colorama
from colorama import Back, Fore, Style

from utils.config import config

# Initialize colorama for Windows support
colorama.init()

# Context variable to track request ID
request_id_ctx = contextvars.ContextVar("request_id", default=None)


class RequestContextFilter(logging.Filter):
    """Add request ID to log records"""

    def filter(self, record):
        record.request_id = request_id_ctx.get(None)
        return True


class ColoredFormatter(logging.Formatter):
    """Custom formatter with colors and enhanced info"""

    # Color schemes for different logging levels
    COLORS = {
        "DEBUG": Fore.CYAN,
        "INFO": Fore.GREEN,
        "WARNING": Fore.YELLOW,
        "ERROR": Fore.RED,
        "CRITICAL": Fore.RED + Back.WHITE,
    }

    def __init__(self, include_path: bool = True):
        """
        Initialize the formatter with custom format
        Args:
            include_path (bool): Whether to include file path in logs
        """
        self.include_path = include_path
        super().__init__()

    def format(self, record: logging.LogRecord) -> str:
        """
        Format the log record with colors and additional information

        Args:
            record: The log record to format

        Returns:
            str: The formatted log message
        """
        # Save original values to restore them later
        orig_msg = record.msg
        orig_levelname = record.levelname

        # Add colors
        color = self.COLORS.get(record.levelname, Fore.WHITE)
        record.levelname = f"{color}{record.levelname}{Style.RESET_ALL}"

        # Add timestamp
        timestamp = datetime.fromtimestamp(record.created).strftime(
            "%Y-%m-%d %H:%M:%S.%f"
        )[:-3]

        # Get file path info
        if self.include_path:
            file_path = Path(record.pathname).relative_to(Path.cwd())
            location = f"{file_path}:{record.lineno}"
        else:
            location = f"{record.filename}:{record.lineno}"
        # Format the message
        record.msg = f"{record.levelname}:\t{Fore.BLUE}{timestamp}{Style.RESET_ALL} {location} - {orig_msg}"

        # Get formatted message
        result = super().format(record)

        # Restore original values
        record.msg = orig_msg
        record.levelname = orig_levelname

        return result


def _get_log_level(level: Optional[str] = None) -> int:
    """
    Get the logging level from the configuration or default to DEBUG

    Args:
        level (Optional[str]): Logging level as a string (e.g., "DEBUG", "INFO")

    Returns:
        int: Corresponding logging level constant
    """
    if level is None:
        level = str(config.get("Logger.DefaultLevel", "DEBUG"))

    if not isinstance(level, str):
        raise ValueError(
            f"Invalid logging level type: {type(level)}. Expected a string."
        )

    level = level.upper()
    if level not in logging._nameToLevel:
        raise ValueError(
            f"Invalid logging level: {level}. Must be one of {list(logging._nameToLevel.keys())}."
        )

    return logging._nameToLevel[level]


def setup_logger(
    name: Optional[str] = None,
    level: Optional[int | str] = None,
    include_path: bool = True,
    log_to_file: bool = False,
    log_file: Optional[str | Path] = None,
) -> logging.Logger:
    """
    Set up a colored logger with optional file logging

    Args:
        name (Optional[str]): Logger name (defaults to root logger)
        level (int): Logging level
        include_path (bool): Whether to include full file paths in logs
        log_to_file (bool): Whether to also log to a file
        log_file (Optional[str | Path]): Path to log file (defaults to logs/app.log)

    Returns:
        logging.Logger: Configured logger instance
    """
    if level is None:
        level = _get_log_level()
    elif isinstance(level, str):
        level = _get_log_level(level)
    elif not isinstance(level, int):
        raise ValueError(
            f"Invalid logging level type: {type(level)}. Expected int or str."
        )
    # Create logger
    logger = logging.getLogger(name)
    logger.setLevel(level)
    logger.addFilter(RequestContextFilter())

    # Prevent propagation to parent loggers
    logger.propagate = False

    # Remove existing handlers
    logger.handlers.clear()

    # Console handler with colored output
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(ColoredFormatter(include_path))
    logger.addHandler(console_handler)

    # File handler if requested
    if log_to_file:
        # Create logs directory if it doesn't exist
        log_dir = Path("logs")
        log_dir.mkdir(exist_ok=True)

        # Default log file path
        if log_file is None:
            log_file = Path.joinpath(log_dir, "app.log")
        else:
            log_file = Path(log_file)

        # Create file handler
        file_handler = logging.FileHandler(log_file, mode="a", encoding="utf-8")
        file_handler.setFormatter(
            logging.Formatter(
                "%(asctime)s.%(msecs)03d %(levelname)s %(pathname)s:%(lineno)d - %(message)s",
                "%Y-%m-%d %H:%M:%S",
            )
        )
        logger.addHandler(file_handler)

    return logger


# Debug levels map for convenience
LOG_LEVELS = {
    "DEBUG": logging.DEBUG,
    "INFO": logging.INFO,
    "WARNING": logging.WARNING,
    "ERROR": logging.ERROR,
    "CRITICAL": logging.CRITICAL,
}

logger = setup_logger(__name__, _get_log_level())

# logger.debug(f"config: \n {json.dumps(config, indent=2)}")
