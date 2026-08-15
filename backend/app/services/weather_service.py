"""
Weather service for Kisaan Mitra.

Wraps Open-Meteo integration with location-specific caching, ET0 extraction,
canonical context reuse, and reliable fallback handling.
"""

from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.integrations.open_meteo import fetch_weather
from app.config import get_settings

settings = get_settings()

# In-memory location cache: key = "lat,lon" → (weather_data_dict, timestamp)
_weather_cache: Dict[str, tuple] = {}
CACHE_DURATION_MINUTES = 30


class WeatherService:
    """Provides current weather + ET0 forecast for a farmer's location."""

    def _get_cache_key(self, latitude: float, longitude: float) -> str:
        return f"{round(float(latitude), 4)},{round(float(longitude), 4)}"

    async def get_weather(
        self,
        db: Optional[AsyncIOMotorDatabase],
        latitude: float,
        longitude: float,
    ) -> Dict[str, Any]:
        """
        Get weather for coordinates.
        Uses last-known-good cache fallback if Open-Meteo API is unavailable.
        Returns structured weather dict with canonical source indicator.
        """
        cache_key = self._get_cache_key(latitude, longitude)

        # Check cache if fresh (< 30 min)
        if cache_key in _weather_cache:
            cached_data, cached_time = _weather_cache[cache_key]
            age_sec = (datetime.utcnow() - cached_time).total_seconds()
            if age_sec < (CACHE_DURATION_MINUTES * 60):
                res = dict(cached_data)
                res["source"] = "cached"
                curr = res.get("current", {})
                rain = res.get("rain", {})
                wind = res.get("wind", {})
                et0 = res.get("et0_mm")
                age_m = int(age_sec / 60)
                print(
                    f"[WEATHER CACHE HIT] Location={cache_key} "
                    f"Temp={curr.get('temperature')}°C Rain={rain.get('amount_mm')}mm "
                    f"Wind={wind.get('speed_kmh')}km/h ET0={et0}mm Source=Cache Age={age_m}m"
                )
                return res

        # Mock mode override if explicitly enabled in settings
        if settings.use_mock_data:
            return self._mock_weather(latitude, longitude)

        # Try live Open-Meteo API
        weather_data = await fetch_weather(latitude, longitude)

        if weather_data is not None and weather_data.get("available", False):
            weather_data["source"] = "open_meteo"
            _weather_cache[cache_key] = (weather_data, datetime.utcnow())
            curr = weather_data.get("current", {})
            rain = weather_data.get("rain", {})
            wind = weather_data.get("wind", {})
            et0 = weather_data.get("et0_mm")
            print(
                f"[WEATHER] Location={cache_key} "
                f"Temp={curr.get('temperature')}°C Rain={rain.get('amount_mm')}mm "
                f"Wind={wind.get('speed_kmh')}km/h ET0={et0}mm Source=Open-Meteo"
            )
            return weather_data

        # Fallback Hierarchy Step 2: Use last-known-good cached data for this location if available
        if cache_key in _weather_cache:
            cached_data, cached_time = _weather_cache[cache_key]
            age_m = int((datetime.utcnow() - cached_time).total_seconds() / 60)
            res = dict(cached_data)
            res["source"] = "cached"
            curr = res.get("current", {})
            rain = res.get("rain", {})
            wind = res.get("wind", {})
            et0 = res.get("et0_mm")
            print(
                f"[WEATHER CACHE FALLBACK] Open-Meteo API failed for {cache_key}. Using last valid cached response. "
                f"Temp={curr.get('temperature')}°C Rain={rain.get('amount_mm')}mm ET0={et0}mm Age={age_m}m"
            )
            return res

        # Fallback Hierarchy Step 3: Explicit Unavailable status (no fake 0°C or arbitrary mock values)
        print(f"[WEATHER ERROR] Open-Meteo unavailable for {cache_key} and no valid cache available.")
        return {
            "location": {"latitude": latitude, "longitude": longitude},
            "current": {
                "temperature": None,
                "feels_like": None,
                "condition": "Unavailable",
                "humidity": None,
            },
            "rain": {
                "amount_mm": 0.0,
                "date": None,
                "description": "Weather data unavailable",
            },
            "wind": {
                "speed_kmh": 0.0,
                "description": "Unavailable",
            },
            "et0_mm": None,
            "forecast": [],
            "available": False,
            "source": "unavailable",
            "error": "Weather data unavailable.",
        }

    def _mock_weather(self, latitude: float, longitude: float) -> Dict[str, Any]:
        """Return realistic mock weather for test/dev mode."""
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
            "et0_mm": 4.5,
            "forecast": [
                {"date": today, "temp_max": 28.0, "temp_min": 22.0, "precipitation_mm": 0.0, "condition": "Partly Cloudy", "eto_mm": 4.5},
                {"date": tomorrow, "temp_max": 27.0, "temp_min": 21.0, "precipitation_mm": 18.0, "condition": "Rain", "eto_mm": 3.8},
                {"date": (datetime.now() + timedelta(days=2)).strftime("%Y-%m-%d"), "temp_max": 26.0, "temp_min": 21.0, "precipitation_mm": 5.0, "condition": "Light Rain", "eto_mm": 4.0},
            ],
            "available": True,
            "source": "mock",
        }


# Singleton
weather_service = WeatherService()
