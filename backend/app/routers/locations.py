from fastapi import APIRouter, Query, HTTPException, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.services.location_service import location_service

router = APIRouter(prefix="/api/v1/locations", tags=["Locations"])


@router.get("/states")
async def get_all_states(
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Get list of all available states/UTs.

    Flutter calls this to populate the State dropdown.

    Returns:
        {"states": ["Andhra Pradesh", "Assam", ..., "West Bengal"]}
    """
    states = await location_service.get_all_states(db)
    return {"states": states}


@router.get("/districts/{state}")
async def get_districts_by_state(
    state: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Get list of districts for a specific state.

    Flutter calls this when the farmer selects a State.

    Args:
        state: State name (e.g., "Maharashtra")

    Returns:
        {"state": "Maharashtra", "districts": ["Ahmednagar", "Akola", ...]}
    """
    districts = await location_service.get_districts_by_state(db, state)
    if not districts:
        raise HTTPException(status_code=404, detail=f"No districts found for state: {state}")
    return {"state": state, "districts": districts}


@router.get("/nearest-district")
async def get_nearest_district(
    latitude: float = Query(..., description="GPS latitude"),
    longitude: float = Query(..., description="GPS longitude"),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Find nearest district from GPS coordinates using Haversine distance.

    Flutter calls this when the farmer taps "Auto Detect Location".

    Phone GPS → lat + lon → FastAPI → districts collection → nearest district

    Returns:
        {
            "state": "Maharashtra",
            "district": "NASHIK",
            "latitude": 20.0059,
            "longitude": 73.7897,
            "distance_km": 2.34
        }
    """
    try:
        result = await location_service.find_nearest_district(db, latitude, longitude)
        return result
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/district-coords")
async def get_district_coords(
    state: str = Query(..., description="State name"),
    district: str = Query(..., description="District name"),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Get coordinates for a specific state + district pair.

    Returns:
        {"state": "Maharashtra", "district": "NASHIK", "latitude": 20.0059, "longitude": 73.7897}
    """
    result = await location_service.get_district_coords(db, state, district)
    if not result:
        raise HTTPException(status_code=404, detail=f"District {district} not found in {state}")
    return result
