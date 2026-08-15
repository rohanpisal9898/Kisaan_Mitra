"""
Google Gemini integration for AI recommendations using direct HTTP REST API.

Architecture:
  Backend Deterministic Engines (Water, Weather, Stage, Health, Yield) OWN ALL NUMBERS.
  Gemini ONLY owns farmer-friendly wording, clear explanations, and prioritization.
  Gemini MUST NOT invent or alter any numerical values (irrigation mm, yield T/Ha, temperature, etc.).

Uses httpx for zero-dependency execution across Python versions.
"""

import json
import httpx
from typing import Optional, Dict, Any, List
from app.config import get_settings

settings = get_settings()


SYSTEM_PROMPT = """You are Kisaan Mitra, an expert agricultural advisory assistant for Indian farmers.

CRITICAL RULES:
1. Generate EXACTLY 3 recommendations, one for each of the following 3 fixed categories IN ORDER:
   Category 1: "irrigation"
   Category 2: "pest_disease"
   Category 3: "fertilizer"

2. CATEGORY 1 (irrigation):
   - Based strictly on calculated net irrigation requirement (net_irrigation_mm) and forecast rain.
   - If net_irrigation_mm is 0 or rain is sufficient, DO NOT tell the farmer to irrigate today! Say "No irrigation needed", "Hold off irrigation", or "Check soil moisture".
   - If net_irrigation_mm > 0, give clear irrigation guidance.

3. CATEGORY 2 (pest_disease):
   - Recommend pest & disease monitoring based on crop, stage, month, weather, and location.
   - Frame as "Watch for...", "Monitor for...", "Inspect leaves for...", or "Check for...".
   - DO NOT claim a disease or pest exists unless explicitly stated in context.

4. CATEGORY 3 (fertilizer):
   - Recommend growth-stage appropriate fertilizer and nutrition management (e.g. "Maintain nitrogen supply", "Support flowering nutrition").
   - Explain what nutrient the crop needs now or what deficiency to watch for in simple farmer language.

5. GENERAL RULES:
   - DO NOT repeat existing dashboard state (e.g. don't just say "Observe Crop Health", give specific action guidance like "Watch for aphids").
   - Keep titles short and actionable (under 50 characters).
   - Keep descriptions concise and practical (under 120 characters).
   - Return ONLY valid JSON in the requested language.

REQUIRED JSON OUTPUT FORMAT:
{
  "recommendations": [
    {
      "category": "irrigation",
      "priority": 1,
      "type": "water",
      "title": "Short actionable title in requested language",
      "description": "Short explanation in requested language",
      "icon": "💧"
    },
    {
      "category": "pest_disease",
      "priority": 2,
      "type": "crop_health",
      "title": "Short actionable title in requested language",
      "description": "Short explanation in requested language",
      "icon": "🐛"
    },
    {
      "category": "fertilizer",
      "priority": 3,
      "type": "crop_stage",
      "title": "Short actionable title in requested language",
      "description": "Short explanation in requested language",
      "icon": "🌱"
    }
  ]
}
"""


def _clean_and_parse_json(text: str) -> Any:
    text = text.strip()
    if "```json" in text:
        text = text.split("```json")[1].split("```")[0].strip()
    elif "```" in text:
        text = text.split("```")[1].split("```")[0].strip()

    try:
        return json.loads(text)
    except Exception:
        pass

    import re
    # Extract json block if surrounded by prose
    match = re.search(r"(\[.*\]|\{.*\})", text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except Exception:
            pass

    # Convert single-quoted keys/strings if valid json parsing fails
    sanitized = re.sub(r"'", '"', text)
    return json.loads(sanitized)


async def get_gemini_recommendations(
    farm_context: Dict[str, Any],
    language: str = "English",
) -> Optional[List[Dict[str, Any]]]:
    api_key = settings.gemini_api_key
    if not api_key or api_key == "your_gemini_api_key_here":
        print("[GEMINI DEBUG] enabled=False request_success=False fallback_used=True (No API Key)")
        return None

    model_names = [
        "gemini-3.1-flash-lite",
        "gemini-3.5-flash-lite",
        "gemini-flash-lite-latest",
        "gemini-3.6-flash",
        "gemini-2.5-flash",
    ]

    context_str = json.dumps(farm_context, indent=2, default=str)
    user_prompt = (
        f"Farm context:\n{context_str}\n\n"
        f"Language requested: {language}\n\n"
        f"Generate exactly 3 structured recommendations for categories [irrigation, pest_disease, fertilizer] in {language}.\n"
        f"Return ONLY valid JSON matching the specified format."
    )

    full_text_prompt = f"{SYSTEM_PROMPT}\n\n{user_prompt}"

    for model_name in model_names:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={api_key}"
        payload = {
            "contents": [
                {
                    "parts": [
                        {"text": full_text_prompt}
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0.2,
                "maxOutputTokens": 2048,
                "responseMimeType": "application/json",
            }
        }

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(url, json=payload)
                if response.status_code == 200:
                    res_json = response.json()
                    candidates = res_json.get("candidates", [])
                    if candidates and "content" in candidates[0]:
                        parts = candidates[0]["content"].get("parts", [])
                        if parts and "text" in parts[0]:
                            text = parts[0]["text"].strip()
                            parsed = _clean_and_parse_json(text)
                            if isinstance(parsed, dict):
                                recommendations = parsed.get("recommendations", [])
                            elif isinstance(parsed, list):
                                recommendations = parsed
                            else:
                                recommendations = []

                            validated = []
                            seen_categories = set()

                            required_categories = ["irrigation", "pest_disease", "fertilizer"]
                            default_icons = {
                                "irrigation": "💧",
                                "pest_disease": "🐛",
                                "fertilizer": "🌱",
                            }
                            default_types = {
                                "irrigation": "water",
                                "pest_disease": "crop_health",
                                "fertilizer": "crop_stage",
                            }

                            for rec in recommendations:
                                cat = str(rec.get("category", "")).lower().strip()
                                if cat not in required_categories:
                                    # Fallback mapping if Gemini returned type or variant
                                    t = str(rec.get("type", "")).lower()
                                    if "water" in t or "irrigation" in t:
                                        cat = "irrigation"
                                    elif "pest" in t or "disease" in t or "health" in t:
                                        cat = "pest_disease"
                                    elif "fert" in t or "nutrit" in t or "stage" in t:
                                        cat = "fertilizer"

                                if cat in required_categories and cat not in seen_categories:
                                    title = str(rec.get("title", "")).strip()
                                    desc = str(rec.get("description", "")).strip()
                                    if title and desc:
                                        seen_categories.add(cat)
                                        validated.append({
                                            "priority": len(validated) + 1,
                                            "category": cat,
                                            "type": rec.get("type", default_types[cat]),
                                            "title": title[:60],
                                            "description": desc[:140],
                                            "severity": rec.get("severity", "medium"),
                                            "icon": default_icons[cat],
                                        })

                            # Must have all 3 distinct required categories
                            if len(validated) == 3 and len(seen_categories) == 3:
                                print(f"[GEMINI DEBUG] enabled=True model_selected={model_name} request_success=True fallback_used=False")
                                return validated
                            else:
                                print(f"[GEMINI DEBUG] model={model_name} validation failed: categories found={seen_categories}")
                else:
                    print(f"[GEMINI DEBUG] model={model_name} HTTP {response.status_code} Body: {response.text[:200]}")
        except Exception as e:
            print(f"[GEMINI DEBUG] model={model_name} exception: {e}")
            continue

    print("[GEMINI DEBUG] enabled=True request_success=False fallback_used=True (All models failed validation or API call)")
    return None
