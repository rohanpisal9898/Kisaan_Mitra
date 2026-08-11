"""
Production Dataset Importer Script for Kisaan Mitra.

Imports and seeds:
  1. kisaan_mitra.csv -> MongoDB `crop_costs` collection
  2. mandi_prices_2024.csv -> MongoDB `mandi_prices` collection
  3. Official MSP dataset -> MongoDB `msp_prices` collection

Idempotent: Uses compound unique keys and bulk upsert operations.
Running this script multiple times guarantees zero record duplication.

Usage:
  python scripts/import_datasets.py
"""

import sys
import os
import math
import asyncio
import pandas as pd
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import UpdateOne

# Ensure UTF-8 output encoding for Windows terminal
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from app.config import get_settings

settings = get_settings()

DATA_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data"))
KISAAN_CSV_PATH = os.path.join(DATA_DIR, "kisaan_mitra.csv")
MANDI_CSV_PATH = os.path.join(DATA_DIR, "mandi_prices_2024.csv")


def normalize_crop_name(raw_crop: str) -> str:
    """Standardizes crop names across all datasets."""
    c = (raw_crop or "").strip().lower()
    if "ground" in c or "moongphali" in c:
        return "Groundnut"
    if "soya" in c or "soybean" in c:
        return "Soybean"
    if "castor" in c:
        return "Castor seed"
    if "sunflower" in c or "surajmukhi" in c:
        return "Sunflower"
    if "sesame" in c or "til" in c or "sesamum" in c:
        return "Sesamum"
    if "mustard" in c or "rapeseed" in c or "sarson" in c:
        return "Rapeseed &Mustard"
    if "linseed" in c or "alsi" in c:
        return "Linseed"
    if "safflower" in c or "kusum" in c:
        return "Safflower"
    if "niger" in c:
        return "Niger seed"
    return raw_crop.strip().title() if raw_crop else "Soybean"


def normalize_state_name(raw_state: str) -> str:
    """Standardizes state names across all datasets."""
    s = (raw_state or "").strip()
    if not s:
        return "All India"
    return s.title()


def normalize_season(raw_season: str) -> str:
    """Standardizes crop seasons."""
    s = (raw_season or "").strip().title()
    if s in ["Kharif", "Rabi", "Zaid"]:
        return s
    return "Kharif"


# Official Government of India Minimum Support Prices (MSP) Seed Data for Oilseeds
MSP_SEED_DATA = [
    {"crop": "Groundnut", "commodity": "Groundnut in shell", "season": "Kharif", "marketing_year": "2024-25", "msp_price": 6783.0, "unit": "Rs/Quintal", "effective_from": "2024-06-01", "effective_to": "2025-05-31"},
    {"crop": "Soybean", "commodity": "Soybean (Yellow)", "season": "Kharif", "marketing_year": "2024-25", "msp_price": 4892.0, "unit": "Rs/Quintal", "effective_from": "2024-06-01", "effective_to": "2025-05-31"},
    {"crop": "Sesamum", "commodity": "Sesamum (Til)", "season": "Kharif", "marketing_year": "2024-25", "msp_price": 9267.0, "unit": "Rs/Quintal", "effective_from": "2024-06-01", "effective_to": "2025-05-31"},
    {"crop": "Sunflower", "commodity": "Sunflower Seed", "season": "Kharif", "marketing_year": "2024-25", "msp_price": 7280.0, "unit": "Rs/Quintal", "effective_from": "2024-06-01", "effective_to": "2025-05-31"},
    {"crop": "Rapeseed &Mustard", "commodity": "Rapeseed & Mustard", "season": "Rabi", "marketing_year": "2024-25", "msp_price": 5650.0, "unit": "Rs/Quintal", "effective_from": "2024-10-01", "effective_to": "2025-09-30"},
    {"crop": "Castor seed", "commodity": "Castor seed", "season": "Kharif", "marketing_year": "2024-25", "msp_price": 6575.0, "unit": "Rs/Quintal", "effective_from": "2024-06-01", "effective_to": "2025-05-31"},
    {"crop": "Linseed", "commodity": "Linseed", "season": "Rabi", "marketing_year": "2024-25", "msp_price": 5650.0, "unit": "Rs/Quintal", "effective_from": "2024-10-01", "effective_to": "2025-09-30"},
    {"crop": "Safflower", "commodity": "Safflower", "season": "Rabi", "marketing_year": "2024-25", "msp_price": 5940.0, "unit": "Rs/Quintal", "effective_from": "2024-10-01", "effective_to": "2025-09-30"},
    {"crop": "Niger seed", "commodity": "Niger seed", "season": "Kharif", "marketing_year": "2024-25", "msp_price": 8717.0, "unit": "Rs/Quintal", "effective_from": "2024-06-01", "effective_to": "2025-05-31"},
]


