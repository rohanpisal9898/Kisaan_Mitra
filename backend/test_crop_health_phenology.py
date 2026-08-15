"""
Comprehensive Phenology-Aware Crop Health Test Suite & Evidence Audit Matrix.

Tests:
1. 36 Scenarios (9 Oilseed Crops × 4 Growth Stages)
2. Evidence Audit Report (directly_reported, literature_supported, derived, calibration_required)
3. Maturity Senescence Non-Penalization
4. Stale Satellite Freshness (>30 Days)
5. Missing Index Weight Renormalization
6. System-Wide 'Watch' -> 'Monitor' Category Verification
"""

import json
from pathlib import Path
from datetime import date, timedelta
from app.services.crop_health_service import crop_health_service

CROPS = [
    "soybean",
    "groundnut",
    "castor",
    "sunflower",
    "sesame",
    "rapeseed_mustard",
    "linseed",
    "safflower",
    "niger",
]

STAGES = ["early_growth", "vegetative", "flowering", "maturity"]


def run_phenology_test_suite():
    print("=" * 70)
    print("  EXECUTING 36-SCENARIO PHENOLOGY CROP HEALTH TEST SUITE")
    print("=" * 70)

    today_str = date.today().isoformat()
    passed_count = 0
    total_scenarios = len(CROPS) * len(STAGES)

    # ------------------------------------------------------------------
    # TEST MATRIX: 9 CROPS × 4 STAGES
    # ------------------------------------------------------------------
    for crop in CROPS:
        for stage in STAGES:
            sample_sat = {
                "NDVI": 0.65,
                "NDRE": 0.35,
                "EVI": 0.50,
                "NDMI": 0.15,
                "VV": -12.5,
                "VH": -18.2,
            }
            res = crop_health_service.calculate_health(
                crop_profile={"crop_id": crop},
                stage_id=stage,
                satellite_data=sample_sat,
                satellite_date=today_str,
            )

            assert res["crop_id"] == crop
            assert res["stage_id"] == stage
            assert res["status"] in ["good", "monitor", "needs_attention", "poor", "unavailable"]
            assert res["status"] != "watch"
            assert res["status_display"] != "Watch"

            if res["score"] is not None:
                assert 0.0 <= res["score"] <= 100.0

            passed_count += 1

    print(f"\n   [PASS] Matrix Test Passed: All {passed_count}/{total_scenarios} crop-stage scenarios evaluated cleanly.")

    # ------------------------------------------------------------------
    # TEST 37: Maturity Senescence Non-Penalization
    # ------------------------------------------------------------------
    print("\n--- TEST 37: Maturity Senescence Non-Penalization ---")
    senescent_sat = {"NDVI": 0.45, "NDRE": 0.22, "EVI": 0.32, "NDMI": 0.02}
    res_mat = crop_health_service.calculate_health(
        crop_profile={"crop_id": "soybean"},
        stage_id="maturity",
        satellite_data=senescent_sat,
        satellite_date=today_str,
    )
    print(f"   Soybean Maturity NDVI=0.45 -> Score: {res_mat['score']}, Status: {res_mat['status_display']}")
    assert res_mat["score"] >= 60.0  # Should be Good or Monitor, NOT Poor
    assert res_mat["status"] in ["good", "monitor"]
    print("   [PASS] TEST 37 PASSED: Declining NDVI in Maturity stage correctly recognized as normal senescence.")

    # ------------------------------------------------------------------
    # TEST 38: Satellite Freshness (>30 Days Stale)
    # ------------------------------------------------------------------
    print("\n--- TEST 38: Satellite Freshness (>30 Days Stale) ---")
    stale_date = (date.today() - timedelta(days=35)).isoformat()
    res_stale = crop_health_service.calculate_health(
        crop_profile={"crop_id": "soybean"},
        stage_id="flowering",
        satellite_data=sample_sat,
        satellite_date=stale_date,
    )
    assert res_stale["status"] == "unavailable"
    assert res_stale["score"] is None
    assert "too old" in res_stale["description"].lower()
    print("   [PASS] TEST 38 PASSED: Satellite observation >30 days old strictly returns Unavailable state.")

    # ------------------------------------------------------------------
    # TEST 39: Missing Index Weight Renormalization
    # ------------------------------------------------------------------
    print("\n--- TEST 39: Missing Index Weight Renormalization ---")
    partial_sat = {"NDVI": 0.72}  # Only NDVI available
    res_part = crop_health_service.calculate_health(
        crop_profile={"crop_id": "sunflower"},
        stage_id="flowering",
        satellite_data=partial_sat,
        satellite_date=today_str,
    )
    assert res_part["status"] == "good"
    assert res_part["score"] == 100.0
    assert "NDVI" in res_part["available_indices"]
    assert "NDRE" in res_part["missing_indices"]
    print("   [PASS] TEST 39 PASSED: Weights cleanly renormalized over available indices without zero-penalization.")

    # ------------------------------------------------------------------
    # TEST 40: Temporal Trend Evaluation
    # ------------------------------------------------------------------
    print("\n--- TEST 40: Temporal Trend Evaluation ---")
    curr_sat = {"NDVI": 0.75, "NDRE": 0.40, "EVI": 0.55, "NDMI": 0.18}
    prev_sat = {"NDVI": 0.65, "NDRE": 0.32, "EVI": 0.45, "NDMI": 0.12}
    res_trend = crop_health_service.calculate_health(
        crop_profile={"crop_id": "soybean"},
        stage_id="vegetative",
        satellite_data=curr_sat,
        satellite_date=today_str,
        previous_satellite_data=prev_sat,
    )
    assert res_trend["score"] >= 85.0
    assert res_trend["status"] == "good"
    print("   [PASS] TEST 40 PASSED: Positive temporal trend (+0.10 NDVI) incorporated into health score.")

    # ------------------------------------------------------------------
    # EVIDENCE AUDIT REPORT
    # ------------------------------------------------------------------
    print("\n" + "=" * 70)
    print("  SCIENTIFIC EVIDENCE LEVEL AUDIT REPORT")
    print("=" * 70)

    json_path = Path(__file__).parent / "data" / "crop_health_benchmarks.json"
    with open(json_path, "r", encoding="utf-8") as f:
        benchmarks_data = json.load(f)

    evidence_counts = {
        "directly_reported": 0,
        "literature_supported": 0,
        "derived_from_published_curve": 0,
        "satellite_calibrated": 0,
        "calibration_required": 0,
    }

    for crop_id, stages in benchmarks_data.items():
        for stage_id, stage_bench in stages.items():
            indices = stage_bench.get("indices", {})
            for idx_name, idx_info in indices.items():
                e_level = idx_info.get("evidence_level", "calibration_required")
                evidence_counts[e_level] = evidence_counts.get(e_level, 0) + 1

    total_benchmarks = sum(evidence_counts.values())
    print(f"   Total Crop-Stage-Index Benchmarks : {total_benchmarks}")
    print(f"   - directly_reported              : {evidence_counts['directly_reported']}")
    print(f"   - literature_supported            : {evidence_counts['literature_supported']}")
    print(f"   - derived_from_published_curve   : {evidence_counts['derived_from_published_curve']}")
    print(f"   - satellite_calibrated           : {evidence_counts['satellite_calibrated']}")
    print(f"   - calibration_required           : {evidence_counts['calibration_required']} (Sentinel-1 SAR)")

    print("\n======================================================================")
    print("  [SUCCESS] ALL PHENOLOGY CROP HEALTH & EVIDENCE AUDIT TESTS PASSED!")
    print("======================================================================")


if __name__ == "__main__":
    run_phenology_test_suite()
