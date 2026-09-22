import os
import sys
import pytest
from unittest.mock import AsyncMock, MagicMock, patch

sys.path.insert(0, os.path.abspath("backend"))

from app.services.wallet_service import wallet_service


@pytest.mark.asyncio
async def test_wallet_overview_multilingual_marathi():
    mock_db = MagicMock()
    # Mock users collection
    mock_db.users.find_one = AsyncMock(return_value={
        "phone_number": "5454545454",
        "farmer_name": "Rohan Farmer",
        "state": "Gujarat",
        "district": "Junagadh",
        "current_crop": "Soyabean",
        "farm_area": 3.0,
        "farm_area_unit": "acres",
        "sowing_date": "2026-06-15",
    })
    # Mock user_expenses
    mock_db.user_expenses.find_one = AsyncMock(return_value=None)
    mock_db.user_expenses.update_one = AsyncMock(return_value=None)
    mock_db.crop_costs.find_one = AsyncMock(return_value=None)
    mock_db.market_insights.find_one = AsyncMock(return_value=None)
    mock_db.market_insights.update_one = AsyncMock(return_value=None)
    mock_db.mandi_prices.find_one = AsyncMock(return_value=None)
    mock_db.msp_prices.find_one = AsyncMock(return_value=None)
    mock_db.market_price_cache.find_one = AsyncMock(return_value={
        "crop": "Soybean",
        "district": "Junagadh",
        "state": "Gujarat",
        "modal_price": 4650.0,
        "floor_price": 4200.0,
        "ceiling_price": 5000.0,
        "fetched_at": "2026-09-22T10:00:00",
    })
    mock_db.market_price_cache.update_one = AsyncMock(return_value=None)

    # Call get_wallet_overview with language="mr"
    res_mr = await wallet_service.get_wallet_overview(mock_db, "5454545454", language="mr")
    assert res_mr is not None
    assert "market_insight" in res_mr
    assert res_mr["market_insight"]["title"] == "🌱 बाजार माहिती"
    assert "बाजारभाव" in res_mr["market_insight"]["content"]

    # Call get_wallet_overview with language="hi"
    res_hi = await wallet_service.get_wallet_overview(mock_db, "5454545454", language="hi")
    assert res_hi is not None
    assert res_hi["market_insight"]["title"] == "🌱 बाज़ार विश्लेषण"
    assert "मंडी बाज़ार भाव" in res_hi["market_insight"]["content"]

    # Call get_wallet_overview with language="en"
    res_en = await wallet_service.get_wallet_overview(mock_db, "5454545454", language="en")
    assert res_en is not None
    assert res_en["market_insight"]["title"] == "🌱 Market Insight"
    assert "market price" in res_en["market_insight"]["content"]
