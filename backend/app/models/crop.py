"""Pydantic models for crop profiles and related data."""

from pydantic import BaseModel, Field
from typing import Optional, Dict


class KcCoefficients(BaseModel):
    """FAO crop coefficients (Kc) for water calculation."""
    initial: float = Field(..., description="Kc during initial stage")
    mid: float = Field(..., description="Kc during mid-season stage")
    end: float = Field(..., description="Kc during late/end stage")


class GrowthStages(BaseModel):
    """Duration in days for each FAO growth stage."""
    initial: int = Field(..., description="Initial stage duration (days)")
    development: int = Field(..., description="Development stage duration (days)")
    mid_season: int = Field(..., description="Mid-season stage duration (days)")
    late_season: int = Field(..., description="Late-season stage duration (days)")


class CropProfile(BaseModel):
    """Full crop profile stored in MongoDB."""
    crop_id: str = Field(..., description="Canonical crop identifier")
    display_names: Dict[str, str] = Field(
        default_factory=dict,
        description="Localized display names: {en: 'Soyabean', hi: 'सोयाबीन', ...}",
    )
    growth_duration_days: int = Field(..., description="Total crop duration in days")
    stages: GrowthStages
    kc: KcCoefficients
    kc_status: str = Field(
        "established",
        description="'established' or 'provisional_proxy'",
    )
    kc_confidence: str = Field(
        "high",
        description="Confidence level: 'high', 'medium', 'low'",
    )


class CropStageResult(BaseModel):
    """Result of crop-stage calculation."""
    stage_id: str = Field(..., description="Internal stage: initial/development/mid_season/late_season")
    stage_display: str = Field(..., description="Farmer-facing stage name")
    days_after_sowing: int
    total_duration: int
    progress_fraction: float = Field(..., ge=0.0, le=1.0)
    status: str = Field("on_track", description="on_track / not_started / matured")
