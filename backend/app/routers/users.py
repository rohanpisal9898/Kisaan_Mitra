from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks, status
from typing import Dict, Any
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.models.user import (
    UserRegisterRequest,
    UserLoginRequest,
    UserResponse,
    UserUpdateRequest,
    AuthTokenResponse,
    RefreshTokenRequest,
    RefreshTokenResponse,
)
from app.services.user_service import user_service
from app.services.dashboard_service import dashboard_service
from app.services.wallet_service import wallet_service
from app.services.n8n_notifications import n8n_notification_service
from app.utils.auth import (
    create_access_token,
    create_refresh_token,
    decode_token,
    get_current_user,
)

router = APIRouter(prefix="/api/v1/users", tags=["Users"])


@router.post("/login", response_model=AuthTokenResponse)
async def login_user(
    login_data: UserLoginRequest,
    background_tasks: BackgroundTasks,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Authenticate user with phone_number and password.
    Returns access_token, refresh_token, and UserResponse.
    Schedules an asynchronous background task to refresh Gemini market insight into MongoDB.
    """
    user, login_status = await user_service.login_user(
        db, login_data.phone_number, login_data.password
    )
    if login_status == "ACCOUNT_NOT_FOUND":
        raise HTTPException(
            status_code=404,
            detail="No account found with this phone number. Please register first.",
        )
    elif login_status == "INVALID_PASSWORD":
        raise HTTPException(
            status_code=401,
            detail="Incorrect password. Please try again.",
        )

    # Generate JWT tokens
    token_payload = {
        "sub": user.phone_number,
        "user_id": str(user.id),
        "phone_number": user.phone_number,
    }
    access_token = create_access_token(token_payload)
    refresh_token = create_refresh_token(token_payload)

    # Asynchronous login-triggered Gemini market insight refresh
    background_tasks.add_task(
        wallet_service.refresh_gemini_market_insight_async, db, user.phone_number
    )
    # Trigger n8n background notification
    background_tasks.add_task(
        n8n_notification_service.trigger_farmer_notification, db, str(user.id)
    )

    return AuthTokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=user,
    )


@router.post("/register", response_model=AuthTokenResponse)
async def register_user(
    user_data: UserRegisterRequest,
    background_tasks: BackgroundTasks,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Register a new user.
    Returns access_token, refresh_token, and UserResponse.
    Schedules an asynchronous background task to refresh Gemini market insight into MongoDB.
    """
    try:
        user = await user_service.register_user(db, user_data)

        token_payload = {
            "sub": user.phone_number,
            "user_id": str(user.id),
            "phone_number": user.phone_number,
        }
        access_token = create_access_token(token_payload)
        refresh_token = create_refresh_token(token_payload)

        background_tasks.add_task(
            wallet_service.refresh_gemini_market_insight_async, db, user.phone_number
        )
        # Trigger n8n background notification
        background_tasks.add_task(
            n8n_notification_service.trigger_farmer_notification, db, str(user.id)
        )

        return AuthTokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            user=user,
        )
    except ValueError as ve:
        if str(ve) == "ACCOUNT_ALREADY_EXISTS":
            raise HTTPException(
                status_code=400,
                detail="An account with this phone number already exists. Please sign in instead.",
            )
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")


@router.post("/refresh", response_model=RefreshTokenResponse)
async def refresh_session_token(
    body: RefreshTokenRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Exchange a valid refresh token for a fresh access token (and rotated refresh token).
    Ensures user still exists in MongoDB.
    """
    payload = decode_token(body.refresh_token)
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="INVALID_REFRESH_TOKEN",
        )

    phone_number = payload.get("sub") or payload.get("phone_number")
    if not phone_number:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="INVALID_TOKEN_PAYLOAD",
        )

    user = await user_service.get_user(db, phone_number)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="USER_NOT_FOUND_OR_DELETED",
        )

    token_payload = {
        "sub": user.phone_number,
        "user_id": str(user.id),
        "phone_number": user.phone_number,
    }
    new_access_token = create_access_token(token_payload)
    new_refresh_token = create_refresh_token(token_payload)

    return RefreshTokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        token_type="bearer",
    )


@router.get("/me", response_model=UserResponse)
async def get_authenticated_user_profile(
    current_user: UserResponse = Depends(get_current_user),
):
    """
    Lightweight authenticated session validation endpoint.
    Used on app startup and periodic foreground validation.
    """
    return current_user


@router.put("/me", response_model=UserResponse)
async def update_authenticated_user_profile(
    update_data: UserUpdateRequest,
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Update profile of the authenticated user.
    """
    update_dict = update_data.model_dump(exclude_none=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No fields to update")

    if "sowing_date" in update_dict and update_dict["sowing_date"]:
        update_dict["sowing_date"] = update_dict["sowing_date"].isoformat()

    updated_user = await user_service.update_user(db, current_user.phone_number, update_dict)
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    dashboard_service.invalidate_cache(current_user.phone_number)
    return updated_user


@router.delete("/me")
async def delete_authenticated_account(
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Permanently delete the authenticated user's account and associated user-scoped records.
    Invalidates any subsequent requests with this user's token.
    """
    phone = current_user.phone_number

    # 1. Delete user document
    await db.users.delete_one({"phone_number": phone})

    # 2. Delete user's saved expenses
    await db.user_expenses.delete_many({"phone_number": phone})

    # 3. Delete user's market insights
    await db.market_insights.delete_many({"phone_number": phone})

    # 4. Delete user's pest detection scans
    await db.pest_scans.delete_many({"$or": [{"user_id": phone}, {"phone_number": phone}]})

    # 5. Invalidate cached dashboard
    dashboard_service.invalidate_cache(phone)

    return {
        "status": "success",
        "message": "User account and associated data have been permanently deleted.",
    }


@router.delete("/{phone_number}")
async def delete_user_by_phone(
    phone_number: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Delete user and all associated records by phone number."""
    phone = phone_number.strip()
    await db.users.delete_one({"phone_number": phone})
    await db.user_expenses.delete_many({"phone_number": phone})
    await db.market_insights.delete_many({"phone_number": phone})
    await db.pest_scans.delete_many({"$or": [{"user_id": phone}, {"phone_number": phone}]})
    dashboard_service.invalidate_cache(phone)

    return {
        "status": "success",
        "message": f"User {phone} and associated data have been permanently deleted.",
    }


@router.get("/{phone_number}", response_model=UserResponse)
async def get_user(
    phone_number: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Get user details by phone number (backward compatible)."""
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
    """Update user data (backward compatible)."""
    update_dict = update_data.model_dump(exclude_none=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No fields to update")

    if "sowing_date" in update_dict and update_dict["sowing_date"]:
        update_dict["sowing_date"] = update_dict["sowing_date"].isoformat()

    user = await user_service.update_user(db, phone_number, update_dict)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    dashboard_service.invalidate_cache(phone_number)
    return user
