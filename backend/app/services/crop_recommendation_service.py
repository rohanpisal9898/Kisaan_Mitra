"""
Crop Recommendation Service for Kisaan Mitra.

Calculates dynamic, personalized crop recommendations for No-Crop & Maturity planning states.

Scoring Parameters:
1. Current Market Demand Score (0-100): Gemini API + 6-Hour MongoDB TTL Cache + Fallback.
2. Water Requirement Score (0-100): ETc = sum(ET0 * Kc * days) * Farm Area (m3).
3. Sowing Window Suitability Score (0-100): Compares current date with crop profile sowing window.

Final Weighted Score = 0.40 * Demand + 0.30 * Water + 0.30 * Sowing Window.
Returns Top 3 candidate crops sorted by suitability descending.
"""

import json
import httpx
from datetime import datetime, timedelta, date
from typing import Dict, Any, List, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.config import get_settings
from app.integrations.gemini import settings, _clean_and_parse_json
from app.services.weather_service import weather_service

# Configurable Scoring Weights (Must sum to 1.0)
DEMAND_WEIGHT = 0.40
WATER_WEIGHT = 0.30
SOWING_WEIGHT = 0.30

# Candidate Crops Profile Metadata & Sowing Windows across all 9 Oilseed Crops
CANDIDATE_CROP_METADATA = {
    "Soybean": {
        "crop_id": "soybean",
        "name": "Soybean",
        "icon": "🌱",
        "sowing_window": "June – July",
        "sowing_months": [6, 7],
        "growth_duration_days": 104,
        "stages": {"initial": 16, "development": 28, "mid_season": 40, "late_season": 20},
        "kc": {"initial": 0.35, "mid": 1.15, "end": 0.50},
        "base_net_return_per_ha": 11324,
    },
    "Groundnut": {
        "crop_id": "groundnut",
        "name": "Groundnut",
        "icon": "🌿",
        "sowing_window": "June – July",
        "sowing_months": [6, 7],
        "growth_duration_days": 120,
        "stages": {"initial": 25, "development": 35, "mid_season": 40, "late_season": 20},
        "kc": {"initial": 0.40, "mid": 1.15, "end": 0.60},
        "base_net_return_per_ha": 8760,
    },
    "Sesame": {
        "crop_id": "sesame",
        "name": "Sesame",
        "icon": "🌿",
        "sowing_window": "June – July",
        "sowing_months": [6, 7],
        "growth_duration_days": 100,
        "stages": {"initial": 20, "development": 25, "mid_season": 35, "late_season": 20},
        "kc": {"initial": 0.35, "mid": 1.10, "end": 0.25},
        "base_net_return_per_ha": 6540,
    },
    "Sunflower": {
        "crop_id": "sunflower",
        "name": "Sunflower",
        "icon": "🌻",
        "sowing_window": "June – July",
        "sowing_months": [1, 2, 6, 7],
        "growth_duration_days": 120,
        "stages": {"initial": 20, "development": 35, "mid_season": 45, "late_season": 20},
        "kc": {"initial": 0.35, "mid": 1.15, "end": 0.35},
        "base_net_return_per_ha": 7800,
    },
    "Rapeseed & Mustard": {
        "crop_id": "rapeseed_mustard",
        "name": "Rapeseed & Mustard",
        "icon": "🌾",
        "sowing_window": "October – November",
        "sowing_months": [9, 10, 11],
        "growth_duration_days": 130,
        "stages": {"initial": 20, "development": 35, "mid_season": 50, "late_season": 25},
        "kc": {"initial": 0.35, "mid": 1.10, "end": 0.35},
        "base_net_return_per_ha": 9450,
    },
    "Linseed": {
        "crop_id": "linseed",
        "name": "Linseed",
        "icon": "🌿",
        "sowing_window": "October – November",
        "sowing_months": [10, 11],
        "growth_duration_days": 140,
        "stages": {"initial": 25, "development": 35, "mid_season": 50, "late_season": 30},
        "kc": {"initial": 0.35, "mid": 1.10, "end": 0.25},
        "base_net_return_per_ha": 7100,
    },
    "Castor": {
        "crop_id": "castor",
        "name": "Castor",
        "icon": "🌱",
        "sowing_window": "July – August",
        "sowing_months": [7, 8],
        "growth_duration_days": 150,
        "stages": {"initial": 25, "development": 40, "mid_season": 55, "late_season": 30},
        "kc": {"initial": 0.35, "mid": 1.15, "end": 0.55},
        "base_net_return_per_ha": 8900,
    },
    "Safflower": {
        "crop_id": "safflower",
        "name": "Safflower",
        "icon": "🌼",
        "sowing_window": "September – October",
        "sowing_months": [9, 10],
        "growth_duration_days": 140,
        "stages": {"initial": 25, "development": 35, "mid_season": 50, "late_season": 30},
        "kc": {"initial": 0.35, "mid": 1.10, "end": 0.25},
        "base_net_return_per_ha": 7300,
    },
    "Niger Seed": {
        "crop_id": "niger",
        "name": "Niger Seed",
        "icon": "🌻",
        "sowing_window": "June – July",
        "sowing_months": [6, 7],
        "growth_duration_days": 110,
        "stages": {"initial": 20, "development": 30, "mid_season": 40, "late_season": 20},
        "kc": {"initial": 0.35, "mid": 1.05, "end": 0.30},
        "base_net_return_per_ha": 5800,
    },
}


