"""
Test Crop Matrix Script
Tests all 9 oilseed crops across 4 growth stages (36 scenarios).
"""

import sys
import os
from datetime import date, timedelta

# Ensure UTF-8 output encoding for Windows terminal
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.crop_stage_service import crop_stage_service
from app.services.water_service import water_service

CROPS = [
    "groundnut",
    "soybean",
    "castor",
    "sunflower",
    "sesame",
    "rapeseed_mustard",
    "linseed",
    "safflower",
    "niger",
]

STAGE_DAS_MAP = {
    "initial": 10,
    "development": 35,
    "mid_season": 65,
    "late_season": 95,
}

def test_crop_matrix():
    print("=" * 65)
    print("  KISAAN MITRA — CROP MATRIX TEST (9 CROPS × 4 STAGES = 36)")
    print("=" * 65)

    total_scenarios = 0
    passed_scenarios = 0

    for crop in CROPS:
        profile = crop_stage_service._fallback_crop_profile(crop)
        kc_status = profile.get("kc_status", "established")
        kc_conf = profile.get("kc_confidence", "high")

        print(f"\n[CROP] {crop.upper()} (Kc Status: {kc_status}, Confidence: {kc_conf})")
        print("-" * 65)

        for stage_key, das in STAGE_DAS_MAP.items():
            total_scenarios += 1
            sowing_date = date.today() - timedelta(days=das)

            stage_res = crop_stage_service.calculate_stage(profile, sowing_date.isoformat())
            water_res = water_service.calculate_water_status(profile, das, eto_mm=5.2, forecast_rain_mm=18.0)

            display_stage = stage_res.get("stage_display")
            water_display = water_res.get("status_display")
            irr_mm = water_res.get("irrigation_mm")

            print(
                f"  Stage: {stage_key:12s} | DAS: {das:3d} | UI Stage: {display_stage:18s} | "
                f"Water Status: {water_display:12s} | Irr: ~{irr_mm} mm"
            )

            # Assertions
            assert display_stage in [
                "Early Growth",
                "Vegetative Growth",
                "Flowering",
                "Maturity",
            ], f"Invalid UI stage: {display_stage}"

            if crop == "niger":
                assert water_res["kc_status"] == "provisional_proxy"
                assert water_res["kc_confidence"] == "low"

            passed_scenarios += 1

    print("\n" + "=" * 65)
    print(f"  RESULT: {passed_scenarios} / {total_scenarios} SCENARIOS PASSED SUCCESSFULLY [OK]")
    print("=" * 65)

if __name__ == "__main__":
    test_crop_matrix()
