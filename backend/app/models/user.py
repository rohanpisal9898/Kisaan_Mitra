import math
from pydantic import BaseModel, Field, field_validator, model_validator
from datetime import date, datetime
from typing import Optional, List


def _normalize_unit(v: str) -> str:
    normalized = v.strip().lower()
    if normalized in {"acre", "acres", "ac"}:
        return "acres"
    if normalized in {"hectare", "hectares", "ha"}:
        return "hectares"
    raise ValueError("Farm area unit must be acres or hectares")


def _validate_area_bounds_helper(area: float, unit: str):
    if not math.isfinite(area):
        raise ValueError("Farm area must be a valid finite number")
    if unit == "hectares":
        min_area, max_area = 0.05, 200.0
    else:
        min_area, max_area = 0.1, 500.0

    if not (min_area <= area <= max_area):
        raise ValueError(
            f"Farm area must be between {min_area} and {max_area} {unit}"
        )


class UserRegisterRequest(BaseModel):
    """Request model for user registration (Step 1 + Step 2 combined)."""
    phone_number: str = Field(..., description="User's phone number (unique identifier)")
    password: str = Field("123456", description="User password for account protection")
    farmer_name: str = Field(..., description="Farmer's name")
    village: str = Field("", description="Village name")
    language: str = Field("en", description="Preferred language: en, hi, mr")

    # Location - can be from dropdown OR auto-detect
    state: str = Field(..., description="State name (from dropdown)")
    district: str = Field(..., description="District name (from dropdown)")
    latitude: Optional[float] = Field(None, description="GPS latitude (from auto-detect)")
    longitude: Optional[float] = Field(None, description="GPS longitude (from auto-detect)")

    # Farm details (Step 2)
    current_crop: Optional[str] = Field(None, description="Current crop being grown (None if Not Sown Yet)")
    farm_area: float = Field(..., description="Farm area value")
    farm_area_unit: str = Field("acres", description="Unit: acres or hectares")
    sowing_date: Optional[date] = Field(None, description="Date when crop was sown (None if Not Sown Yet)")
    farm_location: str = Field("", description="Farm location / landmark description")

    @field_validator("farm_area")
    @classmethod
    def validate_finite_area(cls, v: float) -> float:
        if not math.isfinite(v):
            raise ValueError("Farm area must be a valid finite number")
        return v

    @field_validator("farm_area_unit")
    @classmethod
    def validate_area_unit(cls, v: str) -> str:
        return _normalize_unit(v)

    @model_validator(mode="after")
    def validate_area_bounds(self):
        _validate_area_bounds_helper(self.farm_area, self.farm_area_unit)
        self.farm_area = round(self.farm_area, 2)
        return self


class UserLoginRequest(BaseModel):
    """Request model for user login/authentication."""
    phone_number: str = Field(..., description="User phone number")
    password: str = Field(..., description="User password")


class UserResponse(BaseModel):
    """Response model for user data."""
    id: str
    phone_number: str
    farmer_name: str
    village: str
    language: str
    state: str
    district: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    current_crop: Optional[str] = None
    farm_area: float
    farm_area_unit: str
    sowing_date: Optional[date] = None
    farm_location: str = ""
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class UserUpdateRequest(BaseModel):
    """Request model for updating user fields."""
    farmer_name: Optional[str] = None
    village: Optional[str] = None
    language: Optional[str] = None
    state: Optional[str] = None
    district: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    current_crop: Optional[str] = None
    farm_area: Optional[float] = None
    farm_area_unit: Optional[str] = None
    sowing_date: Optional[date] = None
    farm_location: Optional[str] = None

    @field_validator("farm_area")
    @classmethod
    def validate_finite_area_opt(cls, v: Optional[float]) -> Optional[float]:
        if v is not None:
            if not math.isfinite(v):
                raise ValueError("Farm area must be a valid finite number")
        return v

    @field_validator("farm_area_unit")
    @classmethod
    def validate_area_unit_opt(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            return _normalize_unit(v)
        return v

    @model_validator(mode="after")
    def validate_area_bounds_opt(self):
        if self.farm_area is not None:
            unit = self.farm_area_unit or "acres"
            _validate_area_bounds_helper(self.farm_area, unit)
            self.farm_area = round(self.farm_area, 2)
        return self


class AuthTokenResponse(BaseModel):
    """Response model returning authenticated user and JWT session tokens."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse


class RefreshTokenRequest(BaseModel):
    """Request model to refresh an expired access token."""
    refresh_token: str


class RefreshTokenResponse(BaseModel):
    """Response model for refreshed tokens."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
