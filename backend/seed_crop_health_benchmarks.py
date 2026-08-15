"""
Idempotent Seeding Script for Crop Health Benchmarks in MongoDB.

Reads backend/data/crop_health_benchmarks.json and upserts each (crop_id, stage_id)
record into the `crop_health_benchmarks` collection.
"""

import json
import asyncio
from pathlib import Path
from motor.motor_asyncio import AsyncIOMotorClient
from app.config import get_settings

settings = get_settings()


async def seed_benchmarks():
    json_path = Path(__file__).parent / "data" / "crop_health_benchmarks.json"
    if not json_path.exists():
        print(f"[SEED ERROR] Benchmark JSON file not found at {json_path}")
        return

    with open(json_path, "r", encoding="utf-8") as f:
        benchmarks_data = json.load(f)

    client = AsyncIOMotorClient(settings.mongodb_uri)
    db = client.kisaan_mitra
    collection = db.crop_health_benchmarks

    # Ensure unique compound index on (crop_id, stage_id)
    await collection.create_index([("crop_id", 1), ("stage_id", 1)], unique=True)

    upserted_count = 0
    for crop_id, stages in benchmarks_data.items():
        for stage_id, stage_bench in stages.items():
            doc = {
                "crop_id": crop_id,
                "stage_id": stage_id,
                "indices": stage_bench.get("indices", {}),
                "trend": stage_bench.get("trend", {}),
                "evidence": stage_bench.get("evidence", {}),
            }
            res = await collection.update_one(
                {"crop_id": crop_id, "stage_id": stage_id},
                {"$set": doc},
                upsert=True,
            )
            upserted_count += 1

    print(f"[SEED SUCCESS] Idempotently seeded {upserted_count} crop-stage benchmark records into MongoDB collection 'crop_health_benchmarks'.")
    client.close()


if __name__ == "__main__":
    asyncio.run(seed_benchmarks())
