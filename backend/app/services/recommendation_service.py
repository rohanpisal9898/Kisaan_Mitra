"""
AI Recommendation service for Kisaan Mitra.

Architecture:
  Flutter → FastAPI → Gemini API (3-Category System)
  Category 1: Irrigation (💧)
  Category 2: Pest & Disease (🐛)
  Category 3: Fertilizer & Nutrition (🌱)

Fallback: Rich, deterministic rule engine for all 3 categories if Gemini is unavailable.
"""

from typing import Dict, Any, List, Optional
from datetime import datetime
from app.integrations.gemini import get_gemini_recommendations


class RecommendationService:
    """Generates 3 actionable, crop-aware recommendations (Irrigation, Pest/Disease, Fertilizer)."""

    def __init__(self):
        self._cache: Dict[str, Dict[str, Any]] = {}

    async def get_recommendations(
        self, farm_context: Dict[str, Any], language: str = "English"
    ) -> List[Dict[str, Any]]:
        """
        Get 3 recommendations. Tries Gemini first with strict JSON validation,
        falls back to deterministic 3-category rules.
        """
        crop = farm_context.get("crop_name", "Soyabean")
        stage = farm_context.get("crop_stage", "Flowering")
        phone = farm_context.get("phone_number", "default")
        lang_code = language.lower()[:2]

        cache_key = f"{phone}_{crop}_{stage}_{lang_code}"

        # Simple cache check (5-minute TTL)
        if cache_key in self._cache:
            entry = self._cache[cache_key]
            if (datetime.now() - entry["timestamp"]).total_seconds() < 300:
                return entry["recommendations"]

        gemini_context = {
            "crop": crop,
            "district": farm_context.get("district", "Nashik"),
            "state": farm_context.get("state", "Maharashtra"),
            "crop_stage": stage,
            "days_after_sowing": farm_context.get("days_after_sowing", 60),
            "current_month": farm_context.get("current_month", datetime.now().strftime("%B")),
            "farm_area_ha": farm_context.get("farm_area_ha", 1.5),
            "weather": farm_context.get("weather_summary", {}),
            "water_calculation": farm_context.get("water_summary", {}),
            "crop_health": farm_context.get("health_summary", {}),
            "yield": farm_context.get("yield_summary", {}),
        }

        # Try Gemini AI engine
        ai_recs = await get_gemini_recommendations(gemini_context, language)
        if ai_recs and len(ai_recs) == 3:
            self._cache[cache_key] = {
                "timestamp": datetime.now(),
                "recommendations": ai_recs,
            }
            return ai_recs

        # Fallback: Rich 3-Category Rule Engine
        fallback_recs = self._rule_based_recommendations(farm_context, language)
        self._cache[cache_key] = {
            "timestamp": datetime.now(),
            "recommendations": fallback_recs,
        }
        return fallback_recs

    def _rule_based_recommendations(
        self, ctx: Dict[str, Any], language: str = "English"
    ) -> List[Dict[str, Any]]:
        """Generate deterministic 3-category recommendations when Gemini is unavailable."""
        crop = ctx.get("crop_name", "Soyabean")
        district = ctx.get("district", "Nashik")
        water = ctx.get("water_summary", {})
        weather = ctx.get("weather_summary", {})
        stage = ctx.get("crop_stage", "Flowering")
        das = ctx.get("days_after_sowing", 60)

        irr_mm = water.get("irrigation_mm", 0.0)
        net_irr = water.get("net_irrigation_mm", irr_mm)
        rain_mm = weather.get("rain_mm", 0.0)
        water_status = water.get("status", "")

        is_hi = "hi" in language.lower() or "hindi" in language.lower()
        is_mr = "mr" in language.lower() or "marathi" in language.lower()

        recs = []

        # ─── CATEGORY 1: IRRIGATION ──────────────────────────────────────
        if net_irr <= 0 or water_status in ("rain_sufficient", "no_irrigation") or rain_mm >= 5.0:
            if is_hi:
                title = "सिंचाई की आवश्यकता नहीं"
                desc = f"हाल ही में हुई बारिश आपके {crop} की पानी की मांग के लिए पर्याप्त है। फिर से पानी देने से पहले मिट्टी की नमी जांचें।"
            elif is_mr:
                title = "सिंचनाची गरज नाही"
                desc = f"नुकताच झालेला पाऊस तुमच्या {crop} पिकासाठी पुरेसा आहे. पुन्हा पाणी देण्यापूर्वी मातीची ओल तपासा."
            else:
                title = "No Irrigation Needed"
                desc = f"Recent rainfall is sufficient for your {crop}'s water requirement. Check soil moisture before watering."

            recs.append({
                "priority": 1,
                "category": "irrigation",
                "type": "water",
                "title": title,
                "description": desc,
                "severity": "low",
                "icon": "💧",
            })
        else:
            if is_hi:
                title = f"खेत की सिंचाई करें (~{round(net_irr)} मिमी)"
                desc = f"{district} में आपके {crop} की पानी की मांग वर्षा से अधिक है। जड़ों के पास हल्की सिंचाई करें।"
            elif is_mr:
                title = f"शेताला पाणी द्या (~{round(net_irr)} मिमी)"
                desc = f"{district} मध्ये तुमच्या {crop} पिकाची पाण्याची गरज पावसापेक्षा जास्त आहे. हलके सिंचन करा."
            else:
                title = f"Irrigate Field Soon (~{round(net_irr)} mm)"
                desc = f"Water requirement for {crop} in {district} exceeds rainfall. Apply estimated irrigation."

            recs.append({
                "priority": 1,
                "category": "irrigation",
                "type": "water",
                "title": title,
                "description": desc,
                "severity": "medium",
                "icon": "💧",
            })

        # ─── CATEGORY 2: PEST / DISEASE ──────────────────────────────────
        if is_hi:
            title = f"{crop} में कीटों पर नजर रखें"
            desc = f"विकास के इस चरण (दिन {das}) में पत्तियों और नई शाखाओं पर रस चूसने वाले कीटों या धब्बों की जांच करें।"
        elif is_mr:
            title = f"{crop} वरील किडींवर लक्ष ठेवा"
            desc = f"वाढीच्या या टप्प्यावर (दिवस {das}) पानांवर आणि नव्या कोंभांवर कीड किंवा डागांची पाहणी करा."
        else:
            title = f"Monitor for Sucking Pests"
            desc = f"Inspect young leaves and shoots for aphids or leaf spots during this growth stage (Day {das})."

        recs.append({
            "priority": 2,
            "category": "pest_disease",
            "type": "crop_health",
            "title": title,
            "description": desc,
            "severity": "medium",
            "icon": "🐛",
        })

        # ─── CATEGORY 3: FERTILIZER / NUTRITION ──────────────────────────
        if stage in ("Early Growth", "Vegetative Growth"):
            if is_hi:
                title = "नाइट्रोजन की मात्रा संतुलित रखें"
                desc = f"शुरुआती बढ़वार के लिए संतुलित नाइट्रोजन और सूक्ष्म पोषक तत्व दें। अत्यधिक उर्वरक से बचें।"
            elif is_mr:
                title = "नत्र पुरवठा संतुलित ठेवा"
                desc = f"शुरुवातीच्या वाढीसाठी संतुलित नत्र आणि सूक्ष्म अन्नद्रव्ये द्या. अति खत वापरणे टाळा."
            else:
                title = "Maintain Nitrogen Supply"
                desc = f"Support early foliage growth with balanced nitrogen and micronutrients. Avoid excessive fertilizer."
        elif stage == "Flowering":
            if is_hi:
                title = "फूल आने के समय पोषण सहायता दें"
                desc = f"फूल आने की अवस्था में फॉस्फोरस और पोटाश का उचित संतुलन बनाए रखें ताकि अच्छी उपज मिल सके।"
            elif is_mr:
                title = "फुलोऱ्याच्या काळात अन्नद्रव्ये द्या"
                desc = f"फुलोऱ्याच्या टप्प्यात स्फुरद आणि पालाशचा योग्य समतोल ठेवा जेणेकरून चांगले उत्पादन मिळेल."
            else:
                title = "Support Flowering Nutrition"
                desc = f"Maintain balanced phosphorus and potassium along with nitrogen to support healthy flowering."
        else:
            if is_hi:
                title = "संतुलित पोषण बनाए रखें"
                desc = f"पकाई के चरण में पोषक तत्वों का संतुलन बनाए रखें और मिट्टी की उर्वरता का ध्यान रखें।"
            elif is_mr:
                title = "संतुलित पोषण ठेवा"
                desc = f"पक्वतेच्या टप्प्यात पिकाच्या पोषणाचा समतोल ठेवा आणि मातीचे आरोग्य जपा."
            else:
                title = "Maintain Balanced Nutrition"
                desc = f"Keep fertilizer balanced for the current growth stage and watch for nutrient deficiencies."

        recs.append({
            "priority": 3,
            "category": "fertilizer",
            "type": "crop_stage",
            "title": title,
            "description": desc,
            "severity": "low",
            "icon": "🌱",
        })

        return recs


recommendation_service = RecommendationService()
