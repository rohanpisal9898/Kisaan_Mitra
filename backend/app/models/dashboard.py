from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any

class FarmerInfo(BaseModel):
    name: str = "Ramesh"
    village: str = "Sonepur"
    district: str = "Nashik"
    state: str = "Maharashtra"

class CropInfo(BaseModel):
    id: str = "soybean"
    name: str = "Soyabean"
    sowing_date: str = "2026-06-15"

class WeatherInfo(BaseModel):
    temperature: float = 26.0
    feels_like: float = 28.0
    condition: str = "Partly Cloudy"
    rain_next_24h_mm: float = 18.0
    rain_description: str = "18 mm rain expected"
    wind_kmh: float = 5.0
    available: bool = True

class CropStageInfo(BaseModel):
    stage_id: str = "flowering"
    stage_name: str = "Flowering"
    stage_display: str = "Flowering"
    stage_icon: str = "🌼"
    stage_index: int = 2
    status: str = "on_track"
    days_after_sowing: int = 60
    total_duration: int = 104
    progress_fraction: float = 0.577

class WaterStatusInfo(BaseModel):
    status: str = "rain_sufficient"
    status_display: str = "Rain may cover need"
    irrigation_mm: float = 0.0
    description: str = "No irrigation needed today"
    color: str = "blue"
    kc_status: str = "established"

class CropHealthInfo(BaseModel):
    status: str = "good"
    status_display: str = "Good"
    score: Optional[float] = 86.0
    description: str = "Your crop is growing normally"
    satellite_available: bool = True
    satellite_date: Optional[str] = "2026-08-06"
    satellite_days_old: Optional[int] = 4
    crop_id: Optional[str] = "soybean"
    stage_id: Optional[str] = "flowering"
    available_indices: List[str] = []
    missing_indices: List[str] = []
    index_scores: Dict[str, float] = {}
    benchmark_metadata: Dict[str, Any] = {}

class YieldPredictionInfo(BaseModel):
    predicted: float = 3.4
    lower: float = 3.1
    upper: float = 3.7
    unit: str = "tonnes_per_hectare"
    model_used: str = "satellite"
    confidence_label: str = "90% Confidence Range"

class RecommendationItem(BaseModel):
    priority: int
    category: str = "general"
    type: str = "general"
    title: str
    description: str
    severity: str = "medium"
    icon: str = "💡"

class SownDashboardResponse(BaseModel):
    dashboard_state: str = "growing"
    state: str = "sown"
    farmer: FarmerInfo
    crop: CropInfo
    weather: WeatherInfo
    crop_stage: CropStageInfo
    water: WaterStatusInfo
    crop_health: CropHealthInfo
    yield_prediction: YieldPredictionInfo
    recommendations: List[RecommendationItem] = []

class TopCropRecommendationItem(BaseModel):
    rank: int
    crop: str
    crop_id: str
    icon: str = "🌱"
    score: int = 91
    suitability_percentage: str = "91%"
    demand_score: float = 90.0
    water_score: float = 85.0
    sowing_score: float = 95.0
    market_demand: str = "High"
    net_return: int = 11324
    net_return_formatted: str = "Rs. 11,324/ha"
    water_requirement: int = 4200
    water_requirement_unit: str = "m3"
    water_level: str = "Medium"
    recommended_sowing: str = "June – July"

class PreviousCropInfo(BaseModel):
    name: str
    sowing_date: str
    status: str = "mature"

class PlanningDashboardResponse(BaseModel):
    dashboard_state: str = "no_crop"  # "no_crop" or "crop_matured"
    crop: Optional[CropInfo] = None
    sowing_date: Optional[str] = None
    farmer: FarmerInfo
    location: Dict[str, Any]
    farm_area_ha: float = 2.5
    weather: WeatherInfo
    previous_crop: Optional[PreviousCropInfo] = None
    top_recommendations: List[TopCropRecommendationItem] = Field(default_factory=list)
    market_items: List[Dict[str, Any]] = Field(default_factory=list)
    financial_outlook: Optional[Any] = None
    yield_prediction: Optional[Any] = None
    crop_health: Optional[Any] = None
    water_status: Optional[Any] = None
