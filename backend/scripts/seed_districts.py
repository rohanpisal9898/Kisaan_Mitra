"""
Seed districts into MongoDB from district_coords.csv.
Also creates required collections and indexes.

Run once when setting up the database:
    python -m scripts.seed_districts

Or from backend directory:
    python scripts/seed_districts.py
"""
import asyncio
import csv
import os
import sys

# Add parent dir to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from motor.motor_asyncio import AsyncIOMotorClient

# Load env manually
MONGODB_URI = None
env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env")
if os.path.exists(env_path):
    with open(env_path, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("MONGODB_URI="):
                MONGODB_URI = line.split("=", 1)[1].strip()

if not MONGODB_URI:
    print("[ERROR] MONGODB_URI not found in .env")
    sys.exit(1)

CSV_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "data",
    "district_coords.csv",
)


async def seed():
    print("=" * 50)
    print("  Kisaan Mitra - Database Seeding")
    print("=" * 50)

    # 1. Connect to MongoDB
    print("\n[1/5] Connecting to MongoDB...")
    try:
        client = AsyncIOMotorClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
        await client.admin.command("ping")
        print("  [OK] Connected to MongoDB Atlas successfully!")
    except Exception as e:
        print(f"  [FAIL] MongoDB connection failed: {e}")
        return

    db = client.kisaan_mitra

    # 2. Create collections
    print("\n[2/5] Creating collections...")
    existing = await db.list_collection_names()
    for coll_name in ["users", "predictions", "tasks", "districts"]:
        if coll_name not in existing:
            await db.create_collection(coll_name)
            print(f"  [OK] Created collection: {coll_name}")
        else:
            print(f"  [OK] Collection already exists: {coll_name}")

    # 3. Create indexes
    print("\n[3/5] Creating indexes...")
    try:
        await db.users.create_index("phone_number", unique=True)
        print("  [OK] Created unique index on users.phone_number")
    except Exception as e:
        print(f"  [WARN] Index on users.phone_number: {e}")

    try:
        await db.predictions.create_index("expires_at", expireAfterSeconds=0)
        print("  [OK] Created TTL index on predictions.expires_at")
    except Exception as e:
        print(f"  [WARN] TTL index on predictions.expires_at: {e}")

    try:
        await db.districts.create_index(
            [("State", 1), ("District", 1)], unique=True
        )
        print("  [OK] Created compound index on districts(State, District)")
    except Exception as e:
        print(f"  [WARN] Index on districts: {e}")

    # 4. Seed districts from CSV
    print("\n[4/5] Seeding districts from district_coords.csv...")
    if not os.path.exists(CSV_PATH):
        print(f"  [FAIL] CSV file not found: {CSV_PATH}")
        return

    # Read CSV
    districts = []
    with open(CSV_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            districts.append(
                {
                    "State": row["State"].strip(),
                    "District": row["District"].strip(),
                    "Latitude": float(row["Latitude"]),
                    "Longitude": float(row["Longitude"]),
                }
            )

    print(f"  Read {len(districts)} districts from CSV")

    # Clear existing districts and re-seed
    deleted = await db.districts.delete_many({})
    print(f"  Cleared {deleted.deleted_count} existing district records")

    # Insert all districts
    if districts:
        result = await db.districts.insert_many(districts)
        print(f"  [OK] Inserted {len(result.inserted_ids)} districts into MongoDB")

    # 5. Verify seeding
    print("\n[5/5] Verification...")
    total_districts = await db.districts.count_documents({})
    states = await db.districts.distinct("State")
    print(f"  Total districts in DB: {total_districts}")
    print(f"  Total unique states: {len(states)}")
    print(f"  Sample states: {', '.join(sorted(states)[:5])}...")

    # List all collections
    collections = await db.list_collection_names()
    print(f"\n  Collections in database: {', '.join(sorted(collections))}")

    client.close()
    print("\n" + "=" * 50)
    print("  Seeding completed successfully!")
    print("=" * 50)


if __name__ == "__main__":
    asyncio.run(seed())
