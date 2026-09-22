"""
Single Dashboard Service for Kisaan Mitra.

Orchestrates:
  User profile → Crop stage → Weather → Water status → Satellite Crop Health → CatBoost Yield → Gemini Recommendations
"""

import asyncio
from typing import Dict, Any, Optional, Tuple
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.config import get_settings
from app.integrations.gee_service import gee_service
from app.services.crop_stage_service import crop_stage_service
from app.services.weather_service import weather_service
from app.services.water_service import water_service
from app.services.crop_health_service import crop_health_service
from app.services.yield_service import yield_service
from app.services.recommendation_service import recommendation_service
from app.services.crop_recommendation_service import crop_recommendation_service
from app.services.wallet_service import wallet_service

from app.models.dashboard import (
    SownDashboardResponse,
    PlanningDashboardResponse,
    TopCropRecommendationItem,
    PreviousCropInfo,
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
    """Orchestrates all backend services with composite in-memory caching and parallel execution."""

    def __init__(self):
        self._sown_cache: Dict[str, Tuple[SownDashboardResponse, datetime]] = {}
        self._overview_cache: Dict[str, Tuple[Dict[str, Any], datetime]] = {}

    def invalidate_cache(self, phone_number: Optional[str] = None):
        """Invalidate in-memory dashboard cache for a user or entirely."""
        if phone_number:
            p_str = phone_number.strip()
            self._sown_cache = {k: v for k, v in self._sown_cache.items() if not k.startswith(f"sown:{p_str}:")}
            self._overview_cache = {k: v for k, v in self._overview_cache.items() if not k.startswith(f"overview:{p_str}:")}
        else:
            self._sown_cache.clear()
            self._overview_cache.clear()

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
            user_doc = self._default_user_doc(phone_number)

        farmer_name = user_doc.get("farmer_name", "Ramesh")
        village = user_doc.get("village", "Sonepur")
        district = user_doc.get("district", "Nashik")
        state = user_doc.get("state", "Maharashtra")
        latitude = user_doc.get("latitude") if user_doc.get("latitude") is not None else 19.9975
        longitude = user_doc.get("longitude") if user_doc.get("longitude") is not None else 73.7898
        current_crop = user_doc.get("current_crop", "Soyabean")
        sowing_date_str = user_doc.get("sowing_date", "2026-06-15")
        farm_area = float(user_doc.get("farm_area", 2.5))
        farm_area_unit = str(user_doc.get("farm_area_unit", "acres")).lower()
        farm_area_ha = farm_area * 0.404686 if "acre" in farm_area_unit else farm_area

        # Check composite cache key: user + crop + sowing_date + location + area + language
        settings = get_settings()
        cache_key = f"sown:{phone_number or 'default'}:{current_crop}:{sowing_date_str}:{round(latitude, 4)}:{round(longitude, 4)}:{round(farm_area_ha, 2)}:{language.lower()}"
        if cache_key in self._sown_cache:
            cached_resp, cached_time = self._sown_cache[cache_key]
            if (datetime.utcnow() - cached_time).total_seconds() < settings.dashboard_cache_ttl_seconds:
                return cached_resp

        print(f"\n[DASHBOARD SERVICE DEBUG]")
        print(f"  Requested Phone : {phone_number}")
        print(f"  User Found Phone: {user_doc.get('phone_number', 'DEFAULT')}")
        print(f"  Farmer Name     : {farmer_name}")
        print(f"  Location        : {village}, {district} • {state} (lat: {latitude}, lon: {longitude})")
        print(f"  Current Crop    : {current_crop}")
        print(f"  Sowing Date     : {sowing_date_str}")

        # Parallelize independent first stage: Crop profile and Weather
        crop_profile_fut = crop_stage_service.get_crop_profile(db, current_crop)
        weather_fut = weather_service.get_weather(db, latitude, longitude)
        crop_profile, weather_res = await asyncio.gather(crop_profile_fut, weather_fut)

        crop_id = crop_profile.get("crop_id", "soybean") if crop_profile else "soybean"

        # 2. Calculate Crop Stage (Canonical for Today)
        stage_res = crop_stage_service.calculate_stage(
            crop_profile or {}, sowing_date_str
        )
        curr_weather = weather_res.get("current", {})
        rain_info = weather_res.get("rain", {})
        wind_info = weather_res.get("wind", {})
        forecast_list = weather_res.get("forecast", [])
        weather_available = weather_res.get("available", True)
        weather_source = weather_res.get("source", "open_meteo")

        # Canonical ET0 Extraction (Strict single source per request)
        raw_et0 = weather_res.get("et0_mm")
        if raw_et0 is None and forecast_list and len(forecast_list) > 0:
            raw_et0 = forecast_list[0].get("eto_mm")

        eto_mm = round(float(raw_et0), 2) if raw_et0 is not None else 4.5
        forecast_rain_mm = float(rain_info.get("amount_mm") or 0.0)
        curr_temp = curr_weather.get("temperature") if curr_weather.get("temperature") is not None else 26.0
        wind_speed = wind_info.get("speed_kmh") if wind_info.get("speed_kmh") is not None else 5.0

        print(f"[WEATHER DEBUG]")
        print(f"  Latitude={latitude}, Longitude={longitude}")
        print(f"  Current Temp={curr_temp}°C, Rain Forecast={forecast_rain_mm} mm, Wind={wind_speed} km/h")
        print(f"  ET0={eto_mm} mm/day, Weather Source={weather_source}, Available={weather_available}")

        # 4. Water Status (Consumes Canonical Weather Context)
        days_after_sowing = stage_res.get("days_after_sowing", 60)
        water_res = water_service.calculate_water_status(
            crop_profile or {}, days_after_sowing, eto_mm, forecast_rain_mm
        )

        print(f"[WATER DEBUG]")
        print(f"  Crop={current_crop}, Stage={stage_res.get('stage_name')}, DAS={days_after_sowing}")
        print(f"  Kc={water_res.get('calculation', {}).get('kc')}, ET0={eto_mm}, ETc={water_res.get('calculation', {}).get('crop_water_demand_etc_mm')} mm")
        print(f"  Forecast Rain={forecast_rain_mm} mm, Net Irr Need={water_res.get('calculation', {}).get('net_irrigation_need_mm')} mm")
        print(f"  Water Status Display={water_res.get('status_display')}, Irr to apply={water_res.get('irrigation_mm')} mm")

        # 5. Crop Health / Satellite Default State (No satellite model active by default)
        satellite_data = None
        satellite_date = None
        satellite_source = "unavailable"

        # Safe default crop health object without triggering GEE
        health_stage_id = stage_res.get("stage_id", "flowering")
        health_res = {
            "status": "normal",
            "status_display": "No satellite model active",
            "score": 85.0,
            "description": "No satellite model active",
            "satellite_available": False,
            "satellite_date": None,
            "satellite_days_old": 0,
        }

        # 6. Yield Prediction (Default standard No-Sat model)
        farm_context = {
            "state": state,
            "district": district,
            "crop_name": current_crop,
            "crop_id": crop_id,
            "latitude": latitude,
            "longitude": longitude,
            "sowing_date": sowing_date_str,
            "has_satellite_data": False,
            "satellite_data": None,
        }
        yield_res = await yield_service.predict_yield(farm_context)

        print(f"[YIELD PREDICTION DEBUG]")
        print(f"  Model Used={yield_res.get('model_used')} (Default: No satellite model active)")
        print(f"  Predicted={yield_res.get('yield_predicted')}, Lower={yield_res.get('yield_lower')}, Upper={yield_res.get('yield_upper')} {yield_res.get('unit')}")

        # 7. Gemini Recommendations (Deterministic 3-category fallback if API fails)
        rec_context = {
            "phone_number": phone_number,
            "crop_name": current_crop,
            "district": district,
            "state": state,
            "crop_stage": stage_res.get("stage_name", "Flowering"),
            "days_after_sowing": days_after_sowing,
            "current_month": datetime.now().strftime("%B"),
            "farm_area_ha": farm_area_ha,
            "weather_summary": {
                "temperature": curr_weather.get("temperature", 26.0),
                "condition": curr_weather.get("condition", "Partly Cloudy"),
                "rain_mm": forecast_rain_mm,
                "wind_kmh": wind_info.get("speed_kmh", 5.0),
            },
            "water_summary": {
                "status": water_res.get("status", "rain_sufficient"),
                "irrigation_mm": water_res.get("irrigation_mm", 0.0),
                "net_irrigation_mm": water_res.get("irrigation_mm", 0.0),
                "et0": eto_mm,
                "kc": water_res.get("calculation", {}).get("kc", 0.8),
                "etc": water_res.get("calculation", {}).get("crop_water_demand_etc_mm", 3.6),
                "forecast_rain": forecast_rain_mm,
                "weather_source": weather_source,
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
                    category=r.get("category", "general"),
                    type=r.get("type", "water"),
                    title=r.get("title", ""),
                    description=r.get("description", ""),
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
        self._sown_cache[cache_key] = (response, datetime.utcnow())
        return response

    def _default_user_doc(self, phone_number: Optional[str] = None) -> Dict[str, Any]:
        if phone_number == "1234567894":
            return {
                "phone_number": "1234567894",
                "farmer_name": "manav",
                "village": "navalgad",
                "district": "JHUNJHUNU",
                "state": "Rajasthan",
                "latitude": 19.20881628657986,
                "longitude": 72.8728440148901,
                "current_crop": "Rapeseed &Mustard",
                "sowing_date": "2026-08-11",
                "satellite_date": None,
                "satellite_data": None,
                "satellite_source": "unavailable",
            }
        return {
            "phone_number": "9876543210",
            "farmer_name": "Ramesh",
            "village": "Sonepur",
            "district": "Nashik",
            "state": "Maharashtra",
            "latitude": 19.9975,
            "longitude": 73.7898,
            "current_crop": "Soyabean",
            "sowing_date": "2026-06-15",
            "satellite_date": None,
            "satellite_data": None,
            "satellite_source": "unavailable",
        }

    async def get_dashboard_overview(
        self,
        db: AsyncIOMotorDatabase,
        phone_number: Optional[str] = None,
        language: str = "English",
        query_date: Optional[Any] = None,
    ) -> Dict[str, Any]:
        """
        Dynamic multi-state dashboard handler with composite caching.
        Determines dashboard_state:
          1. "no_crop": current_crop is None / empty -> Planning Dashboard UI
          2. "crop_matured": active crop stage is maturity / DAS >= duration -> Transition Planning UI
          3. "growing": active growing crop -> Existing Sown Dashboard UI
        """
        user_doc = None
        if db is not None and phone_number and phone_number.strip():
            user_doc = await db.users.find_one({"phone_number": phone_number.strip()})

        if not user_doc and db is not None:
            user_doc = await db.users.find_one({}, sort=[("updated_at", -1)])

        if not user_doc:
            user_doc = self._default_user_doc(phone_number)

        current_crop = user_doc.get("current_crop")
        sowing_date_str = user_doc.get("sowing_date")
        latitude = user_doc.get("latitude") if user_doc.get("latitude") is not None else 19.9975
        longitude = user_doc.get("longitude") if user_doc.get("longitude") is not None else 73.7898
        farmer_name = user_doc.get("farmer_name", "Ramesh")
        village = user_doc.get("village", "Sonepur")
        district = user_doc.get("district", "Nashik")
        state = user_doc.get("state", "Maharashtra")
        farm_area_ha = float(user_doc.get("farm_area", user_doc.get("land_size_ha", 2.5)))

        settings = get_settings()
        cache_key = f"overview:{phone_number or 'default'}:{current_crop}:{sowing_date_str}:{round(latitude, 4)}:{round(longitude, 4)}:{round(farm_area_ha, 2)}:{language.lower()}:{query_date}"
        if cache_key in self._overview_cache:
            cached_resp, cached_time = self._overview_cache[cache_key]
            if (datetime.utcnow() - cached_time).total_seconds() < settings.dashboard_cache_ttl_seconds:
                return cached_resp

        # 1. State A: No Crop Sown
        if not current_crop or str(current_crop).strip().lower() in ["none", "null", "not sown yet", "not_sown", ""]:
            print(f"[DASHBOARD STATE] No crop sown for {farmer_name}. Routing to Planning Dashboard.")
            weather_res = await weather_service.get_weather(db, latitude, longitude)
            curr_w = weather_res.get("current", {})
            rain_w = weather_res.get("rain", {})
            wind_w = weather_res.get("wind", {})

            weather_info = WeatherInfo(
                temperature=float(curr_w.get("temperature", 26.0)),
                feels_like=float(curr_w.get("feels_like", 28.0)),
                condition=str(curr_w.get("condition", "Sunny Day")),
                rain_next_24h_mm=float(rain_w.get("amount_mm", 18.0)),
                rain_description=str(rain_w.get("description", "18 mm rain expected")),
                wind_kmh=float(wind_w.get("speed_kmh", 5.0)),
                available=bool(weather_res.get("available", True)),
            )

            recs = await crop_recommendation_service.get_top_recommendations(db, user_doc, language, query_date)
            top_rec_items = [TopCropRecommendationItem(**r) for r in recs]
            market_items = await wallet_service.get_oilseed_markets_from_db(db, state, None, district)

            res = PlanningDashboardResponse(
                dashboard_state="no_crop",
                farmer=FarmerInfo(name=farmer_name, village=village, district=district, state=state),
                location={"latitude": latitude, "longitude": longitude, "village": village, "district": district, "state": state},
                farm_area_ha=farm_area_ha,
                weather=weather_info,
                previous_crop=None,
                top_recommendations=top_rec_items,
                market_items=market_items,
                financial_outlook=None,
                yield_prediction=None,
                crop_health=None,
                water_status=None,
            ).dict()
            self._overview_cache[cache_key] = (res, datetime.utcnow())
            return res

        # 2. Check Crop Maturity for active crop
        crop_profile_task = crop_stage_service.get_crop_profile(db, current_crop)
        weather_task = weather_service.get_weather(db, latitude, longitude)
        crop_profile, weather_res = await asyncio.gather(crop_profile_task, weather_task)

        stage_res = crop_stage_service.calculate_stage(
            crop_profile or {}, sowing_date_str, query_date_str=query_date.isoformat() if query_date else None
        )

        stage_id = stage_res.get("stage_id", "flowering")
        days_after_sowing = stage_res.get("days_after_sowing", 60)
        total_duration = stage_res.get("total_duration", 104)

        # State B: Crop Reached Maturity
        if stage_id == "maturity" or days_after_sowing >= total_duration:
            print(f"[DASHBOARD STATE] Crop {current_crop} reached maturity (DAS: {days_after_sowing}/{total_duration}). Routing to Maturity Transition Dashboard.")
            curr_w = weather_res.get("current", {})
            rain_w = weather_res.get("rain", {})
            wind_w = weather_res.get("wind", {})

            weather_info = WeatherInfo(
                temperature=float(curr_w.get("temperature", 26.0)),
                feels_like=float(curr_w.get("feels_like", 28.0)),
                condition=str(curr_w.get("condition", "Sunny Day")),
                rain_next_24h_mm=float(rain_w.get("amount_mm", 18.0)),
                rain_description=str(rain_w.get("description", "18 mm rain expected")),
                wind_kmh=float(wind_w.get("speed_kmh", 5.0)),
                available=bool(weather_res.get("available", True)),
            )

            recs = await crop_recommendation_service.get_top_recommendations(db, user_doc, language, query_date)
            top_rec_items = [TopCropRecommendationItem(**r) for r in recs]
            market_items = await wallet_service.get_oilseed_markets_from_db(db, state, None, district)

            prev_crop_info = PreviousCropInfo(
                name=current_crop,
                sowing_date=str(sowing_date_str),
                status="mature",
            )

            res = PlanningDashboardResponse(
                dashboard_state="crop_matured",
                farmer=FarmerInfo(name=farmer_name, village=village, district=district, state=state),
                location={"latitude": latitude, "longitude": longitude, "village": village, "district": district, "state": state},
                farm_area_ha=farm_area_ha,
                weather=weather_info,
                previous_crop=prev_crop_info,
                top_recommendations=top_rec_items,
                market_items=market_items,
                financial_outlook=None,
                yield_prediction=None,
                crop_health=None,
                water_status=None,
            ).dict()
            self._overview_cache[cache_key] = (res, datetime.utcnow())
            return res

        # 3. State C: Active Growing Crop -> Sown Dashboard
        sown_resp = await self.get_sown_dashboard(db, phone_number, language)
        res_dict = sown_resp.dict()
        res_dict["dashboard_state"] = "growing"
        self._overview_cache[cache_key] = (res_dict, datetime.utcnow())
        return res_dict


dashboard_service = DashboardService()