class CropRecommendationService:
    """Service to compute dynamic top crop recommendations for farmers."""

    def __init__(self):
        self._in_flight_locks = {}

    async def get_market_demand(
        self, db: Optional[AsyncIOMotorDatabase], district: str, state: str, ttl_hours: float = 6.0
    ) -> Dict[str, Dict[str, Any]]:
        """
        Queries Gemini for current market demand with a 6-Hour MongoDB TTL Cache & Fallback.
        Returns dict: { crop_name: {"demand_score": float, "market_demand": str} }
        """
        state_title = state.title() if state else "Maharashtra"
        district_title = district.title() if district else "Nashik"
        now_dt = datetime.now()
        now_iso = now_dt.isoformat()

        # Step 1: Check MongoDB 6-Hour TTL Cache
        if db is not None:
            try:
                cached_doc = await db.market_demand_cache.find_one({"district": district_title, "state": state_title})
                if cached_doc:
                    fetched_at_str = cached_doc.get("fetched_at")
                    if fetched_at_str:
                        f_dt = datetime.fromisoformat(fetched_at_str)
                        if (now_dt - f_dt).total_seconds() < (ttl_hours * 3600):
                            print(f"[DEMAND SERVICE] TTL Cache HIT for {district_title}, {state_title}")
                            return cached_doc.get("demand_data", {})
            except Exception as e:
                print(f"[DEMAND SERVICE] Error reading demand cache: {e}")

        # Step 2: Query Gemini for Market Demand
        gemini_demand = await self._fetch_gemini_demand(district_title, state_title)
        if gemini_demand:
            # Save to MongoDB market_demand_cache
            if db is not None:
                try:
                    await db.market_demand_cache.update_one(
                        {"district": district_title, "state": state_title},
                        {"$set": {
                            "district": district_title,
                            "state": state_title,
                            "demand_data": gemini_demand,
                            "fetched_at": now_iso,
                            "expires_at": (now_dt + timedelta(hours=ttl_hours)).isoformat(),
                        }},
                        upsert=True,
                    )
                    print(f"[DEMAND SERVICE] Saved Gemini demand data to MongoDB TTL cache for {district_title}")
                except Exception as e:
                    print(f"[DEMAND SERVICE] Error saving demand cache: {e}")
            return gemini_demand

        # Step 3: Default Fallback if Gemini fails & cache empty
        default_demand = {
            "Soybean": {"demand_score": 90.0, "market_demand": "High"},
            "Groundnut": {"demand_score": 85.0, "market_demand": "High"},
            "Sesame": {"demand_score": 78.0, "market_demand": "Medium"},
            "Sunflower": {"demand_score": 72.0, "market_demand": "Medium"},
            "Rapeseed & Mustard": {"demand_score": 82.0, "market_demand": "High"},
            "Linseed": {"demand_score": 70.0, "market_demand": "Medium"},
            "Castor": {"demand_score": 80.0, "market_demand": "High"},
            "Safflower": {"demand_score": 68.0, "market_demand": "Medium"},
            "Niger Seed": {"demand_score": 65.0, "market_demand": "Moderate"},
        }
        return default_demand

    async def _fetch_gemini_demand(self, district: str, state: str) -> Optional[Dict[str, Dict[str, Any]]]:
        """Queries Gemini API for market demand intelligence."""
        api_key = settings.gemini_api_key
        if not api_key or api_key == "your_gemini_api_key_here":
            return None

        model_names = [
            "gemini-2.0-flash",
            "gemini-1.5-flash",
            "gemini-1.5-pro",
        ]
        prompt = (
            f"You are an APMC agricultural market demand analyst in India.\n"
            f"For location '{district}', '{state}', India, evaluate current market demand and price attractiveness for these 9 oilseed crops:\n"
            f"1. Soybean\n2. Groundnut\n3. Sesame\n4. Sunflower\n5. Rapeseed & Mustard\n6. Linseed\n7. Castor\n8. Safflower\n9. Niger Seed\n\n"
            f"RULES:\n"
            f"1. Provide a realistic demand_score (0-100) and market_demand ('High', 'Medium', 'Moderate') for EACH crop.\n"
            f"2. Return ONLY a valid JSON object in this exact schema:\n"
            f'{{\n'
            f'  "crops": [\n'
            f'    {{"crop": "Soybean", "demand_score": 92, "market_demand": "High"}},\n'
            f'    {{"crop": "Groundnut", "demand_score": 84, "market_demand": "High"}},\n'
            f'    {{"crop": "Sesame", "demand_score": 78, "market_demand": "Medium"}},\n'
            f'    {{"crop": "Sunflower", "demand_score": 74, "market_demand": "Medium"}},\n'
            f'    {{"crop": "Rapeseed & Mustard", "demand_score": 82, "market_demand": "High"}}\n'
            f'  ]\n'
            f'}}\n'
        )

        for model in model_names:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
            payload = {
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {"temperature": 0.2, "maxOutputTokens": 600, "responseMimeType": "application/json"}
            }
            try:
                async with httpx.AsyncClient(timeout=5.0) as client:
                    resp = await client.post(url, json=payload)
                    if resp.status_code == 200:
                        res_json = resp.json()
                        candidates = res_json.get("candidates", [])
                        if candidates and "content" in candidates[0]:
                            parts = candidates[0]["content"].get("parts", [])
                            if parts and "text" in parts[0]:
                                text = parts[0]["text"].strip()
                                parsed = _clean_and_parse_json(text)
                                if isinstance(parsed, dict) and "crops" in parsed:
                                    result = {}
                                    for item in parsed["crops"]:
                                        c_name = item.get("crop")
                                        score = float(item.get("demand_score", 75))
                                        score = max(0.0, min(100.0, score))
                                        demand_lbl = str(item.get("market_demand", "High"))
                                        if c_name:
                                            result[c_name] = {"demand_score": score, "market_demand": demand_lbl}
                                    if len(result) >= 3:
                                        print(f"[DEMAND GEMINI] Successfully fetched market demand via {model} for {district}")
                                        return result
            except Exception as e:
                print(f"[DEMAND GEMINI] Exception for model {model}: {e}")
                continue

        return None

    def calculate_water_requirement(
        self, crop_meta: Dict[str, Any], farm_area_ha: float, et0_mm_per_day: float = 4.8
    ) -> Dict[str, Any]:
        """
        Calculates total crop cycle water requirement for a crop:
          ETc_stage = ET0 * Kc_stage * days_stage
          Total_depth_mm = sum(ETc_stage)
          Total_volume_m3 = Total_depth_mm * farm_area_ha * 10 (1 mm/ha = 10 m3)
        """
        stages = crop_meta["stages"]
        kc = crop_meta["kc"]

        # 4 Agronomic Stage ETc calculations
        kc_init = kc.get("initial", 0.35)
        kc_mid = kc.get("mid", 1.10)
        kc_end = kc.get("end", 0.40)
        kc_dev = (kc_init + kc_mid) / 2.0
        kc_late = (kc_mid + kc_end) / 2.0

        etc_init = et0_mm_per_day * kc_init * stages.get("initial", 20)
        etc_dev = et0_mm_per_day * kc_dev * stages.get("development", 30)
        etc_mid = et0_mm_per_day * kc_mid * stages.get("mid_season", 40)
        etc_late = et0_mm_per_day * kc_late * stages.get("late_season", 20)

        total_etc_mm = etc_init + etc_dev + etc_mid + etc_late
        total_volume_m3 = round(total_etc_mm * farm_area_ha * 10, 1)

        # Water level display label
        if total_volume_m3 < 4000:
            water_level = "Low"
        elif total_volume_m3 <= 6500:
            water_level = "Medium"
        else:
            water_level = "High"

        return {
            "total_etc_mm": round(total_etc_mm, 1),
            "total_volume_m3": total_volume_m3,
            "water_level": water_level,
        }

    def calculate_sowing_suitability(
        self, crop_meta: Dict[str, Any], current_date: Optional[date] = None
    ) -> float:
        """Calculates sowing window suitability score (0-100) based on current date."""
        if not current_date:
            current_date = datetime.now().date()

        curr_month = current_date.month
        sowing_months = crop_meta.get("sowing_months", [6, 7])

        if curr_month in sowing_months:
            return 95.0
        elif (curr_month - 1) in sowing_months or (curr_month + 1) in sowing_months:
            return 75.0
        else:
            return 45.0

    async def get_top_recommendations(
        self,
        db: Optional[AsyncIOMotorDatabase],
        farmer_doc: Dict[str, Any],
        language: str = "English",
        current_date: Optional[date] = None,
    ) -> List[Dict[str, Any]]:
        """
        Calculates Top 3 Crop Recommendations dynamically for the farmer.
        """
        district = farmer_doc.get("district", "Nashik")
        state = farmer_doc.get("state", "Maharashtra")
        lat = farmer_doc.get("latitude") if farmer_doc.get("latitude") is not None else 19.9975
        lon = farmer_doc.get("longitude") if farmer_doc.get("longitude") is not None else 73.7898

        # Farm Area Unit Conversion (acres -> hectares)
        farm_area_val = float(farmer_doc.get("farm_area", farmer_doc.get("land_size_ha", 2.5)))
        farm_area_unit = str(farmer_doc.get("farm_area_unit", "acres")).lower()
        if "acre" in farm_area_unit:
            farm_area_ha = farm_area_val * 0.404686
        else:
            farm_area_ha = farm_area_val

        # Fetch environmental ET0 from location weather pipeline
        et0_mm_per_day = 4.8
        try:
            weather_res = await weather_service.get_weather(db, lat, lon)
            forecast_list = weather_res.get("forecast", [])
            if forecast_list and "eto_mm" in forecast_list[0]:
                et0_mm_per_day = float(forecast_list[0]["eto_mm"])
        except Exception as e:
            print(f"[RECOMMENDATION SERVICE] Error fetching ET0: {e}")

        # 1. Fetch Market Demand Intelligence
        demand_data = await self.get_market_demand(db, district, state)

        # 2. Calculate Water Requirements across candidate crops for normalization
        crop_evaluations = []
        raw_volumes = []

        for crop_name, meta in CANDIDATE_CROP_METADATA.items():
            water_info = self.calculate_water_requirement(meta, farm_area_ha, et0_mm_per_day)
            sowing_score = self.calculate_sowing_suitability(meta, current_date)
            demand_info = demand_data.get(crop_name) or demand_data.get(meta["name"]) or {"demand_score": 80.0, "market_demand": "High"}

            raw_volumes.append(water_info["total_volume_m3"])
            crop_evaluations.append({
                "meta": meta,
                "demand_score": float(demand_info["demand_score"]),
                "market_demand": demand_info["market_demand"],
                "water_info": water_info,
                "sowing_score": sowing_score,
            })

        # Normalize Water Scores (Lower water requirement = Higher efficiency score)
        min_vol = min(raw_volumes) if raw_volumes else 1000.0
        max_vol = max(raw_volumes) if raw_volumes else 8000.0
        vol_range = max(max_vol - min_vol, 1.0)

        scored_crops = []
        for eval_item in crop_evaluations:
            meta = eval_item["meta"]
            vol = eval_item["water_info"]["total_volume_m3"]

            # Higher score for lower water volume (mapped 60 to 100)
            water_score = round(100.0 - ((vol - min_vol) / vol_range) * 40.0, 1)

            demand_score = eval_item["demand_score"]
            sowing_score = eval_item["sowing_score"]

            # Final Weighted Score Calculation
            final_score = round(
                (DEMAND_WEIGHT * demand_score) +
                (WATER_WEIGHT * water_score) +
                (SOWING_WEIGHT * sowing_score)
            )
            final_score = max(10, min(99, final_score))

            net_return_per_ha = meta["base_net_return_per_ha"]

            scored_crops.append({
                "crop": meta["name"],
                "crop_id": meta["crop_id"],
                "icon": meta["icon"],
                "score": final_score,
                "suitability_percentage": f"{final_score}%",
                "demand_score": demand_score,
                "water_score": water_score,
                "sowing_score": sowing_score,
                "market_demand": eval_item["market_demand"],
                "net_return": net_return_per_ha,
                "net_return_formatted": f"Rs. {net_return_per_ha:,}/ha",
                "water_requirement": int(vol),
                "water_requirement_unit": "m3",
                "water_requirement_formatted": f"{int(vol):,} m³",
                "water_level": eval_item["water_info"]["water_level"],
                "recommended_sowing": meta["sowing_window"],
            })

        # 3. Sort Descending by Final Score & Select Top 3
        scored_crops.sort(key=lambda x: x["score"], reverse=True)
        top_3 = scored_crops[:3]

        # Add Rank
        for rank_idx, item in enumerate(top_3, start=1):
            item["rank"] = rank_idx

        return top_3


crop_recommendation_service = CropRecommendationService()
