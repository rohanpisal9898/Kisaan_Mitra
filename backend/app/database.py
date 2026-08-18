from motor.motor_asyncio import AsyncIOMotorClient
from app.config import get_settings

settings = get_settings()


class Database:
    client: AsyncIOMotorClient = None


db = Database()


async def get_database():
    """Get MongoDB database instance."""
    return db.client.kisaan_mitra


async def connect_to_mongo():
    """Connect to MongoDB Atlas."""
    db.client = AsyncIOMotorClient(settings.mongodb_uri)
    database = await get_database()

    # Create indexes
    await database.users.create_index("phone_number", unique=True)
    await database.districts.create_index(
        [("State", 1), ("District", 1)], unique=True
    )
    await database.predictions.create_index("expires_at", expireAfterSeconds=0)
    await database.pest_scans.create_index("scan_id", unique=True)

    # Production Financial Shield Indexes
    await database.crop_costs.create_index(
        [("crop", 1), ("state", 1), ("season", 1)], unique=True
    )
    await database.mandi_prices.create_index(
        [("crop", 1), ("state", 1), ("season", 1)], unique=True
    )
    await database.msp_prices.create_index(
        [("crop", 1), ("season", 1), ("marketing_year", 1)], unique=True
    )
    await database.user_expenses.create_index("phone_number", unique=True)
    await database.market_insights.create_index("phone_number", unique=True)
    await database.schemes_cache.create_index(
        [("state", 1), ("crop", 1), ("language", 1)], unique=True
    )
    await database.schemes_cache.create_index("expires_at", expireAfterSeconds=0)
    print("[OK] Connected to MongoDB Atlas & Verified Indexes")


async def close_mongo_connection():
    """Close MongoDB connection."""
    db.client.close()
    print("[OK] Closed MongoDB connection")
