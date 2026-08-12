from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional, List


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
    farm_area: float = Field(..., description="Farm area")
    farm_area_unit: str = Field("acres", description="Unit: acres or hectares")
    sowing_date: Optional[date] = Field(None, description="Date when crop was sown (None if Not Sown Yet)")
    farm_location: str = Field("", description="Farm location / landmark description")


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
