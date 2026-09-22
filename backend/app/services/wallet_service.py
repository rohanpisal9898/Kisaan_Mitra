"""
Farmer Wallet Service — Production Database-First Architecture.

Runtime Source of Truth: MongoDB Atlas
Collections:
  - crop_costs: Baseline crop cost benchmarks (₹/Ha)
  - mandi_prices: Mandi market prices (₹/Quintal)
  - msp_prices: Official Minimum Support Prices (₹/Quintal)
  - user_expenses: Stored farmer expenses
  - market_insights: Gemini market insights with data snapshots & timestamps

Zero runtime CSV dependency!
"""

import asyncio
import math
import uuid
import json
import httpx
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.services.yield_service import yield_service
from app.integrations.gemini import settings, _clean_and_parse_json


def _format_indian_currency(val: float) -> str:
    """Formats numbers into standard Indian currency format (e.g., ₹2.84 L or ₹1,16,000)."""
    abs_val = abs(val)
    sign = "-" if val < 0 else ""
    if abs_val >= 100000:
        lakhs = abs_val / 100000.0
        return f"{sign}₹{lakhs:.2f} L"
    else:
        int_val = int(round(abs_val))
        s = str(int_val)
        if len(s) > 3:
            last3 = s[-3:]
            other = s[:-3]
            res = ""
            while len(other) > 2:
                res = "," + other[-2:] + res
                other = other[:-2]
            formatted = sign + "₹" + other + res + "," + last3
        else:
            formatted = sign + "₹" + s
        return formatted


