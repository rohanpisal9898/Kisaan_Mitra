from fastapi import APIRouter, Depends, Query
from typing import Optional, Dict, Any
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.models.dashboard import SownDashboardResponse
from app.services.dashboard_service import dashboard_service

router = APIRouter(prefix="/api/v1/dashboard", tags=["Dashboard"])


@router.get("/overview")
async def get_dashboard_overview(
    phone_number: Optional[str] = Query(None, description="Optional farmer phone number"),
    language: str = Query("English", description="Preferred language for advisories"),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> Dict[str, Any]:
    """
    Dynamic multi-state dashboard handler.
    Determines state automatically:
      - "no_crop": Farmer has no active crop -> Planning Dashboard UI
      - "crop_matured": Farmer's active crop reached maturity -> Maturity Transition Dashboard UI
      - "growing": Farmer's active crop is growing -> Sown Dashboard UI
    """
    return await dashboard_service.get_dashboard_overview(db, phone_number, language)


@router.get("/sown", response_model=SownDashboardResponse)
async def get_sown_dashboard(
    phone_number: Optional[str] = Query(None, description="Optional farmer phone number"),
    language: str = Query("English", description="Preferred language for advisories"),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Single combined endpoint for the Sown-Crop Dashboard.
    """
    return await dashboard_service.get_sown_dashboard(db, phone_number, language)
