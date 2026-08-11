"""
End-to-End Dashboard Integration Test
Verifies complete flow:
  Farmer Profile -> Dashboard Service -> CatBoost Yield ML -> Satellite/Fallback -> Water -> Gemini/Fallback -> Response Schema
"""

import sys
import os
import asyncio

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.dashboard_service import dashboard_service
from app.ml.model_loader import model_loader


async def run_e2e_test():
    print("=" * 70)
    print("  KISAAN MITRA — END-TO-END DASHBOARD INTEGRATION TEST")
    print("=" * 70)

    # 1. Load ML models
    print("\n1. Loading CatBoost ML Models...")
    model_loader.load_models()
    print("   [OK] CatBoost models loaded successfully")

    # 2. Invoke Dashboard Service
    print("\n2. Invoking Dashboard Service for default farmer (Ramesh)...")
    response = await dashboard_service.get_sown_dashboard(
        db=None, phone_number=None, language="English"
    )

    print("\n3. Validating End-to-End Response Payload:")
    print("-" * 70)
    print(f"   State             : {response.state}")
    print(f"   Farmer Name       : {response.farmer.name}")
    print(f"   Location          : {response.farmer.village}, {response.farmer.district} • {response.farmer.state}")
    print(f"   Crop              : {response.crop.name} (ID: {response.crop.id})")
    print(f"   Weather Temp      : {response.weather.temperature}°C ({response.weather.condition})")
    print(f"   Rain 24h          : {response.weather.rain_next_24h_mm} mm ({response.weather.rain_description})")
    print(f"   Crop Stage        : {response.crop_stage.stage_display} ({response.crop_stage.stage_icon}, Index {response.crop_stage.stage_index})")
    print(f"   Water Status      : {response.water.status_display} (~{response.water.irrigation_mm} mm)")
    print(f"   Crop Health       : {response.crop_health.status_display} (Score: {response.crop_health.score})")
    print(f"   CatBoost Yield    : {response.yield_prediction.predicted} T/Ha [{response.yield_prediction.lower} - {response.yield_prediction.upper}] ({response.yield_prediction.model_used} model)")
    print(f"   Recommendations   : {len(response.recommendations)} items returned")

    for i, r in enumerate(response.recommendations, 1):
        print(f"     {i}. {r.icon} {r.title}: {r.description}")

    # Assertions
    assert response.state == "sown"
    assert response.farmer.name == "Ramesh"
    assert response.crop_stage.stage_display in ["Early Growth", "Vegetative Growth", "Flowering", "Maturity"]
    assert response.yield_prediction.predicted > 0
    assert len(response.recommendations) >= 3

    print("\n" + "=" * 70)
    print("  ALL END-TO-END VERIFICATION CHECKS PASSED SUCCESSFULLY [OK]")
    print("=" * 70)


if __name__ == "__main__":
    asyncio.run(run_e2e_test())
