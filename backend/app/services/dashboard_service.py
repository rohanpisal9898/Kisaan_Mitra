"""
Single Dashboard Service for Kisaan Mitra.

Orchestrates:
  User profile → Crop stage → Weather → Water status → Satellite Crop Health → CatBoost Yield → Gemini Recommendations
"""

from typing import Dict, Any, Optional
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.services.crop_stage_service import crop_stage_service
from app.services.weather_service import weather_service
from app.services.water_service import water_service
from app.services.crop_health_service import crop_health_service
from app.services.yield_service import yield_service
from app.services.recommendation_service import recommendation_service

from app.models.dashboard import (
    SownDashboardResponse,
    FarmerInfo,
    CropInfo,
    WeatherInfo,
    CropStageInfo,
    WaterStatusInfo,
    CropHealthInfo,
    YieldPredictionInfo,
    RecommendationItem,
)


class DashboardService:
    """Orchestrates all backend services into a single sown-crop dashboard response."""

    async def get_sown_dashboard(
        self,
        db: AsyncIOMotorDatabase,
        phone_number: Optional[str] = None,
        language: str = "English",
    ) -> SownDashboardResponse:
        user_doc = None
        if db is not None and phone_number and phone_number.strip():
            user_doc = await db.users.find_one({"phone_number": phone_number.strip()})
        
        if not user_doc and db is not None:
            # Query the most recently updated/registered user if phone_number is not supplied
            user_doc = await db.users.find_one({}, sort=[("updated_at", -1)])

        if not user_doc:
            user_doc = self._default_user_doc()

        farmer_name = user_doc.get("farmer_name", "Ramesh")
        village = user_doc.get("village", "Sonepur")
        district = user_doc.get("district", "Nashik")
        state = user_doc.get("state", "Maharashtra")
        latitude = user_doc.get("latitude", 19.9975)
        longitude = user_doc.get("longitude", 73.7898)
        current_crop = user_doc.get("current_crop", "Soyabean")
        sowing_date_str = user_doc.get("sowing_date", "2026-06-15")

        print(f"\n[DASHBOARD SERVICE DEBUG]")
        print(f"  Requested Phone : {phone_number}")
        print(f"  User Found Phone: {user_doc.get('phone_number', 'DEFAULT')}")
        print(f"  Farmer Name     : {farmer_name}")
        print(f"  Location        : {village}, {district} • {state} (lat: {latitude}, lon: {longitude})")
        print(f"  Current Crop    : {current_crop}")
        print(f"  Sowing Date     : {sowing_date_str}")

        # 1. Fetch Crop Profile
        crop_profile = await crop_stage_service.get_crop_profile(db, current_crop)
        crop_id = crop_profile.get("crop_id", "soybean") if crop_profile else "soybean"

        # 2. Calculate Crop Stage (Canonical)
        stage_res = crop_stage_service.calculate_stage(
            crop_profile or {}, sowing_date_str
        )

        # 3. Weather
        weather_res = await weather_service.get_weather(db, latitude, longitude)
        curr_weather = weather_res.get("current", {})
        rain_info = weather_res.get("rain", {})
        wind_info = weather_res.get("wind", {})
        forecast_list = weather_res.get("forecast", [])
        eto_mm = forecast_list[0].get("eto_mm", 5.2) if forecast_list else 5.2

        print(f"[WEATHER DEBUG]")
        print(f"  Latitude={latitude}, Longitude={longitude}")
        print(f"  Current Temp={curr_weather.get('temperature')}°C, Rain Forecast={rain_info.get('amount_mm')} mm, Wind={wind_info.get('speed_kmh')} km/h")
        print(f"  Weather Source={'Mock' if not weather_res.get('available') else 'Open-Meteo'}")

        # 4. Water Status
        days_after_sowing = stage_res.get("days_after_sowing", 60)
        forecast_rain_mm = rain_info.get("amount_mm", 18.0)
        water_res = water_service.calculate_water_status(
            crop_profile or {}, days_after_sowing, eto_mm, forecast_rain_mm
        )

        print(f"[WATER DEBUG]")
        print(f"  Crop={current_crop}, Stage={stage_res.get('stage_name')}, DAS={days_after_sowing}")
        print(f"  Kc={water_res.get('calculation', {}).get('kc')}, ET0={eto_mm}, ETc={water_res.get('calculation', {}).get('crop_water_demand_etc_mm')} mm")
        print(f"  Forecast Rain={forecast_rain_mm} mm, Net Irr Need={water_res.get('calculation', {}).get('net_irrigation_need_mm')} mm")
        print(f"  Water Status Display={water_res.get('status_display')}, Irr to apply={water_res.get('irrigation_mm')} mm")

        # 5. Crop Health (Satellite)
        satellite_data = user_doc.get("satellite_data")
        satellite_date = user_doc.get("satellite_date")
        health_res = crop_health_service.calculate_health(
            crop_profile or {}, stage_res.get("stage_id", "flowering"), satellite_data, satellite_date
        )

        print(f"[CROP HEALTH DEBUG]")
        print(f"  Status={health_res.get('status')}, Display={health_res.get('status_display')}, Score={health_res.get('score')}")
        print(f"  Satellite Available={health_res.get('satellite_available')}, Date={satellite_date}, Days Old={health_res.get('satellite_days_old')}")

        # 6. Yield Prediction (CatBoost Adapter)
        farm_context = {
            "state": state,
            "district": district,
            "crop_name": current_crop,
            "crop_id": crop_id,
            "latitude": latitude,
            "longitude": longitude,
            "sowing_date": sowing_date_str,
            "has_satellite_data": health_res.get("satellite_available", False),
            "satellite_data": satellite_data,
        }
        yield_res = await yield_service.predict_yield(farm_context)

        print(f"[YIELD PREDICTION DEBUG]")
        print(f"  Model Used={yield_res.get('model_used')}")
        print(f"  Predicted={yield_res.get('yield_predicted')}, Lower={yield_res.get('yield_lower')}, Upper={yield_res.get('yield_upper')} {yield_res.get('unit')}")

        # 7. Gemini Recommendations (Deterministic fallback if API fails)
        rec_context = {
            "crop_name": current_crop,
            "district": district,
            "state": state,
            "crop_stage": stage_res.get("stage_name", "Flowering"),
            "days_after_sowing": days_after_sowing,
            "weather_summary": {
                "temperature": curr_weather.get("temperature", 26.0),
                "condition": curr_weather.get("condition", "Partly Cloudy"),
                "rain_mm": forecast_rain_mm,
                "wind_kmh": wind_info.get("speed_kmh", 5.0),
            },
            "water_summary": {
                "status": water_res.get("status", "rain_sufficient"),
                "irrigation_mm": water_res.get("irrigation_mm", 0.0),
            },
            "health_summary": {
                "status": health_res.get("status", "good"),
                "score": health_res.get("score", 86.0),
            },
            "yield_summary": {
                "predicted": yield_res.get("yield_predicted", 3.4),
                "lower": yield_res.get("yield_lower", 3.1),
                "upper": yield_res.get("yield_upper", 3.7),
            },
        }
        raw_recs = await recommendation_service.get_recommendations(rec_context, language)

        recommendations_list = []
        for r in raw_recs:
            recommendations_list.append(
                RecommendationItem(
                    priority=r.get("priority", 1),
                    type=r.get("type", "water"),
                    title=r.get("title", "Rain expected soon"),
                    description=r.get("description", "Delay irrigation if enough rain occurs"),
                    severity=r.get("severity", "medium"),
                    icon=r.get("icon", "💡"),
                )
            )

        return SownDashboardResponse(
            state="sown",
            farmer=FarmerInfo(
                name=farmer_name,
                village=village,
                district=district,
                state=state,
            ),
            crop=CropInfo(
                id=crop_id,
                name=current_crop,
                sowing_date=str(sowing_date_str)[:10],
            ),
            weather=WeatherInfo(
                temperature=float(curr_weather.get("temperature", 26.0)),
                feels_like=float(curr_weather.get("feels_like", 28.0)),
                condition=str(curr_weather.get("condition", "Partly Cloudy")),
                rain_next_24h_mm=float(forecast_rain_mm),
                rain_description=f"{round(forecast_rain_mm)} mm rain expected",
                wind_kmh=float(wind_info.get("speed_kmh", 5.0)),
                available=weather_res.get("available", True),
            ),
            crop_stage=CropStageInfo(
                stage_id=stage_res.get("stage_id", "flowering"),
                stage_name=stage_res.get("stage_name", "Flowering"),
                stage_display=stage_res.get("stage_display", "Flowering"),
                stage_icon=stage_res.get("stage_icon", "🌼"),
                stage_index=stage_res.get("stage_index", 2),
                status=stage_res.get("status", "on_track"),
                days_after_sowing=stage_res.get("days_after_sowing", 60),
                total_duration=stage_res.get("total_duration", 104),
                progress_fraction=stage_res.get("progress_fraction", 0.577),
            ),
            water=WaterStatusInfo(
                status=water_res.get("status", "rain_sufficient"),
                status_display=water_res.get("status_display", "Rain may cover need"),
                irrigation_mm=float(water_res.get("irrigation_mm", 0.0)),
                description=water_res.get("description", "No irrigation needed today"),
                color=water_res.get("color", "blue"),
                kc_status=water_res.get("kc_status", "established"),
            ),
            crop_health=CropHealthInfo(
                status=health_res.get("status", "good"),
                status_display=health_res.get("status_display", "Good"),
                score=health_res.get("score", 86.0),
                description=health_res.get("description", "Your crop is growing normally"),
                satellite_available=health_res.get("satellite_available", True),
                satellite_date=health_res.get("satellite_date", "2026-08-06"),
                satellite_days_old=health_res.get("satellite_days_old", 4),
            ),
            yield_prediction=YieldPredictionInfo(
                predicted=float(yield_res.get("yield_predicted", 3.4)),
                lower=float(yield_res.get("yield_lower", 3.1)),
                upper=float(yield_res.get("yield_upper", 3.7)),
                unit=yield_res.get("unit", "tonnes_per_hectare"),
                model_used=yield_res.get("model_used", "satellite"),
                confidence_label="90% Confidence Range",
            ),
            recommendations=recommendations_list,
        )

    def _default_user_doc(self) -> Dict[str, Any]:
        return {
            "farmer_name": "Ramesh",
            "village": "Sonepur",
            "district": "Nashik",
            "state": "Maharashtra",
            "latitude": 19.9975,
            "longitude": 73.7898,
            "current_crop": "Soyabean",
            "sowing_date": "2026-06-15",
            "has_satellite_data": True,
            "satellite_date": "2026-08-06",
            "satellite_data": {
                "NDVI": 0.65,
                "NDMI": 0.20,
                "NDYI": 0.15,
                "LST": 28.5
            }
        }


dashboard_service = DashboardService()
