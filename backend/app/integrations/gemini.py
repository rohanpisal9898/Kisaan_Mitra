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


SYSTEM_PROMPT = """You are Kisaan Mitra, an agricultural advisory assistant for Indian farmers.

CRITICAL RULES:
1. Explain and prioritize recommendations using ONLY the supplied farm context.
2. DO NOT INVENT or MODIFY any numbers (such as irrigation mm, yield T/Ha, temperatures, or dates). All numerical values are strictly owned by the backend.
3. If water status says 0 mm or rain covers need, DO NOT recommend applying water today.
4. Do not invent diseases or pest issues unless explicitly present in the context.
5. Return exactly 3 farmer-friendly recommendations.
6. Keep titles short and actionable (under 45 characters).
7. Keep descriptions concise (under 90 characters).
8. Use clear, farmer-friendly terms (avoid technical jargon like NDVI, Kc, ETo).
"""


async def get_gemini_recommendations(
    farm_context: Dict[str, Any],
    language: str = "English",
) -> Optional[List[Dict[str, Any]]]:
    api_key = settings.gemini_api_key
    if not api_key or api_key == "your_gemini_api_key_here":
        print("[GEMINI DEBUG] enabled=False request_success=False fallback_used=True (No API Key)")
        return None

    model_names = ["gemini-flash", "gemini-2.5-pro", "gemini-2.5-flash"]
    
    context_str = json.dumps(farm_context, indent=2, default=str)
    user_prompt = f"Farm context:\n{context_str}\n\nLanguage: {language}\n\nGenerate 3 farmer-friendly recommendations based strictly on the above context.\nReturn ONLY valid JSON."

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
                "maxOutputTokens": 800,
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
                            
                            if "```json" in text:
                                text = text.split("```json")[1].split("```")[0].strip()
                            elif "```" in text:
                                text = text.split("```")[1].split("```")[0].strip()

                            parsed = json.loads(text)
                            if isinstance(parsed, dict):
                                recommendations = parsed.get("recommendations", [])
                            elif isinstance(parsed, list):
                                recommendations = parsed
                            else:
                                recommendations = []

                            validated = []
                            for rec in recommendations[:3]:
                                validated.append({
                                    "priority": rec.get("priority", len(validated) + 1),
                                    "type": rec.get("type", "general"),
                                    "title": str(rec.get("title", ""))[:50],
                                    "description": str(rec.get("description", ""))[:100],
                                    "severity": rec.get("severity", "medium"),
                                    "icon": rec.get("icon", "💡"),
                                })

                            if validated:
                                print(f"[GEMINI DEBUG] enabled=True model_selected={model_name} request_success=True fallback_used=False")
                                return validated
                else:
                    print(f"[GEMINI DEBUG] model={model_name} HTTP {response.status_code}")
        except Exception as e:
            print(f"[GEMINI DEBUG] model={model_name} exception: {e}")
            continue

    print("[GEMINI DEBUG] enabled=True request_success=False fallback_used=True (All models failed)")
    return None
