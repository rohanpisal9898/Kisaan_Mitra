import asyncio
import json
from app.services.wallet_service import wallet_service

def test_wallet_market_price():
    print("======================================================================")
    print("  TESTING GEMINI-FIRST MARKET PRICE SERVICE WITH MONGODB CACHE")
    print("======================================================================")

    # 1. Fetch live or cached market price for Mustard in Rajasthan (Manav Scenario)
    print("\n1. Testing get_mandi_price_with_fallback for Mustard in Rajasthan...")
    res = asyncio.run(wallet_service.get_mandi_price_with_fallback(None, "Rajasthan", "Rapeseed &Mustard"))
    print(f"   Crop          : Rapeseed &Mustard")
    print(f"   Modal Price   : Rs. {res.get('modal_price')}/quintal")
    print(f"   Price Range   : [Rs. {res.get('floor_price')} - Rs. {res.get('ceiling_price')}]")
    print(f"   Market Name   : {res.get('market_name')}")
    print(f"   Source        : {res.get('source')}")
    print(f"   Fetched At    : {res.get('fetched_at')}")

    assert res.get("modal_price", 0) > 0, "Modal price must be greater than 0"
    assert res.get("source") in ["gemini", "cached", "default"], f"Source must be valid, got {res.get('source')}"
    print("   [PASS] Market price retrieved and validated successfully!")

    # 2. Fetch complete Wallet Overview for Manav
    print("\n2. Testing get_wallet_overview for Farmer Manav (Phone: 1234567894)...")
    overview = asyncio.run(wallet_service.get_wallet_overview(None, phone_number="1234567894"))
    
    farmer_name = overview.get("farmer_name")
    crop = overview.get("current_crop")
    selling_info = overview.get("selling_price", {})
    profit_summary = overview.get("profit_summary", {})
    formatted_profit = str(profit_summary.get('formatted_expected_profit', '')).replace('₹', 'Rs. ')
    
    print(f"   Farmer Name   : {farmer_name}")
    print(f"   Current Crop  : {crop}")
    print(f"   Selling Price : Rs. {selling_info.get('modal_price')}/quintal (Source: {selling_info.get('source')})")
    print(f"   Expected Profit: {formatted_profit}")

    assert farmer_name == "manav", f"Expected farmer 'manav', got '{farmer_name}'"
    assert crop in ["Rapeseed &Mustard", "Rapeseed & Mustard"], f"Expected crop 'Rapeseed &Mustard', got '{crop}'"
    assert selling_info.get("modal_price", 0) > 0, "Selling price modal_price must be > 0"
    print("   [PASS] Wallet overview orchestration for Manav succeeded cleanly!")

    print("\n======================================================================")
    print("  [SUCCESS] All Market Price & Wallet Architecture Tests Passed!")
    print("======================================================================")

if __name__ == "__main__":
    test_wallet_market_price()
