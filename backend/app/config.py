from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    gemini_api_key: str = ""
    mongodb_uri: str
    model_path: str = "./data"

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings():
    return Settings()
