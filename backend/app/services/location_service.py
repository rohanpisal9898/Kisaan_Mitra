from motor.motor_asyncio import AsyncIOMotorDatabase
from app.utils.haversine import haversine_distance
from typing import Tuple, List, Optional, Dict
import re


class LocationService:
    """
    Location service that queries MongoDB districts collection with in-memory caching.
    All data comes from MongoDB (seeded from district_coords.csv).
    """

    def __init__(self):
        self._states_cache: Optional[List[str]] = None
        self._districts_by_state_cache: Dict[str, List[str]] = {}
        self._all_districts_cache: Optional[List[Dict]] = None

    def invalidate_cache(self):
        """Clears in-memory location cache if database is reseeded."""
        self._states_cache = None
        self._districts_by_state_cache.clear()
        self._all_districts_cache = None

    async def get_all_states(self, db: AsyncIOMotorDatabase) -> List[str]:
        """
        Get list of all unique states from cache or MongoDB.
        """
        if self._states_cache is not None:
            return self._states_cache

        if db is not None:
            states = await db.districts.distinct("State")
            if states:
                self._states_cache = sorted(states)
                return self._states_cache

        return [
            "Andhra Pradesh", "Assam", "Bihar", "Chhattisgarh", "Gujarat", "Haryana",
            "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh",
            "Maharashtra", "Odisha", "Punjab", "Rajasthan", "Tamil Nadu", "Telangana",
            "Uttar Pradesh", "Uttarakhand", "West Bengal"
        ]

    async def get_districts_by_state(
        self, db: AsyncIOMotorDatabase, state: str
    ) -> List[str]:
        """
        Get list of districts for a specific state from cache or MongoDB.
        """
        state_key = state.strip().lower()
        if state_key in self._districts_by_state_cache:
            return self._districts_by_state_cache[state_key]

        if db is not None:
            pattern = re.compile(f"^{re.escape(state)}$", re.IGNORECASE)
            districts = await db.districts.distinct(
                "District", {"State": pattern}
            )
            if districts:
                sorted_districts = sorted(districts)
                self._districts_by_state_cache[state_key] = sorted_districts
                return sorted_districts

        return []

    async def _get_all_districts_list(self, db: AsyncIOMotorDatabase) -> List[Dict]:
        if self._all_districts_cache is not None:
            return self._all_districts_cache

        if db is not None:
            cursor = db.districts.find({}, {"_id": 0, "State": 1, "District": 1, "Latitude": 1, "Longitude": 1})
            docs = await cursor.to_list(length=1000)
            if docs:
                self._all_districts_cache = docs
                return self._all_districts_cache

        return []

    async def find_nearest_district(
        self, db: AsyncIOMotorDatabase, lat: float, lon: float
    ) -> Dict:
        """
        Find nearest district using Haversine formula from cached/fetched districts.
        """
        docs = await self._get_all_districts_list(db)

        min_distance = float("inf")
        nearest = None

        for doc in docs:
            distance = haversine_distance(
                lat, lon, doc["Latitude"], doc["Longitude"]
            )
            if distance < min_distance:
                min_distance = distance
                nearest = doc

        if nearest is None:
            # Fallback if DB empty
            return {
                "state": "Maharashtra",
                "district": "Nashik",
                "latitude": 19.9975,
                "longitude": 73.7898,
                "distance_km": 0.0,
            }

        return {
            "state": nearest["State"],
            "district": nearest["District"],
            "latitude": nearest["Latitude"],
            "longitude": nearest["Longitude"],
            "distance_km": round(min_distance, 2),
        }

    async def get_district_coords(
        self, db: AsyncIOMotorDatabase, state: str, district: str
    ) -> Optional[Dict]:
        """
        Get coordinates for a specific district from in-memory cache or MongoDB.
        """
        docs = await self._get_all_districts_list(db)
        state_lower = state.strip().lower()
        district_lower = district.strip().lower()

        for doc in docs:
            if doc.get("State", "").strip().lower() == state_lower and doc.get("District", "").strip().lower() == district_lower:
                return {
                    "state": doc["State"],
                    "district": doc["District"],
                    "latitude": doc["Latitude"],
                    "longitude": doc["Longitude"],
                }

        if db is not None:
            result = await db.districts.find_one(
                {
                    "State": re.compile(f"^{re.escape(state)}$", re.IGNORECASE),
                    "District": re.compile(f"^{re.escape(district)}$", re.IGNORECASE),
                },
                {"_id": 0},
            )
            if result:
                return {
                    "state": result["State"],
                    "district": result["District"],
                    "latitude": result["Latitude"],
                    "longitude": result["Longitude"],
                }

        return None


location_service = LocationService()
