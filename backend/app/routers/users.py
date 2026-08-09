from fastapi import APIRouter, HTTPException, Depends
from typing import Dict
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.models.user import UserRegisterRequest, UserLoginRequest, UserResponse, UserUpdateRequest
from app.services.user_service import user_service

router = APIRouter(prefix="/api/v1/users", tags=["Users"])


@router.post("/login", response_model=UserResponse)
async def login_user(
    login_data: UserLoginRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Authenticate user with phone_number and password.
    """
    user, status = await user_service.login_user(
        db, login_data.phone_number, login_data.password
    )
    if status == "ACCOUNT_NOT_FOUND":
        raise HTTPException(
            status_code=404,
            detail="No account found with this phone number. Please register first.",
        )
    elif status == "INVALID_PASSWORD":
        raise HTTPException(
            status_code=401,
            detail="Incorrect password. Please try again.",
        )
    return user


@router.post("/register", response_model=UserResponse)
async def register_user(
    user_data: UserRegisterRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Register a new user or update existing user.

    Called after the farmer completes onboarding (Step 1 + Step 2).

    **Phone number is the unique identifier.**
    """
    try:
        user = await user_service.register_user(db, user_data)
        return user
    except ValueError as ve:
        if str(ve) == "ACCOUNT_ALREADY_EXISTS":
            raise HTTPException(
                status_code=400,
                detail="An account with this phone number already exists. Please sign in instead.",
            )
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")


@router.get("/{phone_number}", response_model=UserResponse)
async def get_user(
    phone_number: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Get user details by phone number."""
    user = await user_service.get_user(db, phone_number)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.put("/{phone_number}", response_model=UserResponse)
async def update_user(
    phone_number: str,
    update_data: UserUpdateRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Update user data.

    Updatable fields: farmer_name, village, language, state, district,
    latitude, longitude, current_crop, farm_area, farm_area_unit,
    sowing_date, farm_location
    """
    update_dict = update_data.model_dump(exclude_none=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No fields to update")

    # Convert sowing_date to string for MongoDB
    if "sowing_date" in update_dict and update_dict["sowing_date"]:
        update_dict["sowing_date"] = update_dict["sowing_date"].isoformat()

    user = await user_service.update_user(db, phone_number, update_dict)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
