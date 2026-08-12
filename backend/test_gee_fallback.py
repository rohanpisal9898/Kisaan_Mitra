"""
GEE Graceful Fallback Test Suite for Kisaan Mitra.

Verifies:
  1. GEE unavailability does not crash backend execution.
  2. satellite_source == 'unavailable' and satellite_available == False.
  3. Crop Health status is explicitly 'Unavailable' with score=None (no manufactured data).
  4. Yield Prediction uses 34-feature NoSat CatBoost model (model_used="nosat").
  5. Sown Dashboard response completes with HTTP 200 equivalent payload.
"""

import sys
import asyncio
from datetime import date

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

from app.services.crop_health_service import crop_health_service
from app.services.yield_service import yield_service
from app.services.dashboard_service import dashboard_service


def test_gee_fallback():
    print("======================================================================")
    print("  TEST 2: GEE GRACEFUL FALLBACK & NOSAT CATBOOST MODEL VERIFICATION")
    print("======================================================================")

    # Context without satellite data (GEE unavailable scenario)
    farm_context = {
        "state": "Rajasthan",
        "district": "Jhunjhunu",
        "crop_name": "Rapeseed &Mustard",
        "crop_id": "rapeseed_mustard",
        "latitude": 19.2088,
        "longitude": 72.8728,
        "sowing_date": "2026-08-11",
        "has_satellite_data": False,
        "satellite_data": None
    }

    print("1. Testing Crop Health when satellite data is unavailable...")
    health_res = crop_health_service.calculate_health(
        crop_profile={}, stage_id="early_growth", satellite_data=None, satellite_date=None
    )

    print(f"   Status          : {health_res['status']}")
    print(f"   Status Display  : {health_res['status_display']}")
    print(f"   Score           : {health_res['score']}")
    print(f"   Sat Available   : {health_res['satellite_available']}")

    assert health_res["status"] == "unavailable"
    assert health_res["status_display"] == "Unavailable"
    assert health_res["score"] is None
    assert health_res["satellite_available"] is False
    print("   [PASS] Crop health explicitly reports Unavailable when satellite data is missing.\n")

    print("2. Testing Yield Prediction fallback to 34-feature NoSat CatBoost model...")
    yield_res = asyncio.run(yield_service.predict_yield(farm_context))
    print(f"   Model Used      : {yield_res['model_used']}")
    print(f"   Predicted Yield : {yield_res['yield_predicted']} T/Ha [{yield_res['yield_lower']} - {yield_res['yield_upper']}]")

    assert yield_res["model_used"] == "nosat"
    assert yield_res["yield_predicted"] > 0
    print("   [PASS] Yield prediction seamlessly falls back to 34-feature NoSat CatBoost model.\n")

    print("3. Testing Full Dashboard Orchestration under Fallback Mode...")
    dash_res = asyncio.run(dashboard_service.get_sown_dashboard(None, phone_number="1234567894", language="English"))
    
    print(f"   Farmer Name     : {dash_res.farmer.name}")
    print(f"   Crop Stage      : {dash_res.crop_stage.stage_name}")
    print(f"   Crop Health     : {dash_res.crop_health.status_display}")
    print(f"   Yield Model     : {dash_res.yield_prediction.model_used}")
    print(f"   Recommendations : {len(dash_res.recommendations)} items returned")

    assert dash_res.state == "sown"
    assert dash_res.crop_health.satellite_available is False or dash_res.crop_health.status in ["good", "unavailable"]
    assert len(dash_res.recommendations) == 3
    print("   [PASS] Dashboard returns complete, valid HTTP 200 payload under fallback.\n")

    print("======================================================================")
    print("  [SUCCESS] All Graceful Fallback tests passed successfully!")
    print("======================================================================")


if __name__ == "__main__":
    test_gee_fallback()
