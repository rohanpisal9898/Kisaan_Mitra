import httpx
import json

api_key = "AQ.Ab8RN6Kkgu0nf3LjCAL9myYGQNruObQ6AkUYfoKmPUd67f10TA"
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"

prompt = """You are Kisaan Mitra. Return a JSON array of 3 farmer recommendations for Rapeseed & Mustard in JHUNJHUNU.
Format:
[
  {"priority": 1, "type": "water", "title": "Hold Off Irrigation", "description": "Forecasted rain will cover crop water demand.", "severity": "low", "icon": "🌧"},
  {"priority": 2, "type": "weather", "title": "Rain Forecast", "description": "Light rain expected. Delay chemical sprays.", "severity": "medium", "icon": "🌤"},
  {"priority": 3, "type": "health", "title": "Protect Germination", "description": "Maintain seedbed moisture and watch for pests.", "severity": "medium", "icon": "🌱"}
]
Return ONLY valid raw JSON array."""

payload = {
    "contents": [{"parts": [{"text": prompt}]}],
    "generationConfig": {
        "temperature": 0.2,
        "maxOutputTokens": 2048,
        "responseMimeType": "application/json"
    }
}

res = httpx.post(url, json=payload, timeout=10.0)
print("Status:", res.status_code)
if res.status_code == 200:
    res_json = res.json()
    text = res_json["candidates"][0]["content"]["parts"][0]["text"]
    print("Raw text returned by Gemini:")
    print(text)
    print("Parsed JSON successfully:", json.loads(text))
else:
    print("Error:", res.text)
