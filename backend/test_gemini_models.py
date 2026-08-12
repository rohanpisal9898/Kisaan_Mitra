import httpx
import json

api_key = "AQ.Ab8RN6Kkgu0nf3LjCAL9myYGQNruObQ6AkUYfoKmPUd67f10TA"
url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"

try:
    res = httpx.get(url, timeout=10.0)
    print("Status:", res.status_code)
    if res.status_code == 200:
        models = res.json().get("models", [])
        print("Available models:")
        for m in models:
            name = m.get("name")
            methods = m.get("supportedGenerationMethods", [])
            if "generateContent" in methods:
                print("  -", name.replace("models/", ""))
    else:
        print("Error Response:", res.text)
except Exception as e:
    print("Exception:", e)
