import asyncio
import httpx
import json

async def run():
    api_key = "AQ.Ab8RN6Kkgu0nf3LjCAL9myYGQNruObQ6AkUYfoKmPUd67f10TA"
    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
    res = httpx.get(url, timeout=10.0)
    models = [m["name"].replace("models/", "") for m in res.json().get("models", []) if "generateContent" in m.get("supportedGenerationMethods", [])]
    print("Found", len(models), "models.")
    
    prompt = '{"crop": "Rapeseed &Mustard", "state": "Rajasthan", "modal_price": 5820}'
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.2, "maxOutputTokens": 100, "responseMimeType": "application/json"}
    }

    for m in models:
        m_url = f"https://generativelanguage.googleapis.com/v1beta/models/{m}:generateContent?key={api_key}"
        try:
            async with httpx.AsyncClient(timeout=4.0) as client:
                r = await client.post(m_url, json=payload)
                if r.status_code == 200:
                    print(f"SUCCESS model={m} -> {r.json()['candidates'][0]['content']['parts'][0]['text'].strip()}")
                else:
                    print(f"FAILED model={m} code={r.status_code}")
        except Exception as e:
            print(f"ERROR model={m} err={e}")

asyncio.run(run())
