from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    gemini_api_key: str = ""
    mongodb_uri: str = "mongodb+srv://rohanpisal9898_db_user:4F68h7NXtB7y6v37@cluster0.kywehlh.mongodb.net/?retryWrites=true&w=majority"
    model_path: str = "./data"

    # Google Earth Engine
    gee_project_id: str = ""
    gee_service_account: str = ""
    gee_private_key: str = ""
    gee_credentials_json: str = ""

    # External API base URLs
    nasa_power_base_url: str = "https://power.larc.nasa.gov/api/temporal/daily/point"
    open_meteo_base_url: str = "https://api.open-meteo.com/v1/forecast"

    # Feature flags — Real CatBoost models & APIs enabled by default
    use_mock_data: bool = False

    # JWT Authentication
    jwt_secret_key: str = "kisaan_mitra_super_secret_jwt_key_2026_yield_optimization"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440  # 24 hours access token
    refresh_token_expire_days: int = 365    # 1 year refresh token

    # Performance & Timeouts
    gemini_connect_timeout: float = 3.0
    gemini_read_timeout: float = 5.0
    gemini_total_timeout: float = 6.0
    dashboard_cache_ttl_seconds: int = 180  # 3 minutes in-memory TTL

    model_config = SettingsConfigDict(
        env_file=(".env", "backend/.env", "../.env"),
        case_sensitive=False,
        extra="ignore"
    )


@lru_cache()
def get_settings():
    return Settings()
