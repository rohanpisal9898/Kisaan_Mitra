"""Pydantic models for weather data."""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date


class WeatherLocation(BaseModel):
    latitude: float
    longitude: float


class CurrentWeather(BaseModel):
    temperature: float = Field(..., description="Temperature in °C")
    feels_like: float = Field(..., description="Feels-like temperature in °C")
    condition: str = Field(..., description="Human-readable condition (Sunny, Cloudy, etc.)")
    humidity: Optional[float] = Field(None, description="Relative humidity %")


class RainForecast(BaseModel):
    amount_mm: float = Field(0, description="Expected rainfall in mm")
    date: Optional[str] = Field(None, description="Date of expected rain (ISO format)")
    description: str = Field("No significant rain expected", description="Human-readable rain info")


class WindInfo(BaseModel):
    speed_kmh: float = Field(0, description="Wind speed in km/h")
    description: str = Field("", description="Human-readable wind info")


class DailyForecast(BaseModel):
    date: str
    temp_max: float
    temp_min: float
    precipitation_mm: float
    condition: str


class WeatherResponse(BaseModel):
    location: WeatherLocation
    current: CurrentWeather
    rain: RainForecast
    wind: WindInfo
    forecast: List[DailyForecast] = Field(default_factory=list)
    available: bool = True
    error: Optional[str] = None
