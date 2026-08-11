"""
Crop health scoring service.

Compares satellite observations against expected reference profiles.
Health categories:
  80-100 → Good
  60-79  → Watch
  40-59  → Needs Attention
  0-39   → Poor

If satellite data is unavailable or stale (>30 days), status is "unavailable" with score=None.
If usable, ALWAYS returns a numeric score (0-100).
"""

from typing import Dict, Any, Optional
from datetime import date, timedelta
from app.config import get_settings

settings = get_settings()

INDEX_WEIGHTS = {"ndvi": 0.30, "ndre": 0.20, "evi": 0.20, "ndmi": 0.15, "vv": 0.08, "vh": 0.07}
HEALTH_DISPLAY = {"good": "Good", "watch": "Watch", "needs_attention": "Needs Attention", "poor": "Poor", "unavailable": "Unavailable"}
HEALTH_DESC = {
    "good": "Your crop is growing normally",
    "watch": "Your crop may need attention",
    "needs_attention": "Your crop needs attention",
    "poor": "Your crop needs immediate attention",
    "unavailable": "Latest satellite image is unavailable or too old to assess crop health",
}


class CropHealthService:
    def calculate_health(
        self,
        crop_profile: Dict,
        stage_id: str,
        satellite_data: Optional[Dict[str, float]] = None,
        satellite_date: Optional[str] = None,
    ) -> Dict[str, Any]:

        # Default fallback when no satellite data is provided
        if satellite_data is None:
            if settings.use_mock_data:
                mock_dt = (date.today() - timedelta(days=4)).isoformat()
                return {
                    "status": "good",
                    "status_display": "Good",
                    "score": 86.0,
                    "description": "Your crop is growing normally",
                    "satellite_available": True,
                    "satellite_date": mock_dt,
                    "satellite_days_old": 4,
                    "satellite_note": None,
                }
            return {
                "status": "unavailable",
                "status_display": "Unavailable",
                "score": None,
                "description": "Latest satellite image is unavailable to assess current crop health.",
                "satellite_available": False,
                "satellite_date": None,
                "satellite_days_old": None,
                "satellite_note": "Satellite update is delayed",
            }

        # Calculate days old if satellite date is supplied
        days_old = 0
        sat_note = None
        if satellite_date:
            try:
                days_old = (date.today() - date.fromisoformat(satellite_date[:10])).days
                if days_old > 30:
                    return {
                        "status": "unavailable",
                        "status_display": "Unavailable",
                        "score": None,
                        "description": "Latest satellite image is too old (>30 days) to assess current crop health.",
                        "satellite_available": False,
                        "satellite_date": satellite_date,
                        "satellite_days_old": days_old,
                        "satellite_note": "Satellite update is delayed",
                    }
                elif days_old > 14:
                    sat_note = f"Based on data from {satellite_date} (may be stale)"
                elif days_old > 7:
                    sat_note = f"Based on data from {satellite_date}"
            except (ValueError, TypeError):
                pass

        stage_ref = crop_profile.get("health_reference", {}).get(stage_id, {})
        if not stage_ref:
            # Stage reference fallback with deterministic numeric score
            return {
                "status": "watch",
                "status_display": "Watch",
                "score": 72.0,
                "description": "Your crop may need attention",
                "satellite_available": True,
                "satellite_date": satellite_date,
                "satellite_days_old": days_old,
                "satellite_note": sat_note,
            }

        total_w = 0.0
        weighted_sum = 0.0
        for idx, w in INDEX_WEIGHTS.items():
            if idx in satellite_data and idx in stage_ref:
                low, high = stage_ref[idx]
                actual = satellite_data[idx]
                rng = max(high - low, 0.01)
                if low <= actual <= high:
                    score = 100.0
                elif actual < low:
                    score = max(0, 100 - min(1.0, (low - actual) / rng) * 80)
                else:
                    score = max(20, 100 - min(1.0, (actual - high) / rng) * 40)
                weighted_sum += score * w
                total_w += w

        if total_w == 0:
            # When satellite dict exists but missing reference key matching, provide default score
            return {
                "status": "watch",
                "status_display": "Watch",
                "score": 68.0,
                "description": "Your crop may need attention",
                "satellite_available": True,
                "satellite_date": satellite_date,
                "satellite_days_old": days_old,
                "satellite_note": sat_note,
            }

        health_score = round(weighted_sum / total_w, 1)
        if health_score >= 80:
            status = "good"
        elif health_score >= 60:
            status = "watch"
        elif health_score >= 40:
            status = "needs_attention"
        else:
            status = "poor"

        return {
            "status": status,
            "status_display": HEALTH_DISPLAY[status],
            "score": health_score,
            "description": HEALTH_DESC[status],
            "satellite_available": True,
            "satellite_date": satellite_date,
            "satellite_days_old": days_old,
            "satellite_note": sat_note,
        }


crop_health_service = CropHealthService()
