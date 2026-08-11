"""
Dashboard Diagnostic Service.

Prints detailed diagnostic report for developer inspection.
"""

from typing import Dict, Any, Optional
from datetime import date
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.services.crop_stage_service import crop_stage_service
from app.services.weather_service import weather_service
from app.services.water_service import water_service
from app.services.crop_health_service import crop_health_service
from app.services.yield_service import yield_service
from app.ml.model_loader import model_loader


class DiagnosticService:
    """Diagnostic tool for verifying all dashboard backend engines."""

    async def run_diagnostic(
        self,
        db: AsyncIOMotorDatabase,
        phone_number: Optional[str] = None,
    ) -> Dict[str, Any]:
        user_doc = None
        if db is not None and phone_number:
            user_doc = await db.users.find_one({"phone_number": phone_number})
        if not user_doc and db is not None:
            user_doc = await db.users.find_one({})

        if not user_doc:
            user_doc = {
                "farmer_name": "Ramesh",
                "village": "Sonepur",
                "district": "Nashik",
                "state": "Maharashtra",
                "latitude": 19.9975,
                "longitude": 73.7898,
                "current_crop": "Soyabean",
                "sowing_date": "2026-06-15",
                "satellite_date": "2026-08-06",
                "satellite_data": {"NDVI": 0.65, "NDMI": 0.20, "NDYI": 0.15, "LST": 28.5},
            }

        farmer_name = user_doc.get("farmer_name", "Ramesh")
        village = user_doc.get("village", "Sonepur")
        district = user_doc.get("district", "Nashik")
        state = user_doc.get("state", "Maharashtra")
        lat = user_doc.get("latitude", 19.9975)
        lon = user_doc.get("longitude", 73.7898)
        crop = user_doc.get("current_crop", "Soyabean")
        sowing_date = user_doc.get("sowing_date", "2026-06-15")

        profile = await crop_stage_service.get_crop_profile(db, crop)
        stage_res = crop_stage_service.calculate_stage(profile or {}, sowing_date)

        weather_res = await weather_service.get_weather(db, lat, lon)
        curr_weather = weather_res.get("current", {})
        rain_info = weather_res.get("rain", {})
        wind_info = weather_res.get("wind", {})
        forecast_list = weather_res.get("forecast", [])
        eto_mm = forecast_list[0].get("eto_mm", 5.2) if forecast_list else 5.2

        water_res = water_service.calculate_water_status(
            profile or {}, stage_res.get("days_after_sowing", 60), eto_mm, rain_info.get("amount_mm", 18.0)
        )

        sat_data = user_doc.get("satellite_data")
        sat_date = user_doc.get("satellite_date")
        health_res = crop_health_service.calculate_health(
            profile or {}, stage_res.get("stage_id", "flowering"), sat_data, sat_date
        )

        farm_ctx = {
            "state": state, "district": district, "crop_name": crop, "latitude": lat, "longitude": lon,
            "sowing_date": sowing_date, "has_satellite_data": health_res.get("satellite_available", False),
            "satellite_data": sat_data
        }
        yield_res = await yield_service.predict_yield(farm_ctx)

        sat_model, sat_order = model_loader.get_model_for_user(True)
        nosat_model, nosat_order = model_loader.get_model_for_user(False)

        report = f"""
==================================================
KISAAN MITRA DASHBOARD DIAGNOSTIC
==================================================

PROFILE
Crop: {crop}
Sowing date: {sowing_date}
Location: {village}, {district} • {state} ({lat}, {lon})

STAGE
Today: {date.today().isoformat()}
Days after sowing: {stage_res.get('days_after_sowing')}
Stage: {stage_res.get('stage_name')} ({stage_res.get('stage_id')}, Index: {stage_res.get('stage_index')})

WEATHER
Source: {'Open-Meteo' if weather_res.get('available') else 'Mock/Fallback'}
Temperature: {curr_weather.get('temperature')}°C
Rain: {rain_info.get('amount_mm')} mm
Wind: {wind_info.get('speed_kmh')} km/h

WATER
Kc: {water_res.get('calculation', {}).get('kc')}
Kc source: {water_res.get('kc_status')}
ET0: {water_res.get('calculation', {}).get('eto_mm')} mm
ETc: {water_res.get('calculation', {}).get('crop_water_demand_etc_mm')} mm
Effective rainfall: {water_res.get('calculation', {}).get('effective_rainfall_mm')} mm
Irrigation need: {water_res.get('calculation', {}).get('net_irrigation_need_mm')} mm
Water Status: {water_res.get('status_display')} (~{water_res.get('irrigation_mm')} mm)

SATELLITE
Image date: {sat_date}
Age: {health_res.get('satellite_days_old')} days
NDVI: {sat_data.get('NDVI') if sat_data else 'None'}
NDMI: {sat_data.get('NDMI') if sat_data else 'None'}
LST: {sat_data.get('LST') if sat_data else 'None'}

HEALTH
Score: {health_res.get('score')}
Status: {health_res.get('status_display')} ({health_res.get('status')})

YIELD
Model: {yield_res.get('model_used')}
CatBoost Satellite Model Loaded: {sat_model is not None} (Features: {len(sat_order)})
CatBoost NoSat Model Loaded: {nosat_model is not None} (Features: {len(nosat_order)})
Prediction: {yield_res.get('yield_predicted')} {yield_res.get('unit')}
Lower: {yield_res.get('yield_lower')}
Upper: {yield_res.get('yield_upper')}

==================================================
"""
        print(report)
        return {
            "profile": {"crop": crop, "sowing_date": sowing_date, "location": f"{village}, {district}"},
            "stage": stage_res,
            "weather": curr_weather,
            "water": water_res,
            "health": health_res,
            "yield": yield_res,
            "sat_features": len(sat_order),
            "nosat_features": len(nosat_order),
        }


diagnostic_service = DiagnosticService()
