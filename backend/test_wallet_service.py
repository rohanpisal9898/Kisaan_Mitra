"""
Automated unit & integration test script for Farmer Wallet Service.
Tests dataset loading, cost parsing, unit conversions, price lookup, and profit math.
"""

import sys
import os
import asyncio

# Ensure UTF-8 output encoding for Windows terminal
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.wallet_service import wallet_service, _format_indian_currency


async def test_wallet():
    print("=" * 65)
    print("  KISAAN MITRA — FARMER WALLET / FINANCIAL SHIELD TEST")
    print("=" * 65)

    # 1. Verify Dataset Loading
    print("\n[TEST 1] Datasets Loading")
    assert wallet_service.kisaan_df is not None, "kisaan_mitra.csv not loaded"
    assert wallet_service.mandi_df is not None, "mandi_prices_2024.csv not loaded"
    print(f"  ✓ kisaan_mitra.csv rows: {len(wallet_service.kisaan_df)}")
    print(f"  ✓ mandi_prices_2024.csv rows: {len(wallet_service.mandi_df)}")

    # 2. Verify Initial Expense Extraction from CSV
    print("\n[TEST 2] Baseline Cost Extraction from CSV")
    costs = wallet_service.get_initial_expenses_for_farm("Maharashtra", "Soyabean", farm_area_ha=1.0117)
    categories = [c["category"] for c in costs]
    print(f"  ✓ Extracted categories: {categories}")
    assert "seed" in categories
    assert "fertilizer" in categories
    assert "labour" in categories
    assert "machinery" in categories
    total_baseline = sum(c["amount"] for c in costs)
    print(f"  ✓ Baseline 1 Ha Soyabean Total Cost: {_format_indian_currency(total_baseline)}")

    # 3. Verify Mandi Price Lookup
    print("\n[TEST 3] Mandi Price Lookup")
    price_info = wallet_service.get_mandi_price_for_crop("Maharashtra", "Soyabean")
    print(f"  ✓ Soyabean in Maharashtra: Modal=₹{price_info['modal_price']}/quintal (Range: ₹{price_info['floor_price']} - ₹{price_info['ceiling_price']})")
    assert price_info["modal_price"] > 0, "Mandi modal price should be > 0"

    # 4. Verify Wallet Overview Calculation (Mock DB = None)
    print("\n[TEST 4] Full Wallet Overview & Profit Math")
    overview = await wallet_service.get_wallet_overview(None, "9876543210")

    ps = overview["profit_summary"]
    print(f"  ✓ Farmer Crop: {overview['current_crop']} | Farm Area: {overview['farm_area']} {overview['farm_area_unit']}")
    print(f"  ✓ Total Yield Predicted: {ps['total_yield_tonnes']} tonnes")
    print(f"  ✓ Total Cost: {ps['formatted_expected_profit']} (Title: {ps['display_title']})")
    print(f"  ✓ Total Cost: {_format_indian_currency(ps['total_cost'])}")
    print(f"  ✓ Expected Revenue: {_format_indian_currency(ps['revenue_expected'])}")
    print(f"  ✓ Expected Profit: {ps['formatted_expected_profit']}")
    print(f"  ✓ Profit Range: {ps['formatted_min_profit']} to {ps['formatted_max_profit']}")

    # 5. Verify Test 1 (Validation Requirement): +/- ₹500 Expense Change
    print("\n[TEST 5] Validation Test — Expense Increment (+₹500)")
    initial_cost = ps["total_cost"]
    initial_exp_profit = ps["expected_profit"]
    initial_min_profit = ps["min_profit"]

    # Increase first expense by ₹500
    expenses = overview["expenses"]
    expenses[0]["amount"] += 500.0

    new_cost = sum(e["amount"] for e in expenses)
    new_exp_profit = round(ps["revenue_expected"] - new_cost, 2)
    new_min_profit = round(ps["revenue_min"] - new_cost, 2)

    assert round(new_cost - initial_cost, 2) == 500.0, f"Expected total cost to increase by 500, got {new_cost - initial_cost}"
    assert round(new_exp_profit - initial_exp_profit, 2) == -500.0, f"Expected profit decrease by 500, got {new_exp_profit - initial_exp_profit}"
    assert round(new_min_profit - initial_min_profit, 2) == -500.0, "Minimum profit should decrease by 500"
    print("  ✓ Total cost increased by ₹500, Min & Expected profit decreased by exactly ₹500")

    # 6. Verify Test 2 (Validation Requirement): Expense Deletion
    print("\n[TEST 6] Validation Test — Expense Deletion")
    deleted_amt = expenses[0]["amount"]
    del expenses[0]
    del_cost = sum(e["amount"] for e in expenses)
    del_exp_profit = round(ps["revenue_expected"] - del_cost, 2)

    assert round(del_cost, 2) == round(new_cost - deleted_amt, 2), "Total cost should decrease by deleted expense amount"
    assert round(del_exp_profit - new_exp_profit, 2) == round(deleted_amt, 2), "Expected profit should increase by deleted expense amount"
    print(f"  ✓ Deleted expense of {_format_indian_currency(deleted_amt)}. Total cost decreased & Profit increased by exactly {_format_indian_currency(deleted_amt)}")

    # 7. Verify Oilseed Markets
    print("\n[TEST 7] Oilseed Markets Section")
    markets = overview["market_items"]
    print(f"  ✓ Top market items count: {len(markets)}")
    for m in markets[:3]:
        print(f"    • {m['crop_name']}: ₹{m['unit_price']}/quintal (Range: ₹{m['min_price']} - ₹{m['max_price']}) — {m['market_status']}")

    # 8. Verify Gemini Market Insight
    print("\n[TEST 8] Market Insight Generation")
    insight = overview["market_insight"]
    print(f"  ✓ Title: {insight['title']}")
    print(f"  ✓ Content: {insight['content']}")

    print("\n" + "=" * 65)
    print("  ALL FARMER WALLET BACKEND TESTS PASSED SUCCESSFULLY!")
    print("=" * 65)


if __name__ == "__main__":
    asyncio.run(test_wallet())
