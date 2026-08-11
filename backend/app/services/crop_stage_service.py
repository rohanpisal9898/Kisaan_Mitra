"""
Crop stage calculation service.

Determines canonical growth stage from:
  crop_profile + sowing_date + current_date

Calculates 4 canonical farmer-facing stages:
  1. Early Growth (initial, stage_id="early_growth", index=0)
  2. Vegetative Growth (development, stage_id="vegetative", index=1)
  3. Flowering (mid_season, stage_id="flowering", index=2)
  4. Maturity (late_season, stage_id="maturity", index=3)
"""

from datetime import date, datetime
from typing import Optional, Dict, Any
from motor.motor_asyncio import AsyncIOMotorDatabase


# Canonical 4 farmer-facing stage mappings
STAGE_MAP = {
    "initial": {"id": "early_growth", "name": "Early Growth", "icon": "🌱", "index": 0},
    "development": {"id": "vegetative", "name": "Vegetative Growth", "icon": "🌿", "index": 1},
    "mid_season": {"id": "flowering", "name": "Flowering", "icon": "🌼", "index": 2},
    "late_season": {"id": "maturity", "name": "Maturity", "icon": "🌾", "index": 3},
}


class CropStageService:
    """Calculates crop growth stage from sowing date and crop profile."""

    async def get_crop_profile(
        self, db: AsyncIOMotorDatabase, crop_id: str
    ) -> Optional[Dict[str, Any]]:
        normalized = self._normalize_crop_id(crop_id)
        if db is not None:
            profile = await db.crop_profiles.find_one({"crop_id": normalized})
            if profile:
                return profile
        
        return self._fallback_crop_profile(normalized)

    def _fallback_crop_profile(self, crop_id: str) -> Dict[str, Any]:
        """Agronomic stage durations for all 9 oilseed crops"""
        crop_configs = {
            "groundnut": {"growth_duration_days": 120, "stages": {"initial": 25, "development": 35, "mid_season": 40, "late_season": 20}, "kc": {"initial": 0.40, "mid": 1.15, "end": 0.60}},
            "soybean": {"growth_duration_days": 104, "stages": {"initial": 16, "development": 28, "mid_season": 40, "late_season": 20}, "kc": {"initial": 0.35, "mid": 1.15, "end": 0.50}},
            "castor": {"growth_duration_days": 150, "stages": {"initial": 25, "development": 40, "mid_season": 55, "late_season": 30}, "kc": {"initial": 0.35, "mid": 1.15, "end": 0.55}},
            "sunflower": {"growth_duration_days": 120, "stages": {"initial": 20, "development": 35, "mid_season": 45, "late_season": 20}, "kc": {"initial": 0.35, "mid": 1.15, "end": 0.35}},
            "sesame": {"growth_duration_days": 100, "stages": {"initial": 20, "development": 25, "mid_season": 35, "late_season": 20}, "kc": {"initial": 0.35, "mid": 1.10, "end": 0.25}},
            "rapeseed_mustard": {"growth_duration_days": 130, "stages": {"initial": 20, "development": 35, "mid_season": 50, "late_season": 25}, "kc": {"initial": 0.35, "mid": 1.10, "end": 0.35}},
            "linseed": {"growth_duration_days": 140, "stages": {"initial": 25, "development": 35, "mid_season": 50, "late_season": 30}, "kc": {"initial": 0.35, "mid": 1.10, "end": 0.25}},
            "safflower": {"growth_duration_days": 140, "stages": {"initial": 25, "development": 35, "mid_season": 50, "late_season": 30}, "kc": {"initial": 0.35, "mid": 1.10, "end": 0.25}},
            "niger": {"growth_duration_days": 110, "stages": {"initial": 20, "development": 30, "mid_season": 40, "late_season": 20}, "kc": {"initial": 0.35, "mid": 1.05, "end": 0.30}, "kc_status": "provisional_proxy", "kc_confidence": "low"},
        }
        cfg = crop_configs.get(crop_id, crop_configs["soybean"])
        return {
            "crop_id": crop_id,
            "growth_duration_days": cfg["growth_duration_days"],
            "stages": cfg["stages"],
            "kc": cfg["kc"],
            "kc_status": cfg.get("kc_status", "established"),
            "kc_confidence": cfg.get("kc_confidence", "high"),
        }

    def _normalize_crop_id(self, crop_name: str) -> str:
        name_lower = crop_name.lower().strip()

        mapping = {
            "groundnut": "groundnut",
            "soyabean": "soybean",
            "soybean": "soybean",
            "soya bean": "soybean",
            "castor seed": "castor",
            "castor": "castor",
            "sunflower": "sunflower",
            "sesamum": "sesame",
            "sesame": "sesame",
            "til": "sesame",
            "rapeseed & mustard": "rapeseed_mustard",
            "rapeseed &mustard": "rapeseed_mustard",
            "rapeseed and mustard": "rapeseed_mustard",
            "rapeseed": "rapeseed_mustard",
            "mustard": "rapeseed_mustard",
            "sarson": "rapeseed_mustard",
            "linseed": "linseed",
            "flax": "linseed",
            "safflower": "safflower",
            "niger seed": "niger",
            "niger": "niger",
            "ramtil": "niger",
        }

        return mapping.get(name_lower, name_lower)

    def _parse_sowing_date(self, sowing_date_val: Any) -> Optional[date]:
        """Robust date parsing for multiple formats"""
        if isinstance(sowing_date_val, date):
            return sowing_date_val
        if isinstance(sowing_date_val, datetime):
            return sowing_date_val.date()
        
        val_str = str(sowing_date_val).strip()
        if not val_str:
            return None

        # ISO format: 2026-06-15 or 2026-06-15T00:00:00
        try:
            return date.fromisoformat(val_str[:10])
        except Exception:
            pass

        # Try common date formats
        formats = [
            "%Y-%m-%d", "%d-%m-%Y", "%d/%m/%Y", "%Y/%m/%d",
            "%d %b %Y", "%d %B %Y", "%b %d, %Y", "%B %d, %Y"
        ]
        for fmt in formats:
            try:
                return datetime.strptime(val_str, fmt).date()
            except Exception:
                continue

        print(f"[WARNING] Could not parse sowing date: '{sowing_date_val}'")
        return None

    def calculate_stage(
        self,
        crop_profile: Dict[str, Any],
        sowing_date_input: Any,
        current_date: Optional[date] = None,
    ) -> Dict[str, Any]:
        if current_date is None:
            current_date = date.today()

        sowing_date = self._parse_sowing_date(sowing_date_input)
        crop_id = crop_profile.get("crop_id", "soybean")

        # Missing date
        if sowing_date is None:
            m = STAGE_MAP["initial"]
            print(f"[CROP STAGE DEBUG] crop_id={crop_id} sowing_date_raw={sowing_date_input} sowing_date_parsed=None today={current_date} days_after_sowing=0 stage_id={m['id']} stage_name={m['name']} stage_index={m['index']} (MISSING_DATE)")
            return {
                "stage_id": m["id"],
                "stage_name": m["name"],
                "stage_display": m["name"],
                "stage_icon": m["icon"],
                "stage_index": m["index"],
                "days_after_sowing": 0,
                "total_duration": crop_profile.get("growth_duration_days", 104),
                "progress_fraction": 0.0,
                "status": "missing_date",
            }

        # Future sowing date
        if sowing_date > current_date:
            m = STAGE_MAP["initial"]
            print(f"[CROP STAGE DEBUG] crop_id={crop_id} sowing_date_raw={sowing_date_input} sowing_date_parsed={sowing_date} today={current_date} days_after_sowing=0 stage_id={m['id']} stage_name={m['name']} stage_index={m['index']} (FUTURE_DATE)")
            return {
                "stage_id": m["id"],
                "stage_name": m["name"],
                "stage_display": m["name"],
                "stage_icon": m["icon"],
                "stage_index": m["index"],
                "days_after_sowing": 0,
                "total_duration": crop_profile.get("growth_duration_days", 104),
                "progress_fraction": 0.0,
                "status": "not_started",
            }

        days_after_sowing = (current_date - sowing_date).days
        total_duration = crop_profile.get("growth_duration_days", 104)

        stages = crop_profile.get("stages", {})
        initial_days = stages.get("initial", 16)
        dev_days = stages.get("development", 28)
        mid_days = stages.get("mid_season", 40)

        if days_after_sowing <= initial_days:
            key = "initial"
        elif days_after_sowing <= initial_days + dev_days:
            key = "development"
        elif days_after_sowing <= initial_days + dev_days + mid_days:
            key = "mid_season"
        else:
            key = "late_season"

        m = STAGE_MAP[key]
        progress = min(1.0, days_after_sowing / max(total_duration, 1))

        status = "on_track"
        if days_after_sowing > total_duration:
            status = "matured"

        print(f"[CROP STAGE DEBUG] crop_id={crop_id} sowing_date_raw={sowing_date_input} sowing_date_parsed={sowing_date} today={current_date} days_after_sowing={days_after_sowing} stage_id={m['id']} stage_name={m['name']} stage_index={m['index']}")

        return {
            "stage_id": m["id"],
            "stage_name": m["name"],
            "stage_display": m["name"],
            "stage_icon": m["icon"],
            "stage_index": m["index"],
            "days_after_sowing": days_after_sowing,
            "total_duration": total_duration,
            "progress_fraction": round(progress, 3),
            "status": status,
        }


# Singleton
crop_stage_service = CropStageService()