async def import_datasets():
    print("=" * 65, flush=True)
    print("  KISAAN MITRA — IDEMPOTENT DATASET IMPORTER", flush=True)
    print("=" * 65, flush=True)

    client = AsyncIOMotorClient(settings.mongodb_uri)
    db = client.kisaan_mitra
    now_iso = datetime.now().isoformat()

    # 1. Ensure Compound Unique Indexes
    await db.crop_costs.create_index([("crop", 1), ("state", 1), ("season", 1)], unique=True)
    await db.mandi_prices.create_index([("crop", 1), ("state", 1), ("season", 1)], unique=True)
    await db.msp_prices.create_index([("crop", 1), ("season", 1), ("marketing_year", 1)], unique=True)
    await db.user_expenses.create_index("phone_number", unique=True)
    await db.market_insights.create_index("phone_number", unique=True)

    # ─── PART 1: Import crop_costs from kisaan_mitra.csv ────────────
    print("\n[PART 1] Importing Crop Costs from kisaan_mitra.csv...", flush=True)
    cost_ops = []
    cost_read = 0

    if os.path.exists(KISAAN_CSV_PATH):
        df_cost = pd.read_csv(KISAAN_CSV_PATH)
        cost_read = len(df_cost)

        for _, row in df_cost.iterrows():
            try:
                crop = normalize_crop_name(str(row.get("crop_name", "")))
                state = normalize_state_name(str(row.get("state_name", "")))
                season = "Kharif"

                def get_float(col):
                    v = row.get(col, 0.0)
                    try:
                        return float(v) if not math.isnan(float(v)) else 0.0
                    except:
                        return 0.0

                opr_cost_seed = get_float("opr_cost_seed")
                opr_cost_fertilizer = get_float("opr_cost_fertilizer")
                opr_cost_labour = (
                    get_float("opr_cost_hmn_lab_family") +
                    get_float("opr_cost_hmn_lab_attached") +
                    get_float("opr_cost_hmn_lab_casual") +
                    get_float("opr_cost_ani_lab_hired") +
                    get_float("opr_cost_ani_lab_owned")
                )
                opr_cost_machinery = get_float("opr_cost_mch_lab_hired") + get_float("opr_cost_mch_lab_owned")
                opr_cost_insecticides = get_float("opr_cost_insecticides")
                opr_cost_irrigation_chrg = get_float("opr_cost_irrigation_chrg")
                opr_cost_other = (
                    get_float("opr_cost_manure") +
                    get_float("opr_cost_misc") +
                    get_float("opr_cost_interest_on_wrk_cap") +
                    get_float("opr_cost_crop_insurance")
                )
                opr_cost_total = get_float("opr_cost") or (
                    opr_cost_seed + opr_cost_fertilizer + opr_cost_labour +
                    opr_cost_machinery + opr_cost_insecticides + opr_cost_irrigation_chrg + opr_cost_other
                )

                doc = {
                    "crop": crop,
                    "state": state,
                    "district": "All",
                    "season": season,
                    "opr_cost_seed": round(opr_cost_seed, 2),
                    "opr_cost_fertilizer": round(opr_cost_fertilizer, 2),
                    "opr_cost_labour": round(opr_cost_labour, 2),
                    "opr_cost_machinery": round(opr_cost_machinery, 2),
                    "opr_cost_insecticides": round(opr_cost_insecticides, 2),
                    "opr_cost_irrigation_chrg": round(opr_cost_irrigation_chrg, 2),
                    "opr_cost_other": round(opr_cost_other, 2),
                    "opr_cost_total": round(opr_cost_total, 2),
                    "source": "kisaan_mitra.csv",
                    "imported_at": now_iso,
                    "updated_at": now_iso,
                }

                cost_ops.append(
                    UpdateOne(
                        {"crop": crop, "state": state, "season": season},
                        {"$set": doc},
                        upsert=True
                    )
                )
            except Exception as e:
                pass

        if cost_ops:
            res = await db.crop_costs.bulk_write(cost_ops)
            cost_inserted = res.upserted_count
            cost_updated = res.modified_count
        else:
            cost_inserted = cost_updated = 0
    else:
        print(f"  [WARNING] {KISAAN_CSV_PATH} not found!", flush=True)
        cost_inserted = cost_updated = 0

    # ─── PART 2: Import mandi_prices from mandi_prices_2024.csv ──────
    print("\n[PART 2] Importing Mandi Prices from mandi_prices_2024.csv...", flush=True)
    mandi_ops = []
    mandi_read = 0

    if os.path.exists(MANDI_CSV_PATH):
        df_mandi = pd.read_csv(MANDI_CSV_PATH)
        mandi_read = len(df_mandi)

        for _, row in df_mandi.iterrows():
            try:
                crop = normalize_crop_name(str(row.get("Crop", "")))
                state = normalize_state_name(str(row.get("State", "")))
                season = normalize_season(str(row.get("Season", "Kharif")))

                floor_price = float(row.get("Floor_Price", 0.0))
                modal_price = float(row.get("Modal_Price", 0.0))
                ceiling_price = float(row.get("Ceiling_Price", 0.0))
                unit = str(row.get("Unit", "Rs/Quintal")).strip()

                doc = {
                    "crop": crop,
                    "state": state,
                    "district": "All",
                    "market": f"{state} Mandi",
                    "season": season,
                    "floor_price": round(floor_price, 2),
                    "modal_price": round(modal_price, 2),
                    "ceiling_price": round(ceiling_price, 2),
                    "unit": unit,
                    "date": "2024-12-31",
                    "source": "mandi_prices_2024.csv",
                    "imported_at": now_iso,
                    "updated_at": now_iso,
                }

                mandi_ops.append(
                    UpdateOne(
                        {"crop": crop, "state": state, "season": season},
                        {"$set": doc},
                        upsert=True
                    )
                )
            except Exception as e:
                pass

        if mandi_ops:
            res = await db.mandi_prices.bulk_write(mandi_ops)
            mandi_inserted = res.upserted_count
            mandi_updated = res.modified_count
        else:
            mandi_inserted = mandi_updated = 0
    else:
        print(f"  [WARNING] {MANDI_CSV_PATH} not found!", flush=True)
        mandi_inserted = mandi_updated = 0

    # ─── PART 3: Import msp_prices Seed Dataset ──────────────────────
    print("\n[PART 3] Importing Government MSP Prices...", flush=True)
    msp_ops = []
    msp_read = len(MSP_SEED_DATA)

    for msp_item in MSP_SEED_DATA:
        try:
            crop = normalize_crop_name(msp_item["crop"])
            season = normalize_season(msp_item["season"])
            marketing_year = msp_item["marketing_year"]

            doc = {
                "crop": crop,
                "commodity": msp_item["commodity"],
                "season": season,
                "marketing_year": marketing_year,
                "msp_price": float(msp_item["msp_price"]),
                "unit": msp_item["unit"],
                "currency": "INR",
                "source": "Government of India (CACP / DES)",
                "effective_from": msp_item["effective_from"],
                "effective_to": msp_item["effective_to"],
                "imported_at": now_iso,
                "updated_at": now_iso,
            }

            msp_ops.append(
                UpdateOne(
                    {"crop": crop, "season": season, "marketing_year": marketing_year},
                    {"$set": doc},
                    upsert=True
                )
            )
        except Exception as e:
            pass

    if msp_ops:
        res = await db.msp_prices.bulk_write(msp_ops)
        msp_inserted = res.upserted_count
        msp_updated = res.modified_count
    else:
        msp_inserted = msp_updated = 0

    # ─── SUMMARY REPORT ──────────────────────────────────────────────
    count_crop_costs = await db.crop_costs.count_documents({})
    count_mandi_prices = await db.mandi_prices.count_documents({})
    count_msp_prices = await db.msp_prices.count_documents({})

    print("\n" + "=" * 65, flush=True)
    print("  DATASET IMPORT SUMMARY REPORT", flush=True)
    print("=" * 65, flush=True)
    print(f"  [crop_costs]   Read: {cost_read} | Inserted: {cost_inserted} | Updated: {cost_updated} | Total DB: {count_crop_costs}", flush=True)
    print(f"  [mandi_prices] Read: {mandi_read} | Inserted: {mandi_inserted} | Updated: {mandi_updated} | Total DB: {count_mandi_prices}", flush=True)
    print(f"  [msp_prices]   Read: {msp_read} | Inserted: {msp_inserted} | Updated: {msp_updated} | Total DB: {count_msp_prices}", flush=True)
    print("=" * 65, flush=True)

    client.close()


if __name__ == "__main__":
    asyncio.run(import_datasets())
