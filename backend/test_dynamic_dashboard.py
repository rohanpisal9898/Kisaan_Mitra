import asyncio
from datetime import date
from app.services.dashboard_service import dashboard_service
from app.services.user_service import user_service
from app.models.user import UserRegisterRequest, UserUpdateRequest

class MockMongoCollection:
    def __init__(self):
        self.docs = {}

    async def find_one(self, query, sort=None):
        phone = query.get("phone_number")
        if phone and phone in self.docs:
            return self.docs[phone]
        for d in self.docs.values():
            if phone and d.get("phone_number") == phone:
                return d
        if self.docs and not phone:
            return list(self.docs.values())[0]
        return None

    def find(self, query):
        class MockCursor:
            def __init__(self, docs):
                self._docs = docs
            async def to_list(self, length=100):
                return list(self._docs.values())
        return MockCursor(self.docs)

    async def update_one(self, query, update, upsert=False):
        phone = query.get("phone_number")
        doc = update.get("$set", {})
        if "_id" not in doc:
            doc["_id"] = "mock_id_123"
        if phone:
            if phone in self.docs:
                self.docs[phone].update(doc)
            else:
                self.docs[phone] = doc
        return True

    async def insert_one(self, doc):
        phone = doc.get("phone_number")
        if "_id" not in doc:
            doc["_id"] = "mock_id_123"
        if phone:
            self.docs[phone] = doc
        return True

    def delete_all(self):
        self.docs.clear()

class MockMongoDB:
    def __init__(self):
        self.users = MockMongoCollection()
        self.districts = MockMongoCollection()
        self.market_demand_cache = MockMongoCollection()
        self.market_price_cache = MockMongoCollection()
        self.mandi_prices = MockMongoCollection()
        self.crop_profiles = MockMongoCollection()
        self.msp_prices = MockMongoCollection()
        self.crop_costs = MockMongoCollection()
        self.market_insights = MockMongoCollection()

async def run_tests():
    print("======================================================================")
    print("  EXECUTING DYNAMIC 'NOT SOWN YET' DASHBOARD END-TO-END SUITE")
    print("======================================================================")

    db = MockMongoDB()

    # ------------------------------------------------------------------
    # TEST 1: No Crop State (current_crop = null, sowing_date = null)
    # ------------------------------------------------------------------
    print("\n--- TEST 1: No Crop State (current_crop = null, sowing_date = null) ---")
    reg_no_crop = UserRegisterRequest(
        phone_number="9990001111",
        password="password123",
        farmer_name="Rohan Pisal",
        village="Kolhapur",
        language="en",
        state="Maharashtra",
        district="MUMBAI SUBURBAN",
        current_crop="Not Sown Yet",
        farm_area=2.0,
        farm_area_unit="acres",
        sowing_date=None,
        farm_location="Kolhapur",
    )
    user_res_1 = await user_service.register_user(db, reg_no_crop)
    print(f"   Registered User Current Crop : {user_res_1.current_crop}")
    print(f"   Registered User Sowing Date  : {user_res_1.sowing_date}")

    assert user_res_1.current_crop is None, f"Expected None, got {user_res_1.current_crop}"
    assert user_res_1.sowing_date is None, f"Expected None, got {user_res_1.sowing_date}"

    dash_no_crop = await dashboard_service.get_dashboard_overview(db, phone_number="9990001111")
    print(f"   Dashboard State            : {dash_no_crop['dashboard_state']}")
    print(f"   Top Recommendations        : {len(dash_no_crop.get('top_recommendations', []))} items")

    assert dash_no_crop["dashboard_state"] == "no_crop"
    assert len(dash_no_crop["top_recommendations"]) == 3
    print("   [PASS] TEST 1 PASSED: 'Not Sown Yet' correctly registered as null and routed to no_crop dashboard.")

    # ------------------------------------------------------------------
    # TEST 2: Actual Crop State (current_crop = Rapeseed &Mustard)
    # ------------------------------------------------------------------
    print("\n--- TEST 2: Actual Crop State (current_crop = Rapeseed &Mustard) ---")
    reg_actual = UserRegisterRequest(
        phone_number="8880002222",
        password="password123",
        farmer_name="Manav",
        village="Navalgad",
        language="en",
        state="Rajasthan",
        district="JHUNJHUNU",
        current_crop="Rapeseed &Mustard",
        farm_area=3.0,
        farm_area_unit="hectares",
        sowing_date=date(2026, 8, 11),
        farm_location="Navalgad",
    )
    user_res_2 = await user_service.register_user(db, reg_actual)
    print(f"   Registered Crop : {user_res_2.current_crop}")
    print(f"   Sowing Date     : {user_res_2.sowing_date}")

    dash_actual = await dashboard_service.get_dashboard_overview(db, phone_number="8880002222", query_date=date(2026, 8, 12))
    print(f"   Dashboard State : {dash_actual['dashboard_state']}")

    assert dash_actual["dashboard_state"] == "growing"
    assert dash_actual["crop"]["name"] == "Rapeseed &Mustard"
    print("   [PASS] TEST 2 PASSED: Actual growing crop state correctly registered and routed to sown dashboard.")

    # ------------------------------------------------------------------
    # TEST 3: Switching from Crop -> Not Sown Yet
    # ------------------------------------------------------------------
    print("\n--- TEST 3: Switching from Crop -> Not Sown Yet ---")
    # Start with active crop
    reg_switch = UserRegisterRequest(
        phone_number="7770003333",
        password="password123",
        farmer_name="Suresh",
        village="Rohtak",
        language="en",
        state="Haryana",
        district="Sonepat",
        current_crop="Soybean",
        farm_area=1.5,
        farm_area_unit="acres",
        sowing_date=date(2026, 8, 10),
    )
    await user_service.register_user(db, reg_switch)

    # User switches to Not Sown Yet in farm setup / profile
    upd = UserUpdateRequest(
        current_crop="Not Sown Yet",
        sowing_date=None,
    )
    user_res_3 = await user_service.update_user(db, "7770003333", upd.model_dump(exclude_none=True))
    print(f"   Updated MongoDB Crop : {user_res_3.current_crop}")
    print(f"   Updated MongoDB Date : {user_res_3.sowing_date}")

    assert user_res_3.current_crop is None
    assert user_res_3.sowing_date is None

    dash_switch = await dashboard_service.get_dashboard_overview(db, phone_number="7770003333")
    print(f"   Dashboard State      : {dash_switch['dashboard_state']}")

    assert dash_switch["dashboard_state"] == "no_crop"
    print("   [PASS] TEST 3 PASSED: Switching from Soybean -> Not Sown Yet cleanly cleared MongoDB and updated dashboard state to no_crop!")

    # ------------------------------------------------------------------
    # TEST 4: Flutter API Contract
    # ------------------------------------------------------------------
    print("\n--- TEST 4: Flutter API Response Contract for no_crop ---")
    assert "crop_stage" not in dash_no_crop or dash_no_crop.get("crop_stage") is None
    assert "water" not in dash_no_crop or dash_no_crop.get("water") is None
    assert "crop_health" not in dash_no_crop or dash_no_crop.get("crop_health") is None
    assert "yield_prediction" not in dash_no_crop or dash_no_crop.get("yield_prediction") is None
    assert dash_no_crop.get("previous_crop") is None
    print("   [PASS] TEST 4 PASSED: API contract confirmed free of stale sown crop structures.")

    print("\n======================================================================")
    print("  [SUCCESS] ALL 4 DYNAMIC DASHBOARD TESTS PASSED CLEANLY!")
    print("======================================================================")

if __name__ == "__main__":
    asyncio.run(run_tests())
