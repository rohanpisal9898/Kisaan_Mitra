from datetime import datetime, date
from typing import Optional, Dict
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.models.user import UserRegisterRequest, UserResponse
from app.services.location_service import location_service


class UserService:
    """Service for user registration and management."""

    async def register_user(
        self,
        db: AsyncIOMotorDatabase,
        user_data: UserRegisterRequest,
    ) -> UserResponse:
        """
        Register a new user or update existing user.
        If latitude/longitude are provided (GPS auto-detect), uses them.
        Otherwise, looks up coordinates from the district name.
        """
        lat = user_data.latitude
        lon = user_data.longitude

        # If no GPS coords provided, look up from district
        if lat is None or lon is None:
            coords = await location_service.get_district_coords(
                db, user_data.state, user_data.district
            )
            if coords:
                lat = coords["latitude"]
                lon = coords["longitude"]

        # Check if user with phone number already exists
        existing = await db.users.find_one({"phone_number": user_data.phone_number})
        if existing:
            raise ValueError("ACCOUNT_ALREADY_EXISTS")

        # Normalize Not Sown Yet
        crop_val = user_data.current_crop
        if not crop_val or str(crop_val).strip().lower() in ["not sown yet", "not_sown", "none", "null", ""]:
            crop_val = None
            sowing_date_val = None
        else:
            sowing_date_val = user_data.sowing_date.isoformat() if user_data.sowing_date else None

        # Prepare user document
        user_doc = {
            "phone_number": user_data.phone_number,
            "password": user_data.password,
            "farmer_name": user_data.farmer_name,
            "village": user_data.village,
            "language": user_data.language,
            "state": user_data.state,
            "district": user_data.district,
            "latitude": lat,
            "longitude": lon,
            "current_crop": crop_val,
            "farm_area": user_data.farm_area,
            "farm_area_unit": user_data.farm_area_unit,
            "sowing_date": sowing_date_val,
            "farm_location": user_data.farm_location,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
        }

        # Clean up any leftover orphan records from previous deleted accounts with this phone
        await db.user_expenses.delete_many({"phone_number": user_data.phone_number})
        await db.market_insights.delete_many({"phone_number": user_data.phone_number})
        await db.pest_scans.delete_many({"$or": [{"user_id": user_data.phone_number}, {"phone_number": user_data.phone_number}]})

        # Insert new user document
        await db.users.insert_one(user_doc)

        # Invalidate any lingering dashboard cache
        from app.services.dashboard_service import dashboard_service
        dashboard_service.invalidate_cache(user_data.phone_number)

        # Fetch the user document
        user = await db.users.find_one({"phone_number": user_data.phone_number})
        return self._to_user_response(user)

    async def login_user(
        self,
        db: AsyncIOMotorDatabase,
        phone_number: str,
        password: str,
    ) -> tuple[Optional[UserResponse], str]:
        """
        Authenticate user with phone_number and password.
        Returns (UserResponse, status_code_string).
        """
        user = await db.users.find_one({"phone_number": phone_number})
        if not user:
            return None, "ACCOUNT_NOT_FOUND"

        saved_password = user.get("password")
        # If password is set on user document, verify match
        if saved_password and saved_password != password:
            return None, "INVALID_PASSWORD"

        return self._to_user_response(user), "SUCCESS"

    async def get_user(
        self,
        db: AsyncIOMotorDatabase,
        phone_number: str,
    ) -> Optional[UserResponse]:
        """Get user by phone number."""
        user = await db.users.find_one({"phone_number": phone_number})
        if not user:
            return None
        return self._to_user_response(user)

    async def get_user_by_phone(
        self,
        db: AsyncIOMotorDatabase,
        phone_number: str,
    ) -> Optional[UserResponse]:
        """Alias for get_user."""
        return await self.get_user(db, phone_number)

    async def update_user(
        self,
        db: AsyncIOMotorDatabase,
        phone_number: str,
        update_data: Dict,
    ) -> Optional[UserResponse]:
        """Update user data."""
        user = await db.users.find_one({"phone_number": phone_number})
        if not user:
            return None

        # If location changed, update coordinates
        if "state" in update_data and "district" in update_data:
            coords = await location_service.get_district_coords(
                db, update_data["state"], update_data["district"]
            )
            if coords:
                update_data["latitude"] = coords["latitude"]
                update_data["longitude"] = coords["longitude"]

        # Normalize Not Sown Yet in update_data
        if "current_crop" in update_data:
            crop_val = update_data["current_crop"]
            if not crop_val or str(crop_val).strip().lower() in ["not sown yet", "not_sown", "none", "null", ""]:
                update_data["current_crop"] = None
                update_data["sowing_date"] = None

        update_data["updated_at"] = datetime.utcnow()

        await db.users.update_one(
            {"phone_number": phone_number},
            {"$set": update_data},
        )

        updated_user = await db.users.find_one({"phone_number": phone_number})
        return self._to_user_response(updated_user)

    def _to_user_response(self, user_doc: Dict) -> UserResponse:
        """Convert MongoDB document to UserResponse."""
        curr_crop = user_doc.get("current_crop")
        if curr_crop and str(curr_crop).strip().lower() in ["not sown yet", "not_sown", "none", "null", ""]:
            curr_crop = None

        s_date = user_doc.get("sowing_date")
        if not curr_crop:
            s_date = None
        elif isinstance(s_date, str):
            try:
                s_date = date.fromisoformat(s_date)
            except Exception:
                s_date = None

        return UserResponse(
            id=str(user_doc["_id"]),
            phone_number=user_doc["phone_number"],
            farmer_name=user_doc.get("farmer_name", ""),
            village=user_doc.get("village", ""),
            language=user_doc.get("language", "en"),
            state=user_doc.get("state", ""),
            district=user_doc.get("district", ""),
            latitude=user_doc.get("latitude"),
            longitude=user_doc.get("longitude"),
            current_crop=curr_crop,
            farm_area=user_doc.get("farm_area", 0),
            farm_area_unit=user_doc.get("farm_area_unit", "acres"),
            sowing_date=s_date,
            farm_location=user_doc.get("farm_location", ""),
            created_at=user_doc.get("created_at"),
            updated_at=user_doc.get("updated_at"),
        )


# Singleton instance
user_service = UserService()
