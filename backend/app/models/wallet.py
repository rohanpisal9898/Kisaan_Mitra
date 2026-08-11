from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class ExpenseItem(BaseModel):
    id: str = Field(..., description="Unique ID of the expense item")
    category: str = Field(..., description="Category key: seed, fertilizer, labour, machinery, irrigation, insecticides, other, or custom")
    label: str = Field(..., description="Display label e.g. Seeds, Labour, Pest Control")
    amount: float = Field(..., ge=0, description="Cost amount in INR")
    is_custom: bool = Field(False, description="Whether this is a custom user-added expense")


class MspInfo(BaseModel):
    crop: str = Field(..., description="Crop name")
    commodity: str = Field("", description="Government commodity specification")
    season: str = Field("Kharif", description="Kharif, Rabi, or Zaid")
    marketing_year: str = Field("2024-25", description="MSP marketing year e.g. 2024-25")
    msp_price: float = Field(0.0, description="Government Minimum Support Price in ₹/quintal")
    unit: str = Field("Rs/Quintal", description="Unit")
    source: str = Field("Government of India (CACP / DES)", description="Official MSP source")
    effective_from: Optional[str] = None
    effective_to: Optional[str] = None
    available: bool = True
    message: Optional[str] = None


class MarketItem(BaseModel):
    crop_name: str = Field(..., description="Crop name e.g. Groundnut, Soybean (Yellow)")
    unit_price: float = Field(..., description="Modal selling price per unit")
    min_price: float = Field(..., description="Minimum floor price")
    max_price: float = Field(..., description="Maximum ceiling price")
    unit: str = Field("Rs/Quintal", description="Price unit e.g. Rs/Quintal")
    market_status: str = Field("Moderate Market", description="Strong Market, Moderate Market, or Weak Market")
    market_name: str = Field("Local Mandi", description="Mandi/Market location name")
    is_farmer_crop: bool = Field(False, description="Whether this is the farmer's current crop")
    msp_price: Optional[float] = Field(None, description="Government Minimum Support Price")
    market_vs_msp: Optional[float] = Field(None, description="Difference between Market Price and MSP")
    market_vs_msp_label: Optional[str] = Field(None, description="Formatted market vs MSP diff string e.g. '+₹664 / quintal'")


class MarketInsight(BaseModel):
    title: str = Field("🌱 Market Insight", description="Title for insight section")
    content: str = Field(..., description="Short 1-2 sentence market insight summary")
    available: bool = Field(True, description="Whether insight is available")
    generated_at: Optional[str] = Field(None, description="Timestamp when Gemini insight was generated and saved in DB")
    data_source: str = Field("MongoDB Atlas & Gemini Intelligence", description="Data source attribution")
    is_updating: bool = Field(False, description="Whether a background refresh is currently in progress")
    cooldown_seconds_remaining: int = Field(0, description="Cooldown time remaining before next refresh allowed")


class SellingPriceInfo(BaseModel):
    modal_price: float = 0.0
    floor_price: float = 0.0
    ceiling_price: float = 0.0
    unit: str = "Rs/Quintal"
    market_name: str = "Local Mandi"
    available: bool = True
    message: Optional[str] = None
    data_source: str = "MongoDB Atlas mandi_prices"


class YieldSummary(BaseModel):
    predicted: float = 0.0
    lower: float = 0.0
    upper: float = 0.0
    unit: str = "tonnes_per_hectare"
    model_used: str = "satellite"
    confidence_label: str = "90% Confidence Range"
    available: bool = True


class ProfitSummary(BaseModel):
    expected_profit: float = 0.0
    min_profit: float = 0.0
    max_profit: float = 0.0
    safe_planning_min: float = 0.0
    safe_planning_max: float = 0.0
    total_cost: float = 0.0
    revenue_expected: float = 0.0
    revenue_min: float = 0.0
    revenue_max: float = 0.0
    selling_price_per_quintal: float = 0.0
    selling_price_per_tonne: float = 0.0
    farm_area_ha: float = 0.0
    total_yield_tonnes: float = 0.0
    is_loss: bool = False
    display_title: str = "Expected Profit"
    formatted_expected_profit: str = "₹0"
    formatted_min_profit: str = "₹0"
    formatted_max_profit: str = "₹0"


class WalletOverviewResponse(BaseModel):
    farmer_name: str = "Farmer"
    village: str = ""
    district: str = ""
    state: str = ""
    current_crop: str = ""
    farm_area: float = 0.0
    farm_area_unit: str = "acres"
    has_farm_area: bool = True
    has_crop: bool = True
    has_yield_prediction: bool = True
    yield_prediction: YieldSummary
    selling_price: SellingPriceInfo
    msp: Optional[MspInfo] = None
    profit_summary: ProfitSummary
    expenses: List[ExpenseItem] = []
    market_items: List[MarketItem] = []
    market_insight: Optional[MarketInsight] = None
    historical_cost_benchmark_note: str = "Historical/estimated cost benchmark from agricultural dataset"
    data_freshness_note: str = "Market & Cost Data: MongoDB Atlas (2024 Benchmark)"


class AddExpenseRequest(BaseModel):
    category: str = Field(..., description="Category key or custom category name")
    label: str = Field(..., description="Display label for expense")
    amount: float = Field(..., ge=0, description="Amount in INR")


class UpdateExpenseRequest(BaseModel):
    amount: float = Field(..., ge=0, description="New amount in INR")
