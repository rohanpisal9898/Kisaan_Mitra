import asyncio
import httpx
import json
from app.integrations.gemini import settings, _clean_and_parse_json

async def run():
    api_key = settings.gemini_api_key
    models = ["gemini-2.5-pro", "gemini-flash-latest", "gemini-3.6-flash", "gemma-4-31b-it", "gemini-2.5-flash"]
    prompt = (
        "Provide current estimated APMC mandi market price for crop 'Rapeseed &Mustard' in 'Rajasthan', India in INR per quintal.\n"
        "Return ONLY valid JSON in this exact structure:\n"
        '{"crop": "Rapeseed &Mustard", "state": "Rajasthan", "modal_price": 5820, "floor_price": 5400, "ceiling_price": 6100, "market": "Rajasthan Mandi", "unit": "Rs/Quintal"}'
    )
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 1024,
            "responseMimeType": "application/json",
        }
    }
    for m in models:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{m}:generateContent?key={api_key}"
        print(f"\n--- Testing model: {m} ---")
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(url, json=payload)
                print("Status Code:", resp.status_code)
                if resp.status_code == 200:
                    res_json = resp.json()
                    text = res_json["candidates"][0]["content"]["parts"][0]["text"]
                    parsed = _clean_and_parse_json(text)
                    print("SUCCESS! Parsed:", parsed)
                    break
                else:
                    print("Body:", resp.text[:250])
        except Exception as e:
            print("Exception:", e)

asyncio.run(run())
