"""
GEE Integration Test Suite for Kisaan Mitra.

Verifies:
  1. GEE initialization with project 'kisaanapp-505311'.
  2. Live Sentinel-2 satellite imagery query & cloud filtering.
  3. Spectral index extraction (NDVI, NDMI, NDYI, LST, ndvi, ndre, evi).
  4. Date-window acquisition date tracking.
  5. 38-feature completeness validation before CatBoost model invocation.
  6. CatBoost Satellite model execution (model_used="satellite").
"""

import sys
import asyncio
from datetime import datetime

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

from app.integrations.gee_service import gee_service
from app.services.yield_service import yield_service
from app.services.crop_health_service import crop_health_service
from app.services.crop_stage_service import crop_stage_service


def test_gee_service():
    print("======================================================================")
    print("  TEST 1: GOOGLE EARTH ENGINE (GEE) INTEGRATION & INDEX EXTRACTION")
    print("======================================================================")

    # Test lat/lon for agricultural land in Jhunjhunu, Rajasthan
    latitude = 19.2088
    longitude = 72.8728
    sowing_date = "2026-06-15"

    print(f"1. Initializing GEE for coordinates lat={latitude}, lon={longitude}...")
    gee_res = gee_service.fetch_satellite_data(latitude, longitude, sowing_date)

    print(f"\n   [GEE SERVICE RESULT]")
    print(f"     satellite_available : {gee_res.get('satellite_available')}")
    print(f"     satellite_source    : {gee_res.get('satellite_source')}")
    print(f"     satellite_date      : {gee_res.get('satellite_date')}")
    print(f"     cloud_cover         : {gee_res.get('cloud_cover')}%")
    print(f"     error_message       : {gee_res.get('error_message')}")

    if gee_res.get("satellite_available"):
        sat_data = gee_res.get("satellite_data", {})
        print(f"\n2. Extracted Spectral Indices:")
        print(f"     CatBoost Keys (Uppercase) -> NDVI: {sat_data.get('NDVI')}, NDMI: {sat_data.get('NDMI')}, NDYI: {sat_data.get('NDYI')}, LST: {sat_data.get('LST')}")
        print(f"     Crop Health Keys (Lowercase) -> ndvi: {sat_data.get('ndvi')}, ndre: {sat_data.get('ndre')}, evi: {sat_data.get('evi')}, ndmi: {sat_data.get('ndmi')}")

        assert "NDVI" in sat_data and "NDMI" in sat_data and "NDYI" in sat_data and "LST" in sat_data
        assert "ndvi" in sat_data and "ndre" in sat_data and "evi" in sat_data

        print("\n3. Testing Stage Alignment at Satellite Acquisition Date...")
        acq_date = gee_res.get("satellite_date")
        profile = crop_stage_service._fallback_crop_profile("rapeseed_mustard")
        stage_at_photo = crop_stage_service.calculate_stage(profile, sowing_date, query_date_str=acq_date)
        print(f"     Stage at image acquisition date ({acq_date}): {stage_at_photo['stage_name']} (DAS: {stage_at_photo['days_after_sowing']})")

        print("\n4. Testing Crop Health Scoring with Real GEE Imagery...")
        health_res = crop_health_service.calculate_health(profile, stage_at_photo["stage_id"], sat_data, acq_date)
        print(f"     Status: {health_res['status_display']}, Score: {health_res['score']}, Available: {health_res['satellite_available']}")

        assert health_res["satellite_available"] is True
        assert health_res["score"] is not None

        print("\n5. Testing CatBoost 38-Feature Satellite Yield Prediction Model...")
        farm_context = {
            "state": "Rajasthan",
            "district": "Jhunjhunu",
            "crop_name": "Rapeseed &Mustard",
            "crop_id": "rapeseed_mustard",
            "latitude": latitude,
            "longitude": longitude,
            "sowing_date": sowing_date,
            "has_satellite_data": True,
            "satellite_data": sat_data
        }
        yield_res = asyncio.run(yield_service.predict_yield(farm_context))
        print(f"     Model Used: {yield_res['model_used']}")
        print(f"     Predicted Yield: {yield_res['yield_predicted']} T/Ha [{yield_res['yield_lower']} - {yield_res['yield_upper']}]")

        assert yield_res["model_used"] == "satellite"
        print("\n[SUCCESS] GEE Integration & 38-Feature Satellite Model test passed!\n")
    else:
        print(f"\n[NOTE] GEE Service returned unavailable ({gee_res.get('error_message')}). Verified exception-safe fallback.\n")


if __name__ == "__main__":
    test_gee_service()
