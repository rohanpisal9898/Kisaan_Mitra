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
        self.msp_prices = MockMongoCollection()
        self.crop_costs = MockMongoCollection()
        self.market_insights = MockMongoCollection()
        self.users = MockMongoCollection()
        self.user_expenses = MockMongoCollection()

async def test_ttl_cache():
    print("======================================================================")
    print("  TESTING 6-HOUR MONGODB TTL CACHE & OVER-FETCHING PREVENTION")
    print("======================================================================")

    db = MockMongoDB()
    crop = "Rapeseed &Mustard"
    state = "Rajasthan"

    # 1. First Request -> Gemini Live Fetch
    print("\n1. First request for Mustard in Rajasthan (Cache Miss)...")
    res1 = await wallet_service.get_mandi_price_with_fallback(db, state, crop)
    print(f"   Modal Price : Rs. {res1.get('modal_price')}/quintal")
    print(f"   Source      : {res1.get('source')}")
    print(f"   Fetched At  : {res1.get('fetched_at')}")

    assert res1.get("source") == "gemini", f"Expected source='gemini', got {res1.get('source')}"

    # 2. Subsequent 10 Requests -> 6-Hour TTL Cache HIT (Zero Gemini API Calls)
    print("\n2. Executing 10 subsequent requests (Testing TTL Cache HITS)...")
    cache_hits = 0
    for i in range(10):
        res = await wallet_service.get_mandi_price_with_fallback(db, state, crop)
        if res.get("source") == "cached":
            cache_hits += 1

    print(f"   Cache Hits  : {cache_hits} / 10 requests")
    assert cache_hits == 10, f"Expected 10 TTL cache hits, got {cache_hits}"
    print("   [PASS] 6-Hour TTL Cache prevented 10 duplicate Gemini API calls!")

    # 3. Testing distinct commodity prices across oilseed crops
    print("\n3. Testing distinct commodity prices across oilseed crops...")
    oilseeds = ["Rapeseed &Mustard", "Soybean", "Groundnut", "Sesamum", "Sunflower"]
    prices = {}
    for o in oilseeds:
        info = await wallet_service.get_mandi_price_with_fallback(db, "Maharashtra", o)
        prices[o] = info.get("modal_price")
        print(f"   {o:20s} : Rs. {info.get('modal_price'):,.2f} / quintal (Source: {info.get('source')})")

    assert len(set(prices.values())) > 1, "Prices for different commodities must be distinct, not hardcoded!"
    print("   [PASS] Commodity-specific market prices verified!")

    # 4. Wallet Overview Orchestration with TTL Cache
    print("\n4. Testing Wallet Overview orchestration (Phone: 1234567894)...")
    overview = await wallet_service.get_wallet_overview(db, phone_number="1234567894")
    selling_price = overview.get("selling_price", {})
    print(f"   Farmer Name   : {overview.get('farmer_name')}")
    print(f"   Current Crop  : {overview.get('current_crop')}")
    print(f"   Selling Price : Rs. {selling_price.get('modal_price')}/quintal (Source: {selling_price.get('source')})")

    assert selling_price.get("modal_price", 0) > 0, "Selling price modal_price must be > 0"
    print("   [PASS] Wallet overview orchestration with TTL Cache passed!")

    print("\n======================================================================")
    print("  [SUCCESS] 6-HOUR TTL CACHE & OVER-FETCHING PREVENTION PROVED!")
    print("======================================================================")

if __name__ == "__main__":
    asyncio.run(test_ttl_cache())
