"""
Open-Meteo integration for dashboard weather.

Uses Open-Meteo free API — no API key required.
Fetches current conditions + 7-day forecast.
"""

import httpx
from typing import Optional, Dict, Any
from datetime import date, timedelta
from app.config import get_settings

settings = get_settings()

# WMO Weather interpretation codes → human-readable conditions
WMO_CODES = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Foggy",
    48: "Rime fog",
    51: "Light drizzle",
    53: "Moderate drizzle",
    55: "Dense drizzle",
    56: "Freezing drizzle",
    57: "Heavy freezing drizzle",
    61: "Slight rain",
    63: "Moderate rain",
    65: "Heavy rain",
    66: "Freezing rain",
    67: "Heavy freezing rain",
    71: "Slight snow",
    73: "Moderate snow",
    75: "Heavy snow",
    77: "Snow grains",
    80: "Slight rain showers",
    81: "Moderate rain showers",
    82: "Violent rain showers",
    85: "Slight snow showers",
    86: "Heavy snow showers",
    95: "Thunderstorm",
    96: "Thunderstorm with hail",
    99: "Thunderstorm with heavy hail",
}

# Simplified farmer-friendly conditions
SIMPLE_CONDITIONS = {
    0: "Sunny",
    1: "Mostly Sunny",
    2: "Partly Cloudy",
    3: "Cloudy",
    45: "Foggy",
    48: "Foggy",
    51: "Light Rain",
    53: "Rain",
    55: "Rain",
    56: "Cold Rain",
    57: "Cold Rain",
    61: "Light Rain",
    63: "Rain",
    65: "Heavy Rain",
    66: "Cold Rain",
    67: "Cold Rain",
    71: "Snow",
    73: "Snow",
    75: "Heavy Snow",
    77: "Snow",
    80: "Rain Showers",
    81: "Rain Showers",
    82: "Heavy Rain",
    85: "Snow Showers",
    86: "Heavy Snow",
    95: "Thunderstorm",
    96: "Thunderstorm",
    99: "Thunderstorm",
}


async def fetch_weather(latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
    """
    Fetch current weather + 7-day forecast from Open-Meteo.

    Returns structured dict matching WeatherResponse model.
    Returns None on failure.
    """
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "current": "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m",
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code,et0_fao_evapotranspiration",
        "timezone": "Asia/Kolkata",
        "forecast_days": 7,
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(settings.open_meteo_base_url, params=params)
            response.raise_for_status()
            data = response.json()
    except Exception as e:
        print(f"[ERROR] Open-Meteo request failed: {e}")
        return None

    # Parse current conditions
    current = data.get("current", {})
    temp = current.get("temperature_2m") or 0.0
    feels_like = current.get("apparent_temperature") if current.get("apparent_temperature") is not None else temp
    humidity = current.get("relative_humidity_2m")
    weather_code = current.get("weather_code") if current.get("weather_code") is not None else 0
    wind_speed = current.get("wind_speed_10m") or 0.0

    condition = SIMPLE_CONDITIONS.get(weather_code, "Unknown")

    # Parse daily forecast
    daily = data.get("daily", {})
    dates = daily.get("time", [])
    temp_maxes = daily.get("temperature_2m_max", [])
    temp_mins = daily.get("temperature_2m_min", [])
    precip_sums = daily.get("precipitation_sum", [])
    daily_codes = daily.get("weather_code", [])
    eto_values = daily.get("et0_fao_evapotranspiration", [])

    forecast = []
    for i in range(len(dates)):
        t_max = temp_maxes[i] if (i < len(temp_maxes) and temp_maxes[i] is not None) else 0.0
        t_min = temp_mins[i] if (i < len(temp_mins) and temp_mins[i] is not None) else 0.0
        p_sum = precip_sums[i] if (i < len(precip_sums) and precip_sums[i] is not None) else 0.0
        d_code = daily_codes[i] if (i < len(daily_codes) and daily_codes[i] is not None) else 0
        eto_val = eto_values[i] if (i < len(eto_values) and eto_values[i] is not None) else None

        forecast.append({
            "date": dates[i],
            "temp_max": t_max,
            "temp_min": t_min,
            "precipitation_mm": p_sum,
            "condition": SIMPLE_CONDITIONS.get(d_code, "Unknown"),
            "eto_mm": eto_val,
        })

    # Find next significant rain
    rain_amount = 0.0
    rain_date = None
    rain_description = "No significant rain expected"

    for f in forecast[1:]:  # skip today
        precip = f.get("precipitation_mm") or 0.0
        if precip > 1.0:
            rain_amount = round(precip, 1)
            rain_date = f["date"]
            if rain_amount >= 40:
                rain_description = f"Heavy rain expected ({rain_amount} mm)"
            elif rain_amount >= 20:
                rain_description = f"{rain_amount} mm rain expected"
            else:
                rain_description = f"{rain_amount} mm rain expected"
            break

    # Wind description
    wind_desc = ""
    if wind_speed >= 40:
        wind_desc = "Strong winds expected"
    elif wind_speed >= 20:
        wind_desc = "Moderate wind"
    else:
        wind_desc = f"{round(wind_speed)} km/h"

    # Extract today's ET0
    today_et0 = None
    if eto_values and len(eto_values) > 0 and eto_values[0] is not None:
        try:
            today_et0 = round(float(eto_values[0]), 2)
        except (ValueError, TypeError):
            today_et0 = None

    return {
        "location": {"latitude": latitude, "longitude": longitude},
        "current": {
            "temperature": round(temp, 1),
            "feels_like": round(feels_like, 1),
            "condition": condition,
            "humidity": humidity,
        },
        "rain": {
            "amount_mm": rain_amount,
            "date": rain_date,
            "description": rain_description,
        },
        "wind": {
            "speed_kmh": round(wind_speed, 1),
            "description": wind_desc,
        },
        "et0_mm": today_et0,
        "forecast": forecast,
        "available": True,
        "source": "open_meteo",
    }


def get_daily_eto(forecast: list, day_offset: int = 0) -> Optional[float]:
    """
    Extract ETo from the forecast for a given day offset.
    day_offset=0 → today, day_offset=1 → tomorrow, etc.
    """
    if day_offset < len(forecast):
        return forecast[day_offset].get("eto_mm")
    return None


def get_rainfall_next_days(forecast: list, days: int = 3) -> float:
    """Sum rainfall for the next N days from forecast."""
    total = 0.0
    for f in forecast[1 : days + 1]:  # skip today
        total += (f.get("precipitation_mm") or 0.0)
    return round(total, 1)

