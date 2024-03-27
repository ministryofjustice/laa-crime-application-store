from functools import lru_cache
from pathlib import Path
from typing import List

from pydantic_settings import SettingsConfigDict
from pydantic_settings_yaml import YamlBaseSettings

THIS_DIR = Path(__file__).parent


class PermissionSettings(YamlBaseSettings):
    model_config = SettingsConfigDict(yaml_file=f"{THIS_DIR}/permissions.yaml")

    locked: List[str]
    casework_editable: List[str]
    provider_editable: List[str]
    casework_role: str
    provider_role: str


@lru_cache()
def get_permissions():
    return PermissionSettings()
