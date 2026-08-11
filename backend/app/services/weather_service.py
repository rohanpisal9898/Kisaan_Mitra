"""
Weather service for the dashboard.

Wraps Open-Meteo integration with caching and error handling.
"""

from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.integrations.open_meteo import fetch_weather
from app.config import get_settings

settings = get_settings()

# In-memory cache: key = "lat,lon" → (data, timestamp)
_weather_cache: Dict[str, tuple] = {}
CACHE_DURATION_MINUTES = 30


class WeatherService:
    """Provides current weather + forecast for a farmer's location."""

    async def get_weather(
        self,
        db: AsyncIOMotorDatabase,
        latitude: float,
        longitude: float,
    ) -> Dict[str, Any]:
        """
        Get weather for coordinates.
        Uses short-lived cache (30 min).
        Returns structured weather dict or error response.
        """
        cache_key = f"{round(latitude, 2)},{round(longitude, 2)}"

        # Check cache
        if cache_key in _weather_cache:
            cached_data, cached_time = _weather_cache[cache_key]
            if datetime.utcnow() - cached_time < timedelta(minutes=CACHE_DURATION_MINUTES):
                return cached_data

        # Mock mode
        if settings.use_mock_data:
            return self._mock_weather(latitude, longitude)

        # Real API call
        weather_data = await fetch_weather(latitude, longitude)

        if weather_data is None:
            return {
                "location": {"latitude": latitude, "longitude": longitude},
                "current": {
                    "temperature": 0,
                    "feels_like": 0,
                    "condition": "Unknown",
                    "humidity": None,
                },
                "rain": {
                    "amount_mm": 0,
                    "date": None,
                    "description": "Weather data unavailable",
                },
                "wind": {"speed_kmh": 0, "description": ""},
                "forecast": [],
                "available": False,
                "error": "Weather data unavailable. Try again later.",
            }

        # Cache the result
        _weather_cache[cache_key] = (weather_data, datetime.utcnow())
        return weather_data

    def _mock_weather(self, latitude: float, longitude: float) -> Dict[str, Any]:
        """Return realistic mock weather for development."""
        today = datetime.now().strftime("%Y-%m-%d")
        tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")

        return {
            "location": {"latitude": latitude, "longitude": longitude},
            "current": {
                "temperature": 26.0,
                "feels_like": 28.0,
                "condition": "Partly Cloudy",
                "humidity": 72.0,
            },
            "rain": {
                "amount_mm": 18.0,
                "date": tomorrow,
                "description": "18.0 mm rain expected",
            },
            "wind": {
                "speed_kmh": 5.0,
                "description": "5 km/h",
            },
            "forecast": [
                {"date": today, "temp_max": 28.0, "temp_min": 22.0, "precipitation_mm": 0.0, "condition": "Partly Cloudy", "eto_mm": 5.2},
                {"date": tomorrow, "temp_max": 27.0, "temp_min": 21.0, "precipitation_mm": 18.0, "condition": "Rain", "eto_mm": 3.8},
                {"date": (datetime.now() + timedelta(days=2)).strftime("%Y-%m-%d"), "temp_max": 26.0, "temp_min": 21.0, "precipitation_mm": 5.0, "condition": "Light Rain", "eto_mm": 4.0},
                {"date": (datetime.now() + timedelta(days=3)).strftime("%Y-%m-%d"), "temp_max": 29.0, "temp_min": 22.0, "precipitation_mm": 0.0, "condition": "Sunny", "eto_mm": 5.5},
                {"date": (datetime.now() + timedelta(days=4)).strftime("%Y-%m-%d"), "temp_max": 30.0, "temp_min": 23.0, "precipitation_mm": 0.0, "condition": "Sunny", "eto_mm": 5.8},
                {"date": (datetime.now() + timedelta(days=5)).strftime("%Y-%m-%d"), "temp_max": 28.0, "temp_min": 22.0, "precipitation_mm": 8.0, "condition": "Rain Showers", "eto_mm": 4.2},
                {"date": (datetime.now() + timedelta(days=6)).strftime("%Y-%m-%d"), "temp_max": 27.0, "temp_min": 21.0, "precipitation_mm": 2.0, "condition": "Partly Cloudy", "eto_mm": 4.5},
            ],
            "available": True,
        }


# Singleton
weather_service = WeatherService()
