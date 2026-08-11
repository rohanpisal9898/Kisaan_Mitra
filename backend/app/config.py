from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    gemini_api_key: str = ""
    mongodb_uri: str
    model_path: str = "./data"

    # Google Earth Engine
    gee_project_id: str = ""
    gee_service_account: str = ""
    gee_private_key: str = ""

    # External API base URLs
    nasa_power_base_url: str = "https://power.larc.nasa.gov/api/temporal/daily/point"
    open_meteo_base_url: str = "https://api.open-meteo.com/v1/forecast"

    # Feature flags — Real CatBoost models & APIs enabled by default
    use_mock_data: bool = False

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings():
    return Settings()