class WalletService:
    def _normalize_crop_name(self, raw_crop: str) -> str:
        """Standardizes crop names across MongoDB collections."""
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

    def _get_canonical_crop_id(self, raw_crop: Optional[str]) -> Optional[str]:
        """Returns snake_case canonical crop ID or None if no active crop is sown."""
        if not raw_crop or not str(raw_crop).strip():
            return None
        c_str = str(raw_crop).strip().lower()
        if c_str in ["none", "null", "not_sown", "not sown yet", ""]:
            return None
        norm = self._normalize_crop_name(raw_crop)
        mapping = {
            "Groundnut": "groundnut",
            "Soybean": "soybean",
            "Sesamum": "sesamum",
            "Sunflower": "sunflower",
            "Rapeseed &Mustard": "rapeseed_mustard",
            "Castor seed": "castor_seed",
            "Linseed": "linseed",
            "Safflower": "safflower",
            "Niger seed": "niger_seed",
        }
        return mapping.get(norm, norm.lower().replace(" ", "_"))

    def _get_current_season(self) -> str:
        month = datetime.now().month
        if 6 <= month <= 10:
            return "Kharif"
        elif month >= 11 or month <= 3:
            return "Rabi"
        else:
            return "Zaid"

    async def get_initial_expenses_from_db(
        self, db: AsyncIOMotorDatabase, state: str, crop: str, farm_area_ha: float
    ) -> List[Dict[str, Any]]:
        """
        Fetches baseline crop cost benchmarks from MongoDB `crop_costs` collection.
        Scales ₹/Ha costs by farm area in hectares.
        """
        crop_norm = self._normalize_crop_name(crop)
        season_curr = self._get_current_season()
        state_title = state.title() if state else "Maharashtra"

        base_per_ha = {
            "seed": 4500.0,
            "fertilizer": 6500.0,
            "labour": 12000.0,
            "machinery": 7500.0,
            "irrigation": 4000.0,
            "insecticides": 3500.0,
            "other": 2500.0,
        }

        if db is not None:
            # Query MongoDB crop_costs collection
            cost_doc = await db.crop_costs.find_one(
                {"crop": crop_norm, "state": state_title, "season": season_curr}
            )
            if not cost_doc:
                cost_doc = await db.crop_costs.find_one({"crop": crop_norm, "state": state_title})
            if not cost_doc:
                cost_doc = await db.crop_costs.find_one({"crop": crop_norm})

            if cost_doc:
                base_per_ha["seed"] = float(cost_doc.get("opr_cost_seed", 4500.0))
                base_per_ha["fertilizer"] = float(cost_doc.get("opr_cost_fertilizer", 6500.0))
                base_per_ha["labour"] = float(cost_doc.get("opr_cost_labour", 12000.0))
                base_per_ha["machinery"] = float(cost_doc.get("opr_cost_machinery", 7500.0))
                base_per_ha["irrigation"] = float(cost_doc.get("opr_cost_irrigation_chrg", 4000.0))
                base_per_ha["insecticides"] = float(cost_doc.get("opr_cost_insecticides", 3500.0))
                base_per_ha["other"] = float(cost_doc.get("opr_cost_other", 2500.0))

        area_scale = max(0.5, farm_area_ha)

        def round_step(val):
            return float(max(500, int(round(val / 500.0)) * 500))

        items = [
            {"id": "exp_seed", "category": "seed", "label": "Seeds", "amount": round_step(base_per_ha["seed"] * area_scale), "is_custom": False},
            {"id": "exp_fert", "category": "fertilizer", "label": "Fertilizer", "amount": round_step(base_per_ha["fertilizer"] * area_scale), "is_custom": False},
            {"id": "exp_labour", "category": "labour", "label": "Labour", "amount": round_step(base_per_ha["labour"] * area_scale), "is_custom": False},
            {"id": "exp_machinery", "category": "machinery", "label": "Machinery", "amount": round_step(base_per_ha["machinery"] * area_scale), "is_custom": False},
            {"id": "exp_irrigation", "category": "irrigation", "label": "Irrigation", "amount": round_step(base_per_ha["irrigation"] * area_scale), "is_custom": False},
            {"id": "exp_pest", "category": "insecticides", "label": "Pest Control", "amount": round_step(base_per_ha["insecticides"] * area_scale), "is_custom": False},
            {"id": "exp_other", "category": "other", "label": "Other", "amount": round_step(base_per_ha["other"] * area_scale), "is_custom": False},
        ]
        return items

    def _normalize_location_name(self, loc: Optional[str]) -> str:
        """Normalizes location (district/state) strings for strict exact matching."""
        if not loc:
            return ""
        l_str = str(loc).strip().lower()
        l_str = l_str.replace(" district", "").replace(" dist", "").replace("dist.", "").strip()
        return l_str

    async def _fetch_gemini_market_price(self, crop: str, district: str, state: str) -> Optional[Dict[str, Any]]:
        """Queries Gemini API for live estimated APMC mandi market price in INR/quintal for a specific district."""
        api_key = settings.gemini_api_key
        if not api_key or api_key == "your_gemini_api_key_here":
            return None

        district_norm_req = self._normalize_location_name(district)
        state_norm_req = self._normalize_location_name(state)
        crop_norm_req = self._normalize_crop_name(crop)

        model_names = [
            "gemini-2.5-flash",
            "gemini-3.5-flash-lite",
            "gemini-3.6-flash",
            "gemini-3.6-flash-lite",
            "gemini-3.6-lite",
        ]
        prompt = (
            f"You are an Indian APMC agricultural market expert.\n"
            f"Find the latest available mandi/market modal price for crop '{crop}' specifically in '{district}' district, '{state}', India in INR per quintal.\n"
            f"RULES:\n"
            f"1. Provide realistic market price specific to '{crop}' in '{district}' district, '{state}'. DO NOT reuse prices from other crops or states.\n"
            f"2. Return ONLY a valid JSON object in this exact schema:\n"
            f'{{\n'
            f'  "crop": "{crop}",\n'
            f'  "district": "{district}",\n'
            f'  "state": "{state}",\n'
            f'  "modal_price": <number_in_inr_per_quintal>,\n'
            f'  "floor_price": <min_number_in_inr>,\n'
            f'  "ceiling_price": <max_number_in_inr>,\n'
            f'  "market": "<Mandi_Name>",\n'
            f'  "available": true\n'
            f'}}\n'
            f"3. If reliable market data for '{crop}' in '{district}' district is unavailable, set 'available': false.\n"
        )

        for model in model_names:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
            payload = {
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {
                    "temperature": 0.2,
                    "maxOutputTokens": 300,
                    "responseMimeType": "application/json",
                }
            }
            try:
                async with httpx.AsyncClient(timeout=6.0) as client:
                    resp = await client.post(url, json=payload)
                    if resp.status_code == 200:
                        res_json = resp.json()
                        candidates = res_json.get("candidates", [])
                        if candidates and "content" in candidates[0]:
                            parts = candidates[0]["content"].get("parts", [])
                            if parts and "text" in parts[0]:
                                text = parts[0]["text"].strip()
                                parsed = _clean_and_parse_json(text)
                                if isinstance(parsed, dict) and parsed.get("available", True) is not False:
                                    # Strict Normalized Exact Match Validation
                                    ret_district = parsed.get("district")
                                    ret_crop = parsed.get("crop")
                                    ret_district_norm = self._normalize_location_name(ret_district)
                                    ret_crop_norm = self._normalize_crop_name(ret_crop) if ret_crop else ""

                                    if not ret_district_norm or ret_district_norm != district_norm_req:
                                        print(f"[MARKET GEMINI] REJECTED: Returned district '{ret_district}' does not match requested district '{district}'")
                                        continue

                                    if ret_crop_norm != crop_norm_req:
                                        print(f"[MARKET GEMINI] REJECTED: Returned crop '{ret_crop}' does not match requested crop '{crop}'")
                                        continue

                                    modal = parsed.get("modal_price")
                                    if modal and isinstance(modal, (int, float)) and 1000 <= modal <= 30000:
                                        parsed["valid"] = True
                                        parsed["model_used"] = model
                                        print(f"[MARKET GEMINI] Live district market price fetched: {crop_norm_req} | {district} | {state} | Rs. {modal}/quintal")
                                        return parsed
            except Exception as e:
                print(f"[MARKET GEMINI] Exception for model {model}: {e}")
                continue

        return None

    async def get_mandi_price_with_fallback(
        self, db: Optional[AsyncIOMotorDatabase], state: str, crop: str, district: Optional[str] = None, ttl_hours: float = 6.0
    ) -> Dict[str, Any]:
        """
        Gemini-First Market Price Service with 6-Hour MongoDB TTL Cache & Request Coalescing.
        Keyed strictly by (crop, district, state).
        """
        crop_norm = self._normalize_crop_name(crop)
        state_title = state.title().strip() if state else "Maharashtra"
        district_title = district.title().strip() if district and district.strip() else "Nashik"
        now_dt = datetime.now()
        now_iso = now_dt.isoformat()

        # Step 1: Check MongoDB 6-Hour TTL Cache FIRST (Strict crop + district + state)
        if db is not None:
            try:
                cached_doc = await db.market_price_cache.find_one({
                    "crop": crop_norm,
                    "district": district_title,
                    "state": state_title,
                })

                # Ignore old state-only records missing district field
                if cached_doc and cached_doc.get("district") == district_title and float(cached_doc.get("modal_price", 0)) > 0:
                    fetched_at_str = cached_doc.get("fetched_at")
                    is_fresh = False
                    if fetched_at_str:
                        try:
                            f_dt = datetime.fromisoformat(fetched_at_str)
                            age_seconds = (now_dt - f_dt).total_seconds()
                            if age_seconds < (ttl_hours * 3600):
                                is_fresh = True
                        except Exception:
                            pass

                    if is_fresh:
                        modal = float(cached_doc.get("modal_price"))
                        age_min = int((now_dt - datetime.fromisoformat(fetched_at_str)).total_seconds() / 60)
                        print(f"[MARKET SERVICE] [TTL Cache HIT] ({crop_norm}, {district_title}, {state_title}): Rs. {modal}/quintal (Age: {age_min}m)")
                        return {
                            "modal_price": modal,
                            "floor_price": float(cached_doc.get("floor_price") or round(modal * 0.92, 2)),
                            "ceiling_price": float(cached_doc.get("ceiling_price") or round(modal * 1.08, 2)),
                            "unit": "Rs/Quintal",
                            "market_name": cached_doc.get("market_name", f"{district_title} Mandi"),
                            "available": True,
                            "source": "cached",
                            "fetched_at": fetched_at_str,
                            "expires_at": cached_doc.get("expires_at"),
                            "message": "Cached district market price from MongoDB (6-Hour TTL active)",
                            "data_source": "MongoDB Persistent Price Cache",
                        }
            except Exception as e:
                print(f"[MARKET SERVICE] Error checking MongoDB TTL cache: {e}")

        # Step 2: Cache Expired or Missing -> Call Gemini API with Request Coalescing / Deduplication
        cache_key = f"{crop_norm}_{district_title}_{state_title}"

        if not hasattr(self, "_in_flight_locks"):
            self._in_flight_locks = {}

        if cache_key in self._in_flight_locks:
            print(f"[MARKET SERVICE] Coalescing concurrent fetch for {cache_key}...")
            await self._in_flight_locks[cache_key].wait()
            if db is not None:
                cached_doc = await db.market_price_cache.find_one({
                    "crop": crop_norm,
                    "district": district_title,
                    "state": state_title,
                })
                if cached_doc and cached_doc.get("district") == district_title and float(cached_doc.get("modal_price", 0)) > 0:
                    modal = float(cached_doc.get("modal_price"))
                    return {
                        "modal_price": modal,
                        "floor_price": float(cached_doc.get("floor_price") or round(modal * 0.92, 2)),
                        "ceiling_price": float(cached_doc.get("ceiling_price") or round(modal * 1.08, 2)),
                        "unit": "Rs/Quintal",
                        "market_name": cached_doc.get("market_name", f"{district_title} Mandi"),
                        "available": True,
                        "source": "cached",
                        "fetched_at": cached_doc.get("fetched_at"),
                        "expires_at": cached_doc.get("expires_at"),
                        "message": "Cached market price from MongoDB",
                        "data_source": "MongoDB Persistent Price Cache",
                    }

        lock_event = asyncio.Event()
        self._in_flight_locks[cache_key] = lock_event

        try:
            gemini_price = await self._fetch_gemini_market_price(crop_norm, district_title, state_title)
            if gemini_price and gemini_price.get("valid"):
                modal = float(gemini_price["modal_price"])
                floor = float(gemini_price.get("floor_price") or round(modal * 0.92, 2))
                ceil = float(gemini_price.get("ceiling_price") or round(modal * 1.08, 2))
                market_name = str(gemini_price.get("market") or f"{district_title} Mandi")
                model_used = str(gemini_price.get("model_used", "gemini-3.1-flash-lite"))
                expires_iso = (now_dt + timedelta(hours=ttl_hours)).isoformat()

                res_doc = {
                    "modal_price": modal,
                    "floor_price": floor,
                    "ceiling_price": ceil,
                    "unit": "Rs/Quintal",
                    "market_name": market_name,
                    "available": True,
                    "source": "gemini",
                    "fetched_at": now_iso,
                    "expires_at": expires_iso,
                    "message": "Live district market price via Gemini AI",
                    "data_source": "Gemini AI Live Market Intelligence",
                }

                if db is not None:
                    try:
                        await db.market_price_cache.update_one(
                            {"crop": crop_norm, "district": district_title, "state": state_title},
                            {"$set": {
                                "crop": crop_norm,
                                "district": district_title,
                                "state": state_title,
                                "modal_price": modal,
                                "floor_price": floor,
                                "ceiling_price": ceil,
                                "unit": "Rs/Quintal",
                                "market_name": market_name,
                                "source": "gemini",
                                "model": model_used,
                                "fetched_at": now_iso,
                                "expires_at": expires_iso,
                                "updated_at": now_iso,
                            }},
                            upsert=True,
                        )
                        print(f"[MARKET SERVICE] Saved Gemini district price: {crop_norm} | {district_title} | {state_title} | Rs. {modal}/quintal")
                    except Exception as e:
                        print(f"[MARKET SERVICE] Error saving price cache to MongoDB: {e}")

                return res_doc
        finally:
            lock_event.set()
            self._in_flight_locks.pop(cache_key, None)

        # Step 3: Gemini Failed -> Return Expired MongoDB Cache if present for exact district
        if db is not None:
            try:
                cached_doc = await db.market_price_cache.find_one({
                    "crop": crop_norm,
                    "district": district_title,
                    "state": state_title,
                })
                if cached_doc and cached_doc.get("district") == district_title and float(cached_doc.get("modal_price", 0)) > 0:
                    modal = float(cached_doc.get("modal_price"))
                    print(f"[MARKET SERVICE] District-specific Gemini unavailable. Using exact cached price for: {crop_norm} | {district_title} | {state_title}")
                    return {
                        "modal_price": modal,
                        "floor_price": float(cached_doc.get("floor_price") or round(modal * 0.92, 2)),
                        "ceiling_price": float(cached_doc.get("ceiling_price") or round(modal * 1.08, 2)),
                        "unit": "Rs/Quintal",
                        "market_name": cached_doc.get("market_name", f"{district_title} Mandi"),
                        "available": True,
                        "source": "cached",
                        "fetched_at": cached_doc.get("fetched_at"),
                        "expires_at": cached_doc.get("expires_at"),
                        "message": "Last known cached district market price from MongoDB",
                        "data_source": "MongoDB Persistent Price Cache",
                    }
            except Exception as e:
                pass

        # Step 4: Deterministic Benchmark Default
        print(f"[MARKET SERVICE] District-specific Gemini unavailable. Using exact default price for: {crop_norm} | {district_title} | {state_title}")
        default_prices = {
            "Soybean": 4850.0,
            "Groundnut": 6300.0,
            "Sesamum": 12500.0,
            "Sunflower": 5400.0,
            "Rapeseed &Mustard": 5440.0,
            "Linseed": 5200.0,
            "Castor seed": 5900.0,
            "Safflower": 4900.0,
            "Niger seed": 5100.0,
        }
        def_modal = default_prices.get(crop_norm, 5000.0)
        return {
            "modal_price": def_modal,
            "floor_price": round(def_modal * 0.92, 2),
            "ceiling_price": round(def_modal * 1.08, 2),
            "unit": "Rs/Quintal",
            "market_name": f"{district_title} Mandi (Benchmark)",
            "available": True,
            "source": "default",
            "fetched_at": None,
            "expires_at": None,
            "message": "Benchmark default market price",
            "data_source": "Kisaan Mitra Benchmark Prices",
        }


        # Step 4: Missing Cache -> Hardcoded Benchmark Default Fallback
        default_db = await self.get_mandi_price_from_db(db, state_title, crop_norm)
        if default_db and default_db.get("available") and default_db.get("modal_price", 0) > 0:
            default_db["source"] = "default"
            default_db["fetched_at"] = None
            default_db["message"] = "Baseline benchmark market data"
            return default_db

        hardcoded_defaults = {
            "Rapeseed &Mustard": 5440.0,
            "Soybean": 4892.0,
            "Groundnut": 6780.0,
            "Castor seed": 5850.0,
            "Sunflower": 6550.0,
            "Sesamum": 14500.0,
            "Linseed": 5950.0,
            "Safflower": 5650.0,
            "Niger seed": 7850.0,
        }
        fallback_modal = hardcoded_defaults.get(crop_norm, 5200.0)
        return {
            "modal_price": fallback_modal,
            "floor_price": round(fallback_modal * 0.92, 2),
            "ceiling_price": round(fallback_modal * 1.08, 2),
            "unit": "Rs/Quintal",
            "market_name": f"{state_title} Mandi (Benchmark)",
            "available": True,
            "source": "default",
            "fetched_at": None,
            "message": "Default agricultural benchmark price",
            "data_source": "Agricultural Benchmark Default",
        }

    async def get_mandi_price_from_db(
        self, db: AsyncIOMotorDatabase, state: str, crop: str
    ) -> Dict[str, Any]:
        """
        Gets Mandi market price from MongoDB `mandi_prices` collection following strict relevance:
          1. Crop + State + Season
          2. Crop + State
          3. Crop (National Average)
        """
        crop_norm = self._normalize_crop_name(crop)
        season_curr = self._get_current_season()
        state_title = state.title() if state else "Maharashtra"

        if db is not None:
            # Order 1: Crop + State + Season
            mandi_doc = await db.mandi_prices.find_one(
                {"crop": crop_norm, "state": state_title, "season": season_curr}
            )
            # Order 2: Crop + State
            if not mandi_doc:
                mandi_doc = await db.mandi_prices.find_one({"crop": crop_norm, "state": state_title})

            if not mandi_doc:
                # Order 3: National average cursor
                cursor = db.mandi_prices.find({"crop": crop_norm})
                docs = await cursor.to_list(length=100)
                if docs:
                    avg_modal = sum(float(d.get("modal_price", 0)) for d in docs) / len(docs)
                    min_floor = min(float(d.get("floor_price", 0)) for d in docs)
                    max_ceil = max(float(d.get("ceiling_price", 0)) for d in docs)
                    return {
                        "modal_price": round(avg_modal, 2),
                        "floor_price": round(min_floor, 2),
                        "ceiling_price": round(max_ceil, 2),
                        "unit": "Rs/Quintal",
                        "market_name": "National Mandi Average",
                        "available": True,
                        "message": "National benchmark market data",
                        "data_source": "MongoDB Atlas mandi_prices",
                        "source": "default",
                        "fetched_at": None,
                    }

            if mandi_doc:
                return {
                    "modal_price": float(mandi_doc.get("modal_price", 0.0)),
                    "floor_price": float(mandi_doc.get("floor_price", 0.0)),
                    "ceiling_price": float(mandi_doc.get("ceiling_price", 0.0)),
                    "unit": str(mandi_doc.get("unit", "Rs/Quintal")),
                    "market_name": str(mandi_doc.get("market", f"{state_title} Mandi")),
                    "available": True,
                    "message": "MongoDB Atlas benchmark data (2024)",
                    "data_source": "MongoDB Atlas mandi_prices",
                    "source": "default",
                    "fetched_at": None,
                }

        return {
            "modal_price": 0.0,
            "floor_price": 0.0,
            "ceiling_price": 0.0,
            "unit": "Rs/Quintal",
            "market_name": "Market price unavailable",
            "available": False,
            "message": "Market price unavailable in DB",
            "data_source": "MongoDB Atlas",
            "source": "default",
            "fetched_at": None,
        }

    async def get_msp_price_from_db(
        self, db: AsyncIOMotorDatabase, crop: str, season: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Gets Government Minimum Support Price (MSP) from MongoDB `msp_prices` collection.
        Query: crop + season + marketing_year
        """
        crop_norm = self._normalize_crop_name(crop)
        season_curr = season or self._get_current_season()

        if db is not None:
            msp_doc = await db.msp_prices.find_one(
                {"crop": crop_norm, "season": season_curr, "marketing_year": "2024-25"}
            )
            if not msp_doc:
                msp_doc = await db.msp_prices.find_one({"crop": crop_norm})

            if msp_doc:
                return {
                    "crop": crop_norm,
                    "commodity": str(msp_doc.get("commodity", crop_norm)),
                    "season": str(msp_doc.get("season", season_curr)),
                    "marketing_year": str(msp_doc.get("marketing_year", "2024-25")),
                    "msp_price": float(msp_doc.get("msp_price", 0.0)),
                    "unit": str(msp_doc.get("unit", "Rs/Quintal")),
                    "source": str(msp_doc.get("source", "Government of India (CACP / DES)")),
                    "effective_from": msp_doc.get("effective_from"),
                    "effective_to": msp_doc.get("effective_to"),
                    "available": True,
                    "message": "Official Government MSP Benchmark",
                }

        return {
            "crop": crop_norm,
            "commodity": crop_norm,
            "season": season_curr,
            "marketing_year": "2024-25",
            "msp_price": 0.0,
            "unit": "Rs/Quintal",
            "source": "Government of India",
            "available": False,
            "message": "MSP data unavailable in DB",
        }

    async def get_oilseed_markets_from_db(
        self,
        db: AsyncIOMotorDatabase,
        state: str,
        farmer_crop: Optional[str] = None,
        district: Optional[str] = None,
        prefetched_mandi: Optional[Dict[str, Any]] = None,
        prefetched_msp: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        """
        Fetches top oilseed market & MSP comparisons from MongoDB.
        Dynamically prepends the farmer's sown crop to index 0 without duplication.
        Evaluates is_farmer_crop strictly via canonical crop IDs.
        """
        default_oilseeds = ["Groundnut", "Soybean", "Sesamum", "Sunflower", "Rapeseed &Mustard"]
        candidate_crops = list(default_oilseeds)
        farmer_crop_id = self._get_canonical_crop_id(farmer_crop)

        if farmer_crop_id is not None:
            farmer_norm = self._normalize_crop_name(farmer_crop)
            existing_idx = None
            for idx, c_raw in enumerate(candidate_crops):
                if self._normalize_crop_name(c_raw) == farmer_norm:
                    existing_idx = idx
                    break

            if existing_idx is not None:
                f_crop = candidate_crops.pop(existing_idx)
                candidate_crops.insert(0, f_crop)
            else:
                candidate_crops.insert(0, farmer_norm)

        prefetched_crop_norm = self._normalize_crop_name(farmer_crop or "Soybean")
        results = []
        for c_raw in candidate_crops:
            c_norm = self._normalize_crop_name(c_raw)
            mandi_info = (
                prefetched_mandi
                if prefetched_mandi is not None and c_norm == prefetched_crop_norm
                else await self.get_mandi_price_with_fallback(db, state, c_raw, district)
            )
            if not mandi_info.get("available") or mandi_info.get("modal_price", 0) <= 0:
                continue

            msp_info = (
                prefetched_msp
                if prefetched_msp is not None and c_norm == prefetched_crop_norm
                else await self.get_msp_price_from_db(db, c_raw)
            )
            modal = mandi_info["modal_price"]
            floor = mandi_info["floor_price"]
            ceil = mandi_info["ceiling_price"]
            msp = msp_info.get("msp_price", 0.0) if msp_info.get("available") else None

            diff = (modal - msp) if msp and msp > 0 else None
            diff_label = f"{'+' if diff >= 0 else ''}₹{round(diff):,} / quintal" if diff is not None else None

            mid = (floor + ceil) / 2.0 if (floor + ceil) > 0 else modal
            if msp and msp > 0:
                if modal >= msp * 1.05 or modal >= mid * 1.03:
                    status = "High Market"
                elif modal < msp or modal < mid * 0.97:
                    status = "Low Market"
                else:
                    status = "Moderate Market"
            else:
                if modal >= mid * 1.03:
                    status = "High Market"
                elif modal < mid * 0.97:
                    status = "Low Market"
                else:
                    status = "Moderate Market"

            item_crop_id = self._get_canonical_crop_id(c_raw)
            crop_display = c_raw
            if c_norm == "Soybean":
                crop_display = "Soybean (Yellow)"
            elif c_norm == "Sesamum":
                crop_display = "Sesame Seed (Til)"
            elif c_norm == "Rapeseed &Mustard":
                crop_display = "Mustard / Rapeseed"

            is_farmer = bool(farmer_crop_id is not None and item_crop_id == farmer_crop_id)

            results.append({
                "crop_id": item_crop_id,
                "crop_name": crop_display,
                "unit_price": modal,
                "min_price": floor,
                "max_price": ceil,
                "unit": "Rs/Quintal",
                "market_status": status,
                "market_name": mandi_info.get("market_name", f"{district or state} Mandi"),
                "is_farmer_crop": is_farmer,
                "msp_price": msp,
                "market_vs_msp": diff,
                "market_vs_msp_label": diff_label,
            })

            if len(results) >= 6:
                break

        return results

    async def refresh_gemini_market_insight_async(
        self, db: AsyncIOMotorDatabase, phone_number: str, language: str = "English", force: bool = False
    ):
        """
        Asynchronous background task triggered on successful login/registration or language switch.
        Fetches Mandi + MSP + Farmer context from MongoDB, calls Gemini API,
        Calculates and refreshes Gemini market insight for the farmer's active crop,
        and upserts the generated market insight into MongoDB `market_insights` collection.
        Enforces a 5-minute cooldown (bypassed if language changed or forced).
        """
        now = datetime.now()
        now_iso = now.isoformat()

        # 1. Fetch user profile
        user = await db.users.find_one({"phone_number": phone_number})
        if not user:
            print(f"[WARN] User not found for phone {phone_number}. Skipping market insight refresh.")
            return

        crop = user.get("current_crop", "Soyabean")
        state = user.get("state", "Maharashtra")
        district = user.get("district", "Nashik")

        # Language normalization
        lang_str = str(language).lower().strip()
        is_hi = "hi" in lang_str or "hindi" in lang_str or "हिं" in lang_str
        is_mr = "mr" in lang_str or "marathi" in lang_str or "मरा" in lang_str
        lang_code = "hi" if is_hi else ("mr" if is_mr else "en")

        # 5-minute cooldown check (bypass if language changed or forced)
        existing = await db.market_insights.find_one({"phone_number": phone_number})
        if not force and existing and existing.get("language") == lang_code and existing.get("generated_at"):
            try:
                gen_time = datetime.fromisoformat(existing["generated_at"])
                if (now - gen_time).total_seconds() < 300:
                    print(f"[INFO] Market insight cooldown active for {phone_number} ({lang_code}). Skipping Gemini call.")
                    return
            except Exception as e:
                print(f"[WARN] Error parsing generated_at: {e}")

        # Fetch mandi and MSP snapshots
        mandi_info = await self.get_mandi_price_with_fallback(db, state, crop, district)
        msp_info = await self.get_msp_price_from_db(db, crop)

        modal_price = mandi_info.get("modal_price", 4800.0)
        floor_price = mandi_info.get("floor_price", 4400.0)
        ceiling_price = mandi_info.get("ceiling_price", 5200.0)
        msp_price = msp_info.get("msp_price", 4892.0)

        # Language normalization
        lang_str = str(language).lower().strip()
        is_hi = "hi" in lang_str or "hindi" in lang_str or "हिं" in lang_str
        is_mr = "mr" in lang_str or "marathi" in lang_str or "मरा" in lang_str
        lang_name = "Hindi (हिंदी)" if is_hi else ("Marathi (मराठी)" if is_mr else "English")

        crop_hi_map = {"Soybean": "सोयाबीन", "Soyabean": "सोयाबीन", "Groundnut": "मूंगफली", "Mustard": "सरसों", "Sunflower": "सूरजमुखी", "Sesame": "तिल", "Linseed": "अलसी", "Castor": "अरंडी"}
        crop_mr_map = {"Soybean": "सोयाबीन", "Soyabean": "सोयाबीन", "Groundnut": "भुईमूग", "Mustard": "मोहरी", "Sunflower": "सूर्यफूल", "Sesame": "तीळ", "Linseed": "जवस", "Castor": "एरंडी"}
        display_crop = crop_hi_map.get(crop, crop) if is_hi else (crop_mr_map.get(crop, crop) if is_mr else crop)

        if is_hi:
            insight_title = "🌱 बाज़ार विश्लेषण"
            insight_text = (
                f"{state} में, {display_crop} का मंडी बाज़ार भाव ₹{int(modal_price):,}/क्विंटल (सीमा ₹{int(floor_price):,} - ₹{int(ceiling_price):,}) चल रहा है, "
                f"जो सरकारी एमएसपी ₹{int(msp_price):,}/क्विंटल की तुलना में है। अपनी फसल बेचने से पहले स्थानीय मंडी आवक पर नज़र रखें।"
            )
        elif is_mr:
            insight_title = "🌱 बाजार माहिती"
            insight_text = (
                f"{state} मध्ये, {display_crop} चा बाजारभाव ₹{int(modal_price):,}/क्विंटल (कक्षा ₹{int(floor_price):,} - ₹{int(ceiling_price):,}) आहे, "
                f"जो शासकीय हमीभाव ₹{int(msp_price):,}/क्विंटल च्या तुलनेत आहे. विक्रीपूर्वी स्थानिक बाजार आवकेची पाहणी करा."
            )
        else:
            insight_title = "🌱 Market Insight"
            insight_text = (
                f"In {state}, {crop} is trading at a market price of ₹{int(modal_price):,}/quintal "
                f"(ranging from ₹{int(floor_price):,} to ₹{int(ceiling_price):,}), which is compared to government MSP of ₹{int(msp_price):,}/quintal. "
                f"Monitor local market arrivals before selling."
            )

        # 2. Call Gemini Flash API for fresh 2-sentence market insight
        api_key = settings.gemini_api_key
        if api_key and api_key != "your_gemini_api_key_here":
            prompt = (
                f"You are an agricultural market advisor for Indian farmers. Summarize this market price and MSP data in EXACTLY 1 to 2 short sentences.\n"
                f"CRITICAL REQUIREMENT: Write the entire response in {lang_name} (using native Devanagari script for Hindi/Marathi).\n"
                f"DO NOT invent any prices or numbers. Use ONLY these given numbers:\n"
                f"Crop: {display_crop}\nState: {state}\nMarket Price: ₹{modal_price}/quintal (Range: ₹{floor_price} - ₹{ceiling_price})\n"
                f"Government MSP Price: ₹{msp_price}/quintal\n\nReturn plain text."
            )
            model_names = [
                "gemini-2.5-flash",
                "gemini-3.5-flash-lite",
                "gemini-3.6-flash",
                "gemini-3.6-flash-lite",
                "gemini-3.6-lite",
            ]
            for model_name in model_names:
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={api_key}"
                payload = {
                    "contents": [{"parts": [{"text": prompt}]}],
                    "generationConfig": {"temperature": 0.2, "maxOutputTokens": 120}
                }

                try:
                    async with httpx.AsyncClient(timeout=8.0) as client:
                        resp = await client.post(url, json=payload)
                        if resp.status_code == 200:
                            res_json = resp.json()
                            candidates = res_json.get("candidates", [])
                            if candidates and "content" in candidates[0]:
                                parts = candidates[0]["content"].get("parts", [])
                                if parts and "text" in parts[0]:
                                    text = parts[0]["text"].strip()
                                    if text:
                                        if is_hi or is_mr:
                                            has_devanagari = any(0x0900 <= ord(c) <= 0x097F for c in text)
                                            if has_devanagari:
                                                insight_text = text
                                                break
                                        else:
                                            insight_text = text
                                            break
                except Exception as e:
                    print(f"[GEMINI REFRESH ERROR] {model_name} exception: {e}")
                    continue

        # 3. Upsert into MongoDB `market_insights` collection
        insight_doc = {
            "phone_number": phone_number,
            "crop": crop,
            "state": state,
            "language": lang_code,
            "insight_title": insight_title,
            "insight_text": insight_text,
            "market_data_snapshot": mandi_info,
            "msp_snapshot": msp_info,
            "generated_at": now_iso,
            "data_source": "MongoDB Atlas & Gemini Intelligence",
            "updated_at": now_iso,
        }

        await db.market_insights.update_one(
            {"phone_number": phone_number, "language": lang_code},
            {"$set": insight_doc},
            upsert=True,
        )
        # Also update the primary phone document for backwards compatibility
        await db.market_insights.update_one(
            {"phone_number": phone_number, "language": {"$exists": False}},
            {"$set": insight_doc},
            upsert=False,
        )
        print(f"[OK] Refreshed & Saved MarketInsight in MongoDB for farmer {phone_number} ({lang_name})")

    async def get_wallet_overview(
        self,
        db: AsyncIOMotorDatabase,
        phone_number: Optional[str] = None,
        language: str = "English",
    ) -> Dict[str, Any]:
        """
        Orchestrates complete Farmer Wallet overview reading EXCLUSIVELY from MongoDB Atlas:
        1. Reads farmer profile (crop, farm_area, farm_area_unit, district, state)
        2. Queries user's saved expenses from `user_expenses` collection in MongoDB Atlas
        3. If no custom expenses, seeds default agricultural expenses from MongoDB `crop_costs`
        4. Queries real-time mandi prices from MongoDB `mandi_prices`
        5. Queries MSP benchmarks from MongoDB `msp_benchmarks`
        6. Reads stored Gemini Market Insights from MongoDB `market_insights`
        7. Recalculates profit, risk level, ROI, and financial shield dynamically
        """
        # 1. Fetch Farmer User Document
        user_doc = None
        phone = phone_number.strip() if phone_number and phone_number.strip() else "guest"
        if db is not None and phone != "guest":
            user_doc = await db.users.find_one({"phone_number": phone})
        if not user_doc and db is not None:
            user_doc = await db.users.find_one({}, sort=[("updated_at", -1)])

        if not user_doc:
            user_doc = self._default_user_doc(phone_number)

        phone = user_doc.get("phone_number", "guest")
        farmer_name = user_doc.get("farmer_name", "Farmer")
        village = user_doc.get("village", "")
        district = user_doc.get("district", "Nashik")
        state = user_doc.get("state", "Maharashtra")
        current_crop = user_doc.get("current_crop")
        if current_crop and not str(current_crop).strip():
            current_crop = None

        current_crop_id = self._get_canonical_crop_id(current_crop)
        farm_area = float(user_doc.get("farm_area", 2.5))
        farm_area_unit = user_doc.get("farm_area_unit", "acres").lower()

        has_farm_area = farm_area > 0
        has_crop = bool(current_crop)
        lookup_crop = current_crop if current_crop else "Soybean"

        # Unit Conversion: Farm Area in Hectares
        if "acre" in farm_area_unit:
            farm_area_ha = farm_area * 0.404686
        else:
            farm_area_ha = farm_area

        # 1. CatBoost Yield Prediction Integration
        farm_context = {
            "state": state,
            "district": district,
            "crop_name": current_crop,
            "crop_id": self._normalize_crop_name(lookup_crop).lower(),
            "latitude": user_doc.get("latitude", 19.9975),
            "longitude": user_doc.get("longitude", 73.7898),
            "sowing_date": user_doc.get("sowing_date", "2026-06-15"),
            "has_satellite_data": user_doc.get("has_satellite_data", True),
            "satellite_data": user_doc.get("satellite_data"),
        }

        async def predict_yield_safely() -> Dict[str, Any]:
            try:
                return await yield_service.predict_yield(farm_context)
            except Exception as e:
                print(f"[WALLET SERVICE] Yield service error: {e}")
                return {
                    "yield_predicted": 0.0,
                    "yield_lower": 0.0,
                    "yield_upper": 0.0,
                    "unit": "tonnes_per_hectare",
                    "model_used": "nosat",
                    "available": False,
                }

        async def read_saved_expenses() -> Optional[Dict[str, Any]]:
            if db is not None and phone != "guest":
                return await db.user_expenses.find_one({"phone_number": phone})
            return None

        # Yield/model work and independent market/expense reads can run together.
        yield_res, mandi_info, msp_info, saved_doc = await asyncio.gather(
            predict_yield_safely(),
            self.get_mandi_price_with_fallback(db, state, lookup_crop, district),
            self.get_msp_price_from_db(db, lookup_crop),
            read_saved_expenses(),
        )
        has_yield = yield_res.get("available", True) and has_crop

        yield_pred = float(yield_res.get("yield_predicted", 0.0))
        yield_low = float(yield_res.get("yield_lower", 0.0))
        yield_upp = float(yield_res.get("yield_upper", 0.0))

        modal_price = float(mandi_info.get("modal_price", 0.0) or 0.0)
        floor_price = float(mandi_info.get("floor_price") or round(modal_price * 0.92, 2))
        ceiling_price = float(mandi_info.get("ceiling_price") or round(modal_price * 1.08, 2))
        has_market_price = mandi_info.get("available", False) and modal_price > 0

        # Selling price per tonne = Mandi modal price per quintal * 10
        selling_price_per_tonne = modal_price * 10.0
        total_yield_tonnes = farm_area_ha * yield_pred

        # 3. User Expenses from MongoDB `user_expenses` collection
        expense_items = []
        if saved_doc and "expenses" in saved_doc and isinstance(saved_doc["expenses"], list):
            expense_items = saved_doc["expenses"]

        if not expense_items:
            # Seed initial expenses from MongoDB `crop_costs` collection
            expense_items = await self.get_initial_expenses_from_db(db, state, lookup_crop, farm_area_ha)
            if db is not None and phone != "guest":
                await db.user_expenses.update_one(
                    {"phone_number": phone},
                    {"$set": {"phone_number": phone, "expenses": expense_items, "updated_at": datetime.now().isoformat()}},
                    upsert=True,
                )

        total_cost = float(sum(item.get("amount", 0.0) for item in expense_items))

        # 4. Authoritative Financial Revenue & Profit Calculations
        if has_farm_area and has_crop and has_yield and has_market_price:
            rev_expected = farm_area_ha * yield_pred * selling_price_per_tonne
            rev_min = farm_area_ha * yield_low * selling_price_per_tonne
            rev_max = farm_area_ha * yield_upp * selling_price_per_tonne

            exp_profit = rev_expected - total_cost
            min_profit = rev_min - total_cost
            max_profit = rev_max - total_cost
        else:
            rev_expected = 0.0
            rev_min = 0.0
            rev_max = 0.0
            exp_profit = 0.0
            min_profit = 0.0
            max_profit = 0.0

        is_loss = exp_profit < 0

        profit_summary = {
            "expected_profit": round(exp_profit, 2),
            "min_profit": round(min_profit, 2),
            "max_profit": round(max_profit, 2),
            "safe_planning_min": round(min_profit, 2),
            "safe_planning_max": round(exp_profit, 2),
            "total_cost": round(total_cost, 2),
            "revenue_expected": round(rev_expected, 2),
            "revenue_min": round(rev_min, 2),
            "revenue_max": round(rev_max, 2),
            "selling_price_per_quintal": modal_price,
            "selling_price_per_tonne": selling_price_per_tonne,
            "farm_area_ha": round(farm_area_ha, 3),
            "total_yield_tonnes": round(total_yield_tonnes, 2),
            "is_loss": is_loss,
            "display_title": "Estimated Loss" if is_loss else "Expected Profit",
            "formatted_expected_profit": _format_indian_currency(exp_profit),
            "formatted_min_profit": _format_indian_currency(min_profit),
            "formatted_max_profit": _format_indian_currency(max_profit),
        }

        # 5. Market Items & MSP comparisons from MongoDB
        market_items = await self.get_oilseed_markets_from_db(
            db,
            state,
            current_crop,
            district,
            prefetched_mandi=mandi_info,
            prefetched_msp=msp_info,
        )

        # 6. Read Stored Gemini Insight directly from MongoDB `market_insights` or compute localized snapshot
        lang_str = str(language).lower().strip()
        is_hi = "hi" in lang_str or "hindi" in lang_str or "हिं" in lang_str
        is_mr = "mr" in lang_str or "marathi" in lang_str or "मरा" in lang_str
        target_lang_code = "hi" if is_hi else ("mr" if is_mr else "en")

        crop_hi_map = {"Soybean": "सोयाबीन", "Soyabean": "सोयाबीन", "Groundnut": "मूंगफली", "Mustard": "सरसों", "Sunflower": "सूरजमुखी", "Sesame": "तिल", "Linseed": "अलसी", "Castor": "अरंडी"}
        crop_mr_map = {"Soybean": "सोयाबीन", "Soyabean": "सोयाबीन", "Groundnut": "भुईमूग", "Mustard": "मोहरी", "Sunflower": "सूर्यफूल", "Sesame": "तीळ", "Linseed": "जवस", "Castor": "एरंडी"}
        display_crop = crop_hi_map.get(lookup_crop, lookup_crop) if is_hi else (crop_mr_map.get(lookup_crop, lookup_crop) if is_mr else lookup_crop)

        target_title = "🌱 बाज़ार विश्लेषण" if is_hi else ("🌱 बाजार माहिती" if is_mr else "🌱 Market Insight")
        msp_val = int(msp_info.get("msp_price", 0))

        if is_hi:
            fallback_text = (
                f"{state} में, {display_crop} का मंडी बाज़ार भाव ₹{int(modal_price):,}/क्विंटल (सीमा ₹{int(floor_price):,} - ₹{int(ceiling_price):,}) चल रहा है, "
                f"जो सरकारी एमएसपी ₹{msp_val:,}/क्विंटल की तुलना में है।"
            )
        elif is_mr:
            fallback_text = (
                f"{state} मध्ये, {display_crop} चा बाजारभाव ₹{int(modal_price):,}/क्विंटल (कक्षा ₹{int(floor_price):,} - ₹{int(ceiling_price):,}) आहे, "
                f"जो शासकीय हमीभाव ₹{msp_val:,}/क्विंटल च्या तुलनेत आहे."
            )
        else:
            fallback_text = (
                f"In {state}, {lookup_crop} is trading at a market price of ₹{int(modal_price):,}/quintal "
                f"(ranging from ₹{int(floor_price):,} to ₹{int(ceiling_price):,}), which is compared to government MSP of ₹{msp_val:,}/quintal."
            )

        insight_res = None
        if current_crop and db is not None and phone != "guest":
            # 1. First attempt to find language-specific market insight document
            insight_doc = await db.market_insights.find_one({"phone_number": phone, "language": target_lang_code})
            if not insight_doc:
                # Fallback to single phone document if exists
                insight_doc = await db.market_insights.find_one({"phone_number": phone})

            if insight_doc:
                gen_at = insight_doc.get("generated_at")
                doc_lang = str(insight_doc.get("language", "en")).lower().strip()
                doc_text = insight_doc.get("insight_text", "")

                # Strict language validation
                has_devanagari = any(0x0900 <= ord(c) <= 0x097F for c in doc_text)
                if target_lang_code == "en":
                    lang_matches = (doc_lang == "en") and (not has_devanagari)
                elif target_lang_code == "hi":
                    lang_matches = (doc_lang == "hi") and has_devanagari
                elif target_lang_code == "mr":
                    lang_matches = (doc_lang == "mr") and has_devanagari
                else:
                    lang_matches = doc_lang == target_lang_code

                if lang_matches:
                    cooldown_sec = 0
                    if gen_at:
                        try:
                            g_dt = datetime.fromisoformat(gen_at)
                            elapsed = (datetime.now() - g_dt).total_seconds()
                            cooldown_sec = max(0, int(300 - elapsed))
                        except:
                            pass

                    insight_res = {
                        "title": insight_doc.get("insight_title", target_title),
                        "content": doc_text,
                        "available": True,
                        "generated_at": gen_at,
                        "data_source": insight_doc.get("data_source", "MongoDB Atlas & Gemini Intelligence"),
                        "is_updating": False,
                        "cooldown_seconds_remaining": cooldown_sec,
                    }
                else:
                    # Language changed or mismatched: trigger async refresh in background for new language
                    asyncio.create_task(self.refresh_gemini_market_insight_async(db, phone, language=language, force=True))

        if current_crop and not insight_res:
            insight_res = {
                "title": target_title,
                "content": fallback_text,
                "available": True,
                "generated_at": datetime.now().isoformat(),
                "data_source": "MongoDB Atlas",
                "is_updating": False,
                "cooldown_seconds_remaining": 0,
            }

        return {
            "farmer_name": farmer_name,
            "village": village,
            "district": district,
            "state": state,
            "current_crop": current_crop,
            "current_crop_id": current_crop_id,
            "farm_area": farm_area,
            "farm_area_unit": farm_area_unit,
            "has_farm_area": has_farm_area,
            "has_crop": has_crop,
            "has_yield_prediction": has_yield,
            "yield_prediction": {
                "predicted": round(yield_pred, 2),
                "lower": round(yield_low, 2),
                "upper": round(yield_upp, 2),
                "unit": "tonnes_per_hectare",
                "model_used": yield_res.get("model_used", "satellite"),
                "confidence_label": yield_res.get("confidence_label", "90% Confidence Range"),
                "available": has_yield,
            },
            "selling_price": mandi_info,
            "msp": msp_info,
            "profit_summary": profit_summary,
            "expenses": expense_items,
            "market_items": market_items,
            "market_insight": insight_res,
            "historical_cost_benchmark_note": "Historical/estimated cost benchmark from agricultural dataset",
            "data_freshness_note": f"Market Data: {mandi_info.get('data_source', 'Gemini AI / MongoDB')}",
        }

    async def update_user_expenses(
        self, db: AsyncIOMotorDatabase, phone_number: str, expenses: List[Dict[str, Any]]
    ):
        """Saves user expense list to MongoDB."""
        if db is not None and phone_number:
            await db.user_expenses.update_one(
                {"phone_number": phone_number},
                {"$set": {"phone_number": phone_number, "expenses": expenses, "updated_at": datetime.now().isoformat()}},
                upsert=True,
            )


    def _default_user_doc(self, phone_number: Optional[str] = None) -> Dict[str, Any]:
        if phone_number == "1234567894":
            return {
                "phone_number": "1234567894",
                "farmer_name": "manav",
                "village": "navalgad",
                "district": "JHUNJHUNU",
                "state": "Rajasthan",
                "current_crop": "Rapeseed &Mustard",
                "farm_area": 3.0,
                "farm_area_unit": "acres",
                "sowing_date": "2026-08-11",
                "latitude": 19.20881628657986,
                "longitude": 72.8728440148901,
            }
        return {
            "phone_number": "9876543210",
            "farmer_name": "Ramesh",
            "village": "Sonepur",
            "district": "Nashik",
            "state": "Maharashtra",
            "current_crop": "Soyabean",
            "farm_area": 2.5,
            "farm_area_unit": "acres",
            "sowing_date": "2026-06-15",
            "latitude": 19.9975,
            "longitude": 73.7898,
        }


wallet_service = WalletService()
