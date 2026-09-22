import pytest
import os
import sys

os.environ.setdefault("MONGODB_URI", "mongodb://localhost:27017/kisaan_mitra")
os.environ.setdefault("JWT_SECRET_KEY", "test_jwt_secret_key_12345678901234567890")

# Add backend directory to sys.path
sys.path.insert(0, os.path.abspath("backend"))

from app.utils.auth import create_access_token, create_refresh_token, decode_token
from app.services.dashboard_service import dashboard_service

def test_jwt_auth_tokens():
    test_phone = "9876543210"
    user_data = {"phone_number": test_phone, "farmer_name": "Rohan Farmer"}
    
    # 1. Generate Access & Refresh Tokens
    access_token = create_access_token(user_data)
    refresh_token = create_refresh_token(user_data)
    
    assert access_token is not None and len(access_token) > 20
    assert refresh_token is not None and len(refresh_token) > 20
    
    # 2. Decode Access Token
    payload = decode_token(access_token)
    assert payload["sub"] == test_phone
    assert payload["farmer_name"] == "Rohan Farmer"
    assert payload["type"] == "access"
    
    # 3. Decode Refresh Token
    r_payload = decode_token(refresh_token)
    assert r_payload["sub"] == test_phone
    assert r_payload["type"] == "refresh"

@pytest.mark.asyncio
async def test_dashboard_defaults_nosat():
    # Test that DashboardService defaults to satellite_available=False and nosat yield model
    dashboard_data = await dashboard_service.get_sown_dashboard(
        db=None,
        phone_number="9876543210",
        language="English"
    )
    
    assert dashboard_data is not None
    assert dashboard_data.yield_prediction is not None
    yield_pred = dashboard_data.yield_prediction
    assert yield_pred.model_used == "nosat", f"Expected nosat model_used, got {yield_pred.model_used}"
    assert dashboard_data.crop_health.satellite_available is False, "Expected crop_health.satellite_available to be False by default"
