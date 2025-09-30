import yaml
import os
from pathlib import Path
from typing import Any


class Config:
    """Configuration class to load settings from a YAML file."""

    def __init__(self, config_file: str = "config.yaml"):
        self.config_file = config_file
        self.config = self._load_config()

    def _load_config(self) -> dict:
        """Load configuration from a YAML file."""
        config_path = Path(self.config_file)
        if not config_path.is_file():
            raise FileNotFoundError(f"Configuration file not found: {self.config_file}")

        with open(config_path, "r") as file:
            try:
                config = yaml.safe_load(file)
                return config
            except yaml.YAMLError as e:
                raise ValueError(f"Error parsing the YAML configuration file: {e}")

    def get(self, key: str, default=None) -> Any:
        """Get a configuration value using dot notation, with an optional default."""
        keys = key.split(".")
        value = self.config
        try:
            for k in keys:
                value = value[k]
        except (KeyError, TypeError):
            return default
        return value


# Create a global configuration instance
config = Config()
