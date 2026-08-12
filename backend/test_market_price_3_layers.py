import asyncio
import json
from datetime import datetime
from app.services.wallet_service import wallet_service
from app.integrations.gemini import settings

class MockMongoCollection:
    def __init__(self):
        self.docs = {}

    async def find_one(self, query, sort=None):
        crop = query.get("crop")
        state = query.get("state")
        key = f"{crop}_{state}" if state else crop
        return self.docs.get(key) or self.docs.get(crop)

    def find(self, query):
        class MockCursor:
            def __init__(self, docs):
                self._docs = docs
            async def to_list(self, length=100):
                return list(self._docs.values())
        return MockCursor(self.docs)

    async def update_one(self, query, update, upsert=False):
        crop = query.get("crop")
        state = query.get("state")
        key = f"{crop}_{state}" if state else crop
        doc = update.get("$set", {})
        self.docs[key] = doc
        return True

    def delete_all(self):
        self.docs.clear()

class MockMongoDB:
    def __init__(self):
        self.market_price_cache = MockMongoCollection()
        self.mandi_prices = MockMongoCollection()
        self.users = MockMongoCollection()
        self.user_expenses = MockMongoCollection()

async def test_3_layers():
    print("======================================================================")
    print("  TESTING & PROVING ALL 3 MARKET PRICE ARCHITECTURE LAYERS")
    print("======================================================================")

    db = MockMongoDB()
    crop = "Rapeseed &Mustard"
    state = "Rajasthan"

    # ------------------------------------------------------------------
    # LAYER 1: GEMINI LIVE FETCH (source: "gemini")
    # ------------------------------------------------------------------
    print("\n--- LAYER 1: Gemini Live Price Fetch ---")
    res_l1 = await wallet_service.get_mandi_price_with_fallback(db, state, crop)
    print(f"   Crop        : {crop}")
    print(f"   Modal Price : Rs. {res_l1.get('modal_price')}/quintal")
    print(f"   Source      : {res_l1.get('source')}")
    print(f"   Fetched At  : {res_l1.get('fetched_at')}")

    assert res_l1.get("source") == "gemini", f"Expected source='gemini', got {res_l1.get('source')}"
    assert res_l1.get("modal_price", 0) > 0, "Modal price must be > 0"
    
    # Check MongoDB persistent cache document
    cache_doc = await db.market_price_cache.find_one({"crop": crop, "state": state})
    assert cache_doc is not None, "MongoDB cache document must be created"
    assert cache_doc.get("source") == "gemini", "MongoDB document must retain source='gemini'"
    print("   [PASS] LAYER 1 PROVED: Gemini live fetch succeeded & saved to MongoDB cache!")

    # ------------------------------------------------------------------
    # LAYER 2: GEMINI UNAVAILABLE -> MONGODB CACHE FALLBACK (source: "cached")
    # ------------------------------------------------------------------
    print("\n--- LAYER 2: Gemini Unavailable -> MongoDB Cache Fallback ---")
    # Temporarily disable Gemini API key to simulate Gemini API downtime
    original_key = settings.gemini_api_key
    settings.gemini_api_key = ""

    try:
        res_l2 = await wallet_service.get_mandi_price_with_fallback(db, state, crop)
        print(f"   Modal Price : Rs. {res_l2.get('modal_price')}/quintal")
        print(f"   Source      : {res_l2.get('source')}")
        print(f"   Fetched At  : {res_l2.get('fetched_at')}")

        assert res_l2.get("source") == "cached", f"Expected source='cached', got {res_l2.get('source')}"
        assert res_l2.get("modal_price") == res_l1.get("modal_price"), "Cached price must equal previously Gemini-fetched price!"
        print("   [PASS] LAYER 2 PROVED: Returned exact Gemini-fetched price from MongoDB cache!")
    finally:
        settings.gemini_api_key = original_key

    # ------------------------------------------------------------------
    # LAYER 3: CACHE CLEARED & GEMINI UNAVAILABLE -> BENCHMARK DEFAULT (source: "default")
    # ------------------------------------------------------------------
    print("\n--- LAYER 3: Cache Empty & Gemini Unavailable -> Benchmark Default ---")
    db.market_price_cache.delete_all()
    settings.gemini_api_key = ""

    try:
        res_l3 = await wallet_service.get_mandi_price_with_fallback(db, state, crop)
        print(f"   Modal Price : Rs. {res_l3.get('modal_price')}/quintal")
        print(f"   Source      : {res_l3.get('source')}")
        print(f"   Fetched At  : {res_l3.get('fetched_at')}")

        assert res_l3.get("source") == "default", f"Expected source='default', got {res_l3.get('source')}"
        assert res_l3.get("modal_price") == 5440.0, f"Expected default price 5440.0, got {res_l3.get('modal_price')}"
        print("   [PASS] LAYER 3 PROVED: Returned default benchmark price when cache is empty and Gemini fails!")
    finally:
        settings.gemini_api_key = original_key

    print("\n======================================================================")
    print("  [SUCCESS] ALL 3 MARKET PRICE ARCHITECTURE LAYERS VERIFIED & PROVED!")
    print("======================================================================")

if __name__ == "__main__":
    asyncio.run(test_3_layers())
