"""
Seed script for crop_profiles collection.

Seeds all 9 supported oilseed crops with:
- Growth stage durations (FAO-based)
- Kc coefficients (FAO-56)
- Localized display names (en, hi, mr, gu, ta, te)
- Satellite health reference profiles per stage

Run once:
    python scripts/seed_crop_profiles.py
"""

import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from app.config import get_settings

settings = get_settings()

# ── All 9 crop profiles ────────────────────────────────────────

CROP_PROFILES = [
    {
        "crop_id": "groundnut",
        "display_names": {
            "en": "Groundnut",
            "hi": "मूंगफली",
            "mr": "भुईमूग",
            "gu": "મગફળી",
            "ta": "நிலக்கடலை",
            "te": "వేరుశెనగ",
        },
        "growth_duration_days": 120,
        "stages": {
            "initial": 25,
            "development": 35,
            "mid_season": 40,
            "late_season": 20,
        },
        "kc": {"initial": 0.40, "mid": 1.15, "end": 0.60},
        "kc_status": "established",
        "kc_confidence": "high",
        "health_reference": {
            "initial":    {"ndvi": [0.15, 0.30], "ndre": [0.08, 0.18], "evi": [0.10, 0.25], "ndmi": [-0.10, 0.10]},
            "development":{"ndvi": [0.30, 0.60], "ndre": [0.18, 0.35], "evi": [0.25, 0.50], "ndmi": [0.05, 0.25]},
            "mid_season": {"ndvi": [0.55, 0.80], "ndre": [0.30, 0.50], "evi": [0.45, 0.70], "ndmi": [0.15, 0.35]},
            "late_season":{"ndvi": [0.30, 0.55], "ndre": [0.15, 0.30], "evi": [0.20, 0.45], "ndmi": [0.00, 0.20]},
        },
    },
    {
        "crop_id": "soybean",
        "display_names": {
            "en": "Soyabean",
            "hi": "सोयाबीन",
            "mr": "सोयाबीन",
            "gu": "સોયાબીન",
            "ta": "சோயாபீன்",
            "te": "సోయాబీన్",
        },
        "growth_duration_days": 104,
        "stages": {
            "initial": 16,
            "development": 28,
            "mid_season": 40,
            "late_season": 20,
        },
        "kc": {"initial": 0.35, "mid": 1.15, "end": 0.50},
        "kc_status": "established",
        "kc_confidence": "high",
        "health_reference": {
            "initial":    {"ndvi": [0.12, 0.28], "ndre": [0.06, 0.16], "evi": [0.08, 0.22], "ndmi": [-0.10, 0.08]},
            "development":{"ndvi": [0.28, 0.58], "ndre": [0.16, 0.33], "evi": [0.22, 0.48], "ndmi": [0.03, 0.22]},
            "mid_season": {"ndvi": [0.55, 0.82], "ndre": [0.30, 0.52], "evi": [0.45, 0.72], "ndmi": [0.15, 0.38]},
            "late_season":{"ndvi": [0.28, 0.52], "ndre": [0.14, 0.28], "evi": [0.18, 0.42], "ndmi": [-0.02, 0.18]},
        },
    },
    {
        "crop_id": "castor",
        "display_names": {
            "en": "Castor seed",
            "hi": "अरंडी",
            "mr": "एरंडी",
            "gu": "દિવેલા",
            "ta": "ஆமணக்கு",
            "te": "ఆముదం",
        },
        "growth_duration_days": 150,
        "stages": {
            "initial": 25,
            "development": 40,
            "mid_season": 55,
            "late_season": 30,
        },
        "kc": {"initial": 0.35, "mid": 1.15, "end": 0.55},
        "kc_status": "established",
        "kc_confidence": "high",
        "health_reference": {
            "initial":    {"ndvi": [0.12, 0.25], "ndre": [0.06, 0.15], "evi": [0.08, 0.20], "ndmi": [-0.10, 0.08]},
            "development":{"ndvi": [0.25, 0.55], "ndre": [0.15, 0.32], "evi": [0.20, 0.45], "ndmi": [0.02, 0.20]},
            "mid_season": {"ndvi": [0.50, 0.78], "ndre": [0.28, 0.48], "evi": [0.40, 0.68], "ndmi": [0.12, 0.32]},
            "late_season":{"ndvi": [0.25, 0.48], "ndre": [0.12, 0.25], "evi": [0.15, 0.38], "ndmi": [-0.05, 0.15]},
        },
    },
    {
        "crop_id": "sunflower",
        "display_names": {
            "en": "Sunflower",
            "hi": "सूरजमुखी",
            "mr": "सूर्यफूल",
            "gu": "સૂર્યમુખી",
            "ta": "சூரியகாந்தி",
            "te": "పొద్దుతిరుగుడు",
        },
        "growth_duration_days": 120,
        "stages": {
            "initial": 20,
            "development": 35,
            "mid_season": 45,
            "late_season": 20,
        },
        "kc": {"initial": 0.35, "mid": 1.15, "end": 0.35},
        "kc_status": "established",
        "kc_confidence": "high",
        "health_reference": {
            "initial":    {"ndvi": [0.12, 0.28], "ndre": [0.06, 0.16], "evi": [0.08, 0.22], "ndmi": [-0.10, 0.08]},
            "development":{"ndvi": [0.28, 0.58], "ndre": [0.16, 0.33], "evi": [0.22, 0.48], "ndmi": [0.03, 0.22]},
            "mid_season": {"ndvi": [0.55, 0.80], "ndre": [0.30, 0.50], "evi": [0.45, 0.70], "ndmi": [0.15, 0.35]},
            "late_season":{"ndvi": [0.25, 0.48], "ndre": [0.12, 0.25], "evi": [0.15, 0.38], "ndmi": [-0.05, 0.15]},
        },
    },
    {
        "crop_id": "sesame",
        "display_names": {
            "en": "Sesamum",
            "hi": "तिल",
            "mr": "तीळ",
            "gu": "તલ",
            "ta": "எள்",
            "te": "నువ్వులు",
        },
        "growth_duration_days": 100,
        "stages": {
            "initial": 20,
            "development": 25,
            "mid_season": 35,
            "late_season": 20,
        },
        "kc": {"initial": 0.35, "mid": 1.10, "end": 0.25},
        "kc_status": "established",
        "kc_confidence": "high",
        "health_reference": {
            "initial":    {"ndvi": [0.10, 0.25], "ndre": [0.05, 0.14], "evi": [0.07, 0.20], "ndmi": [-0.12, 0.06]},
            "development":{"ndvi": [0.25, 0.52], "ndre": [0.14, 0.30], "evi": [0.20, 0.42], "ndmi": [0.01, 0.18]},
            "mid_season": {"ndvi": [0.48, 0.72], "ndre": [0.25, 0.42], "evi": [0.38, 0.62], "ndmi": [0.10, 0.28]},
            "late_season":{"ndvi": [0.20, 0.42], "ndre": [0.10, 0.22], "evi": [0.12, 0.32], "ndmi": [-0.08, 0.12]},
        },
    },
    {
        "crop_id": "rapeseed_mustard",
        "display_names": {
            "en": "Rapeseed & Mustard",
            "hi": "सरसों",
            "mr": "मोहरी",
            "gu": "રાઈ / સરસવ",
            "ta": "கடுகு",
            "te": "ఆవాలు",
        },
        "growth_duration_days": 130,
        "stages": {
            "initial": 20,
            "development": 35,
            "mid_season": 50,
            "late_season": 25,
        },
        "kc": {"initial": 0.35, "mid": 1.10, "end": 0.35},
        "kc_status": "established",
        "kc_confidence": "high",
        "health_reference": {
            "initial":    {"ndvi": [0.12, 0.28], "ndre": [0.06, 0.16], "evi": [0.08, 0.22], "ndmi": [-0.10, 0.08]},
            "development":{"ndvi": [0.28, 0.55], "ndre": [0.16, 0.32], "evi": [0.22, 0.45], "ndmi": [0.03, 0.20]},
            "mid_season": {"ndvi": [0.52, 0.78], "ndre": [0.28, 0.48], "evi": [0.42, 0.68], "ndmi": [0.12, 0.32]},
            "late_season":{"ndvi": [0.25, 0.48], "ndre": [0.12, 0.25], "evi": [0.15, 0.38], "ndmi": [-0.05, 0.15]},
        },
    },
    {
        "crop_id": "linseed",
        "display_names": {
            "en": "Linseed",
            "hi": "अलसी",
            "mr": "जवस / अळशी",
            "gu": "અળસી",
            "ta": "ஆளிவிதை",
            "te": "అవిసె",
        },
        "growth_duration_days": 140,
        "stages": {
            "initial": 25,
            "development": 35,
            "mid_season": 50,
            "late_season": 30,
        },
        "kc": {"initial": 0.35, "mid": 1.10, "end": 0.25},
        "kc_status": "established",
        "kc_confidence": "high",
        "health_reference": {
            "initial":    {"ndvi": [0.10, 0.25], "ndre": [0.05, 0.14], "evi": [0.07, 0.20], "ndmi": [-0.12, 0.06]},
            "development":{"ndvi": [0.25, 0.52], "ndre": [0.14, 0.30], "evi": [0.20, 0.42], "ndmi": [0.01, 0.18]},
            "mid_season": {"ndvi": [0.48, 0.72], "ndre": [0.25, 0.42], "evi": [0.38, 0.62], "ndmi": [0.10, 0.28]},
            "late_season":{"ndvi": [0.20, 0.40], "ndre": [0.10, 0.20], "evi": [0.12, 0.30], "ndmi": [-0.08, 0.12]},
        },
    },
    {
        "crop_id": "safflower",
        "display_names": {
            "en": "Safflower",
            "hi": "कुसुम",
            "mr": "करडई",
            "gu": "કુસુમ",
            "ta": "குசும்பா",
            "te": "కుసుమ",
        },
        "growth_duration_days": 140,
        "stages": {
            "initial": 25,
            "development": 35,
            "mid_season": 50,
            "late_season": 30,
        },
        "kc": {"initial": 0.35, "mid": 1.10, "end": 0.25},
        "kc_status": "established",
        "kc_confidence": "high",
        "health_reference": {
            "initial":    {"ndvi": [0.10, 0.25], "ndre": [0.05, 0.14], "evi": [0.07, 0.20], "ndmi": [-0.12, 0.06]},
            "development":{"ndvi": [0.25, 0.52], "ndre": [0.14, 0.30], "evi": [0.20, 0.42], "ndmi": [0.01, 0.18]},
            "mid_season": {"ndvi": [0.48, 0.72], "ndre": [0.25, 0.42], "evi": [0.38, 0.62], "ndmi": [0.10, 0.28]},
            "late_season":{"ndvi": [0.20, 0.40], "ndre": [0.10, 0.20], "evi": [0.12, 0.30], "ndmi": [-0.08, 0.12]},
        },
    },
    {
        "crop_id": "niger",
        "display_names": {
            "en": "Niger seed",
            "hi": "रामतिल",
            "mr": "खुरासणी / काळेतीळ",
            "gu": "રામતલ",
            "ta": "பயறு எள்",
            "te": "వెర్రినువ్వులు",
        },
        "growth_duration_days": 110,
        "stages": {
            "initial": 20,
            "development": 30,
            "mid_season": 40,
            "late_season": 20,
        },
        # Provisional proxy — not FAO-validated for Niger seed
        "kc": {"initial": 0.35, "mid": 1.05, "end": 0.30},
        "kc_status": "provisional_proxy",
        "kc_confidence": "low",
        "health_reference": {
            "initial":    {"ndvi": [0.10, 0.25], "ndre": [0.05, 0.14], "evi": [0.07, 0.20], "ndmi": [-0.12, 0.06]},
            "development":{"ndvi": [0.25, 0.50], "ndre": [0.14, 0.28], "evi": [0.20, 0.40], "ndmi": [0.01, 0.16]},
            "mid_season": {"ndvi": [0.45, 0.68], "ndre": [0.22, 0.38], "evi": [0.35, 0.58], "ndmi": [0.08, 0.25]},
            "late_season":{"ndvi": [0.18, 0.38], "ndre": [0.08, 0.18], "evi": [0.10, 0.28], "ndmi": [-0.10, 0.10]},
        },
    },
]


async def seed_crop_profiles():
    """Insert or update all crop profiles in MongoDB."""
    client = AsyncIOMotorClient(settings.mongodb_uri)
    db = client.kisaan_mitra

    # Create unique index
    await db.crop_profiles.create_index("crop_id", unique=True)

    inserted = 0
    updated = 0

    for profile in CROP_PROFILES:
        result = await db.crop_profiles.update_one(
            {"crop_id": profile["crop_id"]},
            {"$set": profile},
            upsert=True,
        )
        if result.upserted_id:
            inserted += 1
        elif result.modified_count > 0:
            updated += 1

    print(f"[OK] Crop profiles seeded: {inserted} inserted, {updated} updated")
    print(f"[OK] Total crop profiles in DB: {await db.crop_profiles.count_documents({})}")

    # List all crops
    async for crop in db.crop_profiles.find({}, {"crop_id": 1, "display_names.en": 1}):
        print(f"  - {crop['crop_id']}: {crop['display_names']['en']}")

    client.close()


if __name__ == "__main__":
    asyncio.run(seed_crop_profiles())
