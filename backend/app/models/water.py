"""Pydantic models for water status calculation."""

from pydantic import BaseModel, Field
from typing import Optional


class WaterCalculation(BaseModel):
    """Internal water calculation details."""
    eto_mm: float = Field(..., description="Reference evapotranspiration (mm/day)")
    kc: float = Field(..., description="Current crop coefficient")
    etc_mm: float = Field(..., description="Crop evapotranspiration (mm/day)")
    effective_rainfall_mm: float = Field(0, description="Effective rainfall (mm)")
    irrigation_need_mm: float = Field(0, description="Net irrigation requirement (mm)")


class WaterStatusResponse(BaseModel):
    """Farmer-facing water status."""
    status: str = Field(
        ...,
        description="Status category: well_supplied / needs_soon / irrigation_needed / high_stress / rain_sufficient",
    )
    status_display: str = Field(..., description="Farmer-friendly status text")
    irrigation_mm: Optional[float] = Field(None, description="Approximate irrigation in mm")
    description: str = Field("", description="Short explanation")
    color: str = Field("green", description="UI color hint: green/yellow/orange/red/blue")
    calculation: Optional[WaterCalculation] = Field(
        None, description="Internal calculation details (not shown to farmer)"
    )
