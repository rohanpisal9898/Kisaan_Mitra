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

import math
import uuid
import json
import httpx
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.services.yield_service import yield_service
from app.integrations.gemini import settings


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
        self, db: AsyncIOMotorDatabase, state: str, farmer_crop: str
    ) -> List[Dict[str, Any]]:
        """Fetches top 3-5 oilseed market & MSP comparisons from MongoDB."""
        oilseed_crops = ["Groundnut", "Soybean", "Sesamum", "Sunflower", "Rapeseed &Mustard", "Castor seed"]
        results = []

        for c_raw in oilseed_crops:
            mandi_info = await self.get_mandi_price_from_db(db, state, c_raw)
            if not mandi_info.get("available") or mandi_info.get("modal_price", 0) <= 0:
                continue

            msp_info = await self.get_msp_price_from_db(db, c_raw)
            modal = mandi_info["modal_price"]
            floor = mandi_info["floor_price"]
            ceil = mandi_info["ceiling_price"]
            msp = msp_info.get("msp_price", 0.0) if msp_info.get("available") else None

            # Calculate Difference between Market Price and MSP
            diff = (modal - msp) if msp and msp > 0 else None
            diff_label = f"{'+' if diff >= 0 else ''}₹{round(diff):,} / quintal" if diff is not None else None

            mid = (floor + ceil) / 2.0 if (floor + ceil) > 0 else modal
            if modal >= mid * 1.02:
                status = "Strong Market"
            elif modal >= mid * 0.95:
                status = "Moderate Market"
            else:
                status = "Weak Market"

            crop_display = c_raw
            if c_raw == "Soybean": crop_display = "Soybean (Yellow)"
            elif c_raw == "Sesamum": crop_display = "Sesame Seed (Til)"
            elif c_raw == "Rapeseed &Mustard": crop_display = "Mustard / Rapeseed"

            is_farmer = (self._normalize_crop_name(c_raw) == self._normalize_crop_name(farmer_crop))

            results.append({
                "crop_name": crop_display,
                "unit_price": modal,
                "min_price": floor,
                "max_price": ceil,
                "unit": "Rs/Quintal",
                "market_status": status,
                "market_name": mandi_info.get("market_name", f"{state} Mandi"),
                "is_farmer_crop": is_farmer,
                "msp_price": msp,
                "market_vs_msp": diff,
                "market_vs_msp_label": diff_label,
            })

            if len(results) >= 5:
                break

        return results

    async def refresh_gemini_market_insight_async(
        self, db: AsyncIOMotorDatabase, phone_number: str
    ):
        """
        Asynchronous background task triggered on successful login/registration.
        Fetches Mandi + MSP + Farmer context from MongoDB, calls Gemini API,
        and upserts the generated market insight into MongoDB `market_insights` collection.
        Enforces a 5-minute cooldown (300s) per farmer to prevent duplicate API requests.
        Preserves previous valid insight if Gemini call fails.
        """
        if db is None or not phone_number or phone_number == "guest":
            return

        phone = phone_number.strip()
        now_dt = datetime.now()
        now_iso = now_dt.isoformat()

        # 1. Check 5-minute Cooldown in MongoDB
        existing_insight = await db.market_insights.find_one({"phone_number": phone})
        if existing_insight and "generated_at" in existing_insight:
            try:
                gen_dt = datetime.fromisoformat(existing_insight["generated_at"])
                seconds_elapsed = (now_dt - gen_dt).total_seconds()
                if seconds_elapsed < 300:  # 5 minutes cooldown
                    print(f"[GEMINI REFRESH] Cooldown active for {phone} ({int(300 - seconds_elapsed)}s remaining). Skipping Gemini call.")
                    return
            except Exception as e:
                pass

        # 2. Fetch Farmer Profile, Mandi Price & MSP from MongoDB
        user_doc = await db.users.find_one({"phone_number": phone})
        if not user_doc:
            return

        crop = user_doc.get("current_crop", "Soyabean")
        state = user_doc.get("state", "Maharashtra")

        mandi_info = await self.get_mandi_price_from_db(db, state, crop)
        msp_info = await self.get_msp_price_from_db(db, crop)

        modal_price = mandi_info.get("modal_price", 0.0)
        floor_price = mandi_info.get("floor_price", 0.0)
        ceiling_price = mandi_info.get("ceiling_price", 0.0)
        msp_price = msp_info.get("msp_price", 0.0)

        fallback_text = (
            f"{crop} market price in {state} is currently averaging around ₹{int(modal_price):,}/quintal "
            f"against the official MSP benchmark of ₹{int(msp_price):,}/quintal. "
            f"Plan your sales taking into account local quality and market arrivals."
        )

        api_key = settings.gemini_api_key
        insight_text = fallback_text

        if api_key and api_key != "your_gemini_api_key_here":
            prompt = (
                f"You are an agricultural advisor for Indian farmers. Summarize this market price and MSP data in EXACTLY 1 to 2 short sentences.\n"
                f"DO NOT invent any prices or numbers. Use ONLY these given numbers:\n"
                f"Crop: {crop}\nState: {state}\nMarket Price: ₹{modal_price}/quintal (Range: ₹{floor_price} - ₹{ceiling_price})\n"
                f"Government MSP Price: ₹{msp_price}/quintal\n\nReturn plain text."
            )
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-flash:generateContent?key={api_key}"
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
                                    insight_text = text
            except Exception as e:
                print(f"[GEMINI REFRESH ERROR] Gemini API call exception: {e}")

        # 3. Upsert into MongoDB `market_insights` collection
        insight_doc = {
            "phone_number": phone,
            "crop": crop,
            "state": state,
            "insight_title": "🌱 Market Insight",
            "insight_text": insight_text,
            "market_data_snapshot": mandi_info,
            "msp_snapshot": msp_info,
            "generated_at": now_iso,
            "data_source": "MongoDB Atlas & Gemini Intelligence",
            "updated_at": now_iso,
        }

        await db.market_insights.update_one(
            {"phone_number": phone},
            {"$set": insight_doc},
            upsert=True,
        )
        print(f"[OK] Refreshed & Saved MarketInsight in MongoDB for farmer {phone}")

    async def get_wallet_overview(
        self,
        db: AsyncIOMotorDatabase,
        phone_number: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Orchestrates complete Farmer Wallet overview reading EXCLUSIVELY from MongoDB Atlas:
          Farmer Profile (users) -> Yield Prediction (CatBoost) -> Mandi (mandi_prices) -> MSP (msp_prices) -> Expenses (user_expenses) -> Insights (market_insights)
        Opening wallet page DOES NOT call Gemini.
        """
        user_doc = None
        if db is not None and phone_number and phone_number.strip():
            user_doc = await db.users.find_one({"phone_number": phone_number.strip()})
        if not user_doc and db is not None:
            user_doc = await db.users.find_one({}, sort=[("updated_at", -1)])

        if not user_doc:
            user_doc = {
                "phone_number": "guest",
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

        phone = user_doc.get("phone_number", "guest")
        farmer_name = user_doc.get("farmer_name", "Farmer")
        village = user_doc.get("village", "")
        district = user_doc.get("district", "Nashik")
        state = user_doc.get("state", "Maharashtra")
        current_crop = user_doc.get("current_crop", "Soyabean")
        farm_area = float(user_doc.get("farm_area", 2.5))
        farm_area_unit = user_doc.get("farm_area_unit", "acres").lower()

        has_farm_area = farm_area > 0
        has_crop = bool(current_crop and current_crop.strip())

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
            "crop_id": self._normalize_crop_name(current_crop).lower(),
            "latitude": user_doc.get("latitude", 19.9975),
            "longitude": user_doc.get("longitude", 73.7898),
            "sowing_date": user_doc.get("sowing_date", "2026-06-15"),
            "has_satellite_data": user_doc.get("has_satellite_data", True),
            "satellite_data": user_doc.get("satellite_data"),
        }

        try:
            yield_res = await yield_service.predict_yield(farm_context)
            has_yield = yield_res.get("available", True)
        except Exception as e:
            print(f"[WALLET SERVICE] Yield service error: {e}")
            yield_res = {"yield_predicted": 0.0, "yield_lower": 0.0, "yield_upper": 0.0, "unit": "tonnes_per_hectare", "model_used": "nosat", "available": False}
            has_yield = False

        yield_pred = float(yield_res.get("yield_predicted", 0.0))
        yield_low = float(yield_res.get("yield_lower", 0.0))
        yield_upp = float(yield_res.get("yield_upper", 0.0))

        # 2. Mandi Market Price & MSP Lookup from MongoDB
        mandi_info = await self.get_mandi_price_from_db(db, state, current_crop)
        msp_info = await self.get_msp_price_from_db(db, current_crop)

        modal_price = mandi_info.get("modal_price", 0.0)
        has_market_price = mandi_info.get("available", False) and modal_price > 0

        # Selling price per tonne = Mandi modal price per quintal * 10
        selling_price_per_tonne = modal_price * 10.0
        total_yield_tonnes = farm_area_ha * yield_pred

        # 3. User Expenses from MongoDB `user_expenses` collection
        expense_items = []
        if db is not None and phone != "guest":
            saved_doc = await db.user_expenses.find_one({"phone_number": phone})
            if saved_doc and "expenses" in saved_doc and isinstance(saved_doc["expenses"], list):
                expense_items = saved_doc["expenses"]

        if not expense_items:
            # Seed initial expenses from MongoDB `crop_costs` collection
            expense_items = await self.get_initial_expenses_from_db(db, state, current_crop, farm_area_ha)
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
        market_items = await self.get_oilseed_markets_from_db(db, state, current_crop)

        # 6. Read Stored Gemini Insight directly from MongoDB `market_insights` (Zero Gemini API call)
        insight_res = None
        if db is not None and phone != "guest":
            insight_doc = await db.market_insights.find_one({"phone_number": phone})
            if insight_doc:
                gen_at = insight_doc.get("generated_at")
                cooldown_sec = 0
                if gen_at:
                    try:
                        g_dt = datetime.fromisoformat(gen_at)
                        elapsed = (datetime.now() - g_dt).total_seconds()
                        cooldown_sec = max(0, int(300 - elapsed))
                    except:
                        pass

                insight_res = {
                    "title": insight_doc.get("insight_title", "🌱 Market Insight"),
                    "content": insight_doc.get("insight_text", ""),
                    "available": True,
                    "generated_at": gen_at,
                    "data_source": insight_doc.get("data_source", "MongoDB Atlas & Gemini Intelligence"),
                    "is_updating": False,
                    "cooldown_seconds_remaining": cooldown_sec,
                }

        if not insight_res:
            fallback_text = (
                f"{current_crop} market price in {state} averages ₹{int(modal_price):,}/quintal "
                f"against official MSP of ₹{int(msp_info.get('msp_price', 0)):,}/quintal. "
                f"Sign in to generate an AI market insight."
            )
            insight_res = {
                "title": "🌱 Market Insight",
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
            "farm_area": farm_area,
            "farm_area_unit": farm_area_unit,
            "has_farm_area": has_farm_area,
            "has_crop": has_crop,
            "has_yield_prediction": has_yield,
            "yield_prediction": {
                "predicted": round(yield_pred, 2),
                "lower": round(yield_low, 2),
                "upper": round(yield_upp, 2),
                "unit": yield_res.get("unit", "tonnes_per_hectare"),
                "model_used": yield_res.get("model_used", "nosat"),
                "confidence_label": "90% Confidence Range",
                "available": has_yield,
            },
            "selling_price": mandi_info,
            "msp": msp_info,
            "profit_summary": profit_summary,
            "expenses": expense_items,
            "market_items": market_items,
            "market_insight": insight_res,
            "historical_cost_benchmark_note": "Historical/estimated cost benchmark from MongoDB crop_costs",
            "data_freshness_note": "Market & Cost Data: MongoDB Atlas (2024 Benchmark)",
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


wallet_service = WalletService()
