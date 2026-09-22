import math
import os
import sys
import pytest
from pydantic import ValidationError

sys.path.insert(0, os.path.abspath("backend"))

from app.models.user import UserRegisterRequest, UserUpdateRequest


def create_register_payload(**overrides):
    payload = {
        "phone_number": "9876543210",
        "password": "password123",
        "farmer_name": "Rohan Sharma",
        "village": "Deolali",
        "state": "Maharashtra",
        "district": "Nashik",
        "current_crop": "Soyabean",
        "farm_area": 2.5,
        "farm_area_unit": "acres",
        "farm_location": "Deolali Farm",
    }
    payload.update(overrides)
    return payload


class TestFarmAreaBounds:
    # ─── Acres Boundary Tests ──────────────────────────────────
    def test_acres_below_minimum_rejected(self):
        with pytest.raises(ValidationError) as exc:
            UserRegisterRequest(**create_register_payload(farm_area=0.09, farm_area_unit="acres"))
        assert "Farm area must be between 0.1 and 500.0 acres" in str(exc.value)

    def test_acres_at_minimum_accepted(self):
        req = UserRegisterRequest(**create_register_payload(farm_area=0.10, farm_area_unit="acres"))
        assert req.farm_area == 0.10
        assert req.farm_area_unit == "acres"

    def test_acres_at_maximum_accepted(self):
        req = UserRegisterRequest(**create_register_payload(farm_area=500.0, farm_area_unit="acres"))
        assert req.farm_area == 500.0
        assert req.farm_area_unit == "acres"

    def test_acres_above_maximum_rejected(self):
        with pytest.raises(ValidationError) as exc:
            UserRegisterRequest(**create_register_payload(farm_area=500.01, farm_area_unit="acres"))
        assert "Farm area must be between 0.1 and 500.0 acres" in str(exc.value)

    # ─── Hectares Boundary Tests ───────────────────────────────
    def test_hectares_below_minimum_rejected(self):
        with pytest.raises(ValidationError) as exc:
            UserRegisterRequest(**create_register_payload(farm_area=0.049, farm_area_unit="hectares"))
        assert "Farm area must be between 0.05 and 200.0 hectares" in str(exc.value)

    def test_hectares_at_minimum_accepted(self):
        req = UserRegisterRequest(**create_register_payload(farm_area=0.05, farm_area_unit="hectares"))
        assert req.farm_area == 0.05
        assert req.farm_area_unit == "hectares"

    def test_hectares_at_maximum_accepted(self):
        req = UserRegisterRequest(**create_register_payload(farm_area=200.0, farm_area_unit="hectares"))
        assert req.farm_area == 200.0
        assert req.farm_area_unit == "hectares"

    def test_hectares_above_maximum_rejected(self):
        with pytest.raises(ValidationError) as exc:
            UserRegisterRequest(**create_register_payload(farm_area=200.01, farm_area_unit="hectares"))
        assert "Farm area must be between 0.05 and 200.0 hectares" in str(exc.value)

    # ─── Unit-Aware Disambiguation Test (Crucial Proof) ───────
    def test_unit_aware_differentiation_0_06(self):
        # 0.06 is valid for hectares (min 0.05)
        req_ha = UserRegisterRequest(**create_register_payload(farm_area=0.06, farm_area_unit="hectares"))
        assert req_ha.farm_area == 0.06

        # 0.06 is invalid for acres (min 0.1)
        with pytest.raises(ValidationError) as exc:
            UserRegisterRequest(**create_register_payload(farm_area=0.06, farm_area_unit="acres"))
        assert "Farm area must be between 0.1 and 500.0 acres" in str(exc.value)

    # ─── Non-numeric & Special Values ─────────────────────────
    def test_nan_rejected(self):
        with pytest.raises(ValidationError) as exc:
            UserRegisterRequest(**create_register_payload(farm_area=float("nan"), farm_area_unit="acres"))
        assert "Farm area must be a valid finite number" in str(exc.value) or "finite" in str(exc.value)

    def test_infinity_rejected(self):
        with pytest.raises(ValidationError) as exc:
            UserRegisterRequest(**create_register_payload(farm_area=float("inf"), farm_area_unit="acres"))
        assert "Farm area must be a valid finite number" in str(exc.value) or "finite" in str(exc.value)

    def test_invalid_unit_rejected(self):
        with pytest.raises(ValidationError) as exc:
            UserRegisterRequest(**create_register_payload(farm_area=5.0, farm_area_unit="square_feet"))
        assert "Farm area unit must be acres or hectares" in str(exc.value)

    # ─── Unit Normalization Tests ─────────────────────────────
    def test_unit_normalization(self):
        for u in ["acre", "acres", "ac", " ACRES "]:
            req = UserRegisterRequest(**create_register_payload(farm_area=2.0, farm_area_unit=u))
            assert req.farm_area_unit == "acres"

        for u in ["hectare", "hectares", "ha", " HECTARES "]:
            req = UserRegisterRequest(**create_register_payload(farm_area=2.0, farm_area_unit=u))
            assert req.farm_area_unit == "hectares"

    # ─── UserUpdateRequest Tests ──────────────────────────────
    def test_update_request_bounds(self):
        # Valid update
        up1 = UserUpdateRequest(farm_area=10.0, farm_area_unit="hectares")
        assert up1.farm_area == 10.0
        assert up1.farm_area_unit == "hectares"

        # Invalid update: 0.06 acres
        with pytest.raises(ValidationError):
            UserUpdateRequest(farm_area=0.06, farm_area_unit="acres")

        # Valid update: 0.06 hectares
        up2 = UserUpdateRequest(farm_area=0.06, farm_area_unit="ha")
        assert up2.farm_area == 0.06
        assert up2.farm_area_unit == "hectares"
