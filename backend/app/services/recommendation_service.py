"""
AI Recommendation service.

Architecture: Flutter → FastAPI → Gemini API
Fallback: Contextual rule-based recommendations if Gemini is unavailable.
"""

from typing import Dict, Any, List
from app.integrations.gemini import get_gemini_recommendations


class RecommendationService:
    """Generates 3 actionable, contextual recommendations for the farmer."""

    async def get_recommendations(
        self, farm_context: Dict[str, Any], language: str = "English"
    ) -> List[Dict[str, Any]]:
        """
        Get 3 recommendations. Tries Gemini first, falls back to contextual rules.
        """
        gemini_context = {
            "crop": farm_context.get("crop_name", "Soyabean"),
            "district": farm_context.get("district", "Nashik"),
            "state": farm_context.get("state", "Maharashtra"),
            "crop_stage": farm_context.get("crop_stage", "Flowering"),
            "days_after_sowing": farm_context.get("days_after_sowing", 60),
            "weather": farm_context.get("weather_summary", {}),
            "water": farm_context.get("water_summary", {}),
            "crop_health": farm_context.get("health_summary", {}),
            "yield": farm_context.get("yield_summary", {}),
        }

        # Try Gemini AI engine
        ai_recs = await get_gemini_recommendations(gemini_context, language)
        if ai_recs and len(ai_recs) >= 3:
            return ai_recs[:3]

        # Fallback: Rich contextual rule engine
        return self._rule_based_recommendations(farm_context)

    def _rule_based_recommendations(self, ctx: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate rich, contextual recommendations when Gemini is unavailable."""
        recs = []
        crop = ctx.get("crop_name", "Soyabean")
        district = ctx.get("district", "Nashik")
        water = ctx.get("water_summary", {})
        weather = ctx.get("weather_summary", {})
        health = ctx.get("health_summary", {})
        yield_data = ctx.get("yield_summary", {})
        stage = ctx.get("crop_stage", "Flowering")
        das = ctx.get("days_after_sowing", 60)

        irr_mm = water.get("irrigation_mm", 0.0)
        rain_mm = weather.get("rain_mm", 0.0)
        water_status = water.get("status", "")
        health_status = health.get("status", "good")
        health_score = health.get("score")

        # 1. Water Recommendation (Contextual)
        if water_status in ("needs_soon", "irrigation_needed", "high_stress") and irr_mm > 0:
            recs.append({
                "priority": 1,
                "type": "water",
                "title": f"Irrigate ~{round(irr_mm)} mm Soon",
                "description": f"Your {crop} crop in {district} needs irrigation to maintain optimal soil moisture.",
                "severity": "high" if water_status == "high_stress" else "medium",
                "icon": "💧",
            })
        elif water_status == "rain_sufficient" or rain_mm >= 5.0:
            recs.append({
                "priority": 1,
                "type": "water",
                "title": "Hold Off Irrigation",
                "description": f"Forecasted rain (~{round(rain_mm)} mm) in {district} will cover your {crop} water demand.",
                "severity": "low",
                "icon": "🌧",
            })
        else:
            recs.append({
                "priority": 1,
                "type": "water",
                "title": "Check Soil Moisture",
                "description": f"Soil moisture is stable for {crop}. Check root zone before applying extra water.",
                "severity": "low",
                "icon": "💧",
            })

        # 2. Weather & Health Recommendation (Contextual)
        if rain_mm >= 20.0:
            recs.append({
                "priority": 2,
                "type": "weather",
                "title": f"Ensure Field Drainage",
                "description": f"Heavy rain ({round(rain_mm)} mm) expected in {district}. Clear channels to prevent waterlogging.",
                "severity": "high",
                "icon": "🌧",
            })
        elif health_status in ("watch", "needs_attention", "poor"):
            recs.append({
                "priority": 2,
                "type": "crop_health",
                "title": f"Inspect {crop} Health",
                "description": f"Health score is {health_score or 'Watch'}. Check field for pest or nutrient deficiency.",
                "severity": "medium",
                "icon": "🌿",
            })
        else:
            recs.append({
                "priority": 2,
                "type": "weather",
                "title": f"Rain Forecast ({round(rain_mm)} mm)",
                "description": f"Light to moderate rainfall expected in {district}. Delay chemical sprays during rain.",
                "severity": "low",
                "icon": "🌤",
            })

        # 3. Growth Stage & Yield Recommendation (Contextual)
        if stage == "Early Growth":
            recs.append({
                "priority": 3,
                "type": "crop_stage",
                "title": "Protect Early Germination",
                "description": f"Day {das}: Maintain moist seedbed and watch for seedling pests in {crop}.",
                "severity": "medium",
                "icon": "🌱",
            })
        elif stage == "Vegetative Growth":
            recs.append({
                "priority": 3,
                "type": "crop_stage",
                "title": "Support Vegetative Growth",
                "description": f"Day {das}: Apply recommended nitrogen top-dressing to build strong foliage.",
                "severity": "medium",
                "icon": "🌿",
            })
        elif stage == "Flowering":
            recs.append({
                "priority": 3,
                "type": "crop_stage",
                "title": "Protect Flowering Stage",
                "description": f"Day {das}: Flowering is critical for yield ({yield_data.get('predicted', 3.4)} T/Ha expected). Avoid water stress.",
                "severity": "high",
                "icon": "🌼",
            })
        else:
            recs.append({
                "priority": 3,
                "type": "crop_stage",
                "title": "Prepare for Harvest",
                "description": f"Day {das}: Crop is reaching maturity. Monitor pod/seed dryness before harvesting.",
                "severity": "medium",
                "icon": "🌾",
            })

        return recs[:3]


recommendation_service = RecommendationService()
