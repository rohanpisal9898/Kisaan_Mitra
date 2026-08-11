from fastapi import APIRouter, Depends, Query
from typing import Optional
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.models.dashboard import SownDashboardResponse
from app.services.dashboard_service import dashboard_service

router = APIRouter(prefix="/api/v1/dashboard", tags=["Dashboard"])


@router.get("/sown", response_model=SownDashboardResponse)
async def get_sown_dashboard(
    phone_number: Optional[str] = Query(None, description="Optional farmer phone number"),
    language: str = Query("English", description="Preferred language for advisories"),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Single combined endpoint for the Sown-Crop Dashboard.

    Backend orchestrates:
      Farmer info -> Weather -> Crop Stage -> Water Status -> Crop Health -> CatBoost Yield -> Gemini Recommendations
    """
    return await dashboard_service.get_sown_dashboard(db, phone_number, language)
