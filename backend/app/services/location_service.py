from motor.motor_asyncio import AsyncIOMotorDatabase
from app.utils.haversine import haversine_distance
from typing import Tuple, List, Optional, Dict


class LocationService:
    """
    Location service that queries MongoDB districts collection.
    All data comes from MongoDB (seeded from district_coords.csv).
    Flutter never touches the CSV directly.
    """

    async def get_all_states(self, db: AsyncIOMotorDatabase) -> List[str]:
        """
        Get list of all unique states from MongoDB.
        Equivalent to: db.districts.distinct("State")
        """
        states = await db.districts.distinct("State")
        return sorted(states)

    async def get_districts_by_state(
        self, db: AsyncIOMotorDatabase, state: str
    ) -> List[str]:
        """
        Get list of districts for a specific state.
        Case-insensitive matching via regex.
        """
        import re
        pattern = re.compile(f"^{re.escape(state)}$", re.IGNORECASE)
        districts = await db.districts.distinct(
            "District", {"State": pattern}
        )
        return sorted(districts)

    async def find_nearest_district(
        self, db: AsyncIOMotorDatabase, lat: float, lon: float
    ) -> Dict:
        """
        Find nearest district using Haversine formula.
        Queries all districts from MongoDB and calculates distances.

        Returns:
            {
                "state": str,
                "district": str,
                "latitude": float,
                "longitude": float,
                "distance_km": float
            }
        """
        cursor = db.districts.find({}, {"_id": 0, "State": 1, "District": 1, "Latitude": 1, "Longitude": 1})

        min_distance = float("inf")
        nearest = None

        async for doc in cursor:
            distance = haversine_distance(
                lat, lon, doc["Latitude"], doc["Longitude"]
            )
            if distance < min_distance:
                min_distance = distance
                nearest = doc

        if nearest is None:
            raise ValueError("No districts found in database. Run seed_districts.py first.")

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
        Get coordinates for a specific district.
        """
        import re
        result = await db.districts.find_one(
            {
                "State": re.compile(f"^{re.escape(state)}$", re.IGNORECASE),
                "District": re.compile(f"^{re.escape(district)}$", re.IGNORECASE),
            },
            {"_id": 0},
        )

        if not result:
            return None

        return {
            "state": result["State"],
            "district": result["District"],
            "latitude": result["Latitude"],
            "longitude": result["Longitude"],
        }


# Singleton instance
location_service = LocationService()
