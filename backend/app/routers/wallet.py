from fastapi import APIRouter, Depends, Query, HTTPException, Path
from typing import Optional
import uuid
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.models.wallet import (
    WalletOverviewResponse,
    AddExpenseRequest,
    UpdateExpenseRequest,
    SaveExpensesRequest,
)
from app.services.wallet_service import wallet_service

router = APIRouter(prefix="/api/v1/wallet", tags=["Farmer Wallet"])


@router.get("/overview", response_model=WalletOverviewResponse)
async def get_wallet_overview(
    phone_number: Optional[str] = Query(None, description="Farmer phone number"),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Fetch complete Farmer Wallet & Financial Shield summary."""
    data = await wallet_service.get_wallet_overview(db, phone_number)
    return WalletOverviewResponse(**data)


@router.post("/expenses/save", response_model=WalletOverviewResponse)
async def save_user_expenses(
    request: SaveExpensesRequest,
    phone_number: Optional[str] = Query(None, description="Farmer phone number"),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Save/update all expense items for the farmer account."""
    overview = await wallet_service.get_wallet_overview(db, phone_number)
    phone = phone_number or overview.get("farmer_name", "guest")

    expenses_dict_list = [item.model_dump() for item in request.expenses]
    await wallet_service.update_user_expenses(db, phone, expenses_dict_list)

    updated_overview = await wallet_service.get_wallet_overview(db, phone_number)
    return WalletOverviewResponse(**updated_overview)



@router.post("/expenses", response_model=WalletOverviewResponse)
async def add_expense(
    request: AddExpenseRequest,
    phone_number: Optional[str] = Query(None, description="Farmer phone number"),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Add a new expense item to the farmer's wallet."""
    overview = await wallet_service.get_wallet_overview(db, phone_number)
    expenses = overview.get("expenses", [])

    new_id = f"custom_{uuid.uuid4().hex[:8]}"
    new_item = {
        "id": new_id,
        "category": request.category.lower().strip(),
        "label": request.label.strip() or "Custom Expense",
        "amount": max(0.0, float(request.amount)),
        "is_custom": True,
    }

    expenses.append(new_item)

    phone = phone_number or overview.get("farmer_name", "guest")
    await wallet_service.update_user_expenses(db, phone, expenses)

    updated_overview = await wallet_service.get_wallet_overview(db, phone_number)
    return WalletOverviewResponse(**updated_overview)


@router.put("/expenses/{expense_id}", response_model=WalletOverviewResponse)
async def update_expense(
    expense_id: str = Path(..., description="ID of expense item to update"),
    request: UpdateExpenseRequest = ...,
    phone_number: Optional[str] = Query(None, description="Farmer phone number"),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Update expense amount (e.g., +/- ₹500 adjustment). Amount cannot go below ₹0."""
    overview = await wallet_service.get_wallet_overview(db, phone_number)
    expenses = overview.get("expenses", [])

    found = False
    new_amount = max(0.0, float(request.amount))
    for item in expenses:
        if item.get("id") == expense_id:
            item["amount"] = new_amount
            found = True
            break

    if not found:
        raise HTTPException(status_code=404, detail="Expense item not found")

    phone = phone_number or overview.get("farmer_name", "guest")
    await wallet_service.update_user_expenses(db, phone, expenses)

    updated_overview = await wallet_service.get_wallet_overview(db, phone_number)
    return WalletOverviewResponse(**updated_overview)


@router.delete("/expenses/{expense_id}", response_model=WalletOverviewResponse)
async def delete_expense(
    expense_id: str = Path(..., description="ID of expense item to delete"),
    phone_number: Optional[str] = Query(None, description="Farmer phone number"),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Delete an expense item from the farmer's wallet."""
    overview = await wallet_service.get_wallet_overview(db, phone_number)
    expenses = overview.get("expenses", [])

    updated_expenses = [item for item in expenses if item.get("id") != expense_id]

    phone = phone_number or overview.get("farmer_name", "guest")
    await wallet_service.update_user_expenses(db, phone, updated_expenses)

    updated_overview = await wallet_service.get_wallet_overview(db, phone_number)
    return WalletOverviewResponse(**updated_overview)


@router.post("/insight/refresh", response_model=WalletOverviewResponse)
async def refresh_wallet_insight(
    phone_number: Optional[str] = Query(None, description="Farmer phone number"),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Manually request a fresh Gemini market insight refresh into MongoDB.
    Enforces a 5-minute cooldown per farmer to prevent duplicate requests.
    """
    if phone_number and phone_number.strip():
        await wallet_service.refresh_gemini_market_insight_async(db, phone_number.strip())
    data = await wallet_service.get_wallet_overview(db, phone_number)
    return WalletOverviewResponse(**data)


@router.post("/reset-expenses", response_model=WalletOverviewResponse)
async def reset_expenses(
    phone_number: Optional[str] = Query(None, description="Farmer phone number"),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Reset expenses to default agricultural MongoDB crop_costs benchmarks."""
    overview = await wallet_service.get_wallet_overview(db, phone_number)
    state = overview.get("state", "Maharashtra")
    crop = overview.get("current_crop", "Soyabean")
    farm_area = overview.get("farm_area", 2.5)
    farm_area_unit = overview.get("farm_area_unit", "acres").lower()

    farm_area_ha = farm_area * 0.404686 if "acre" in farm_area_unit else farm_area
    default_expenses = await wallet_service.get_initial_expenses_from_db(db, state, crop, farm_area_ha)

    phone = phone_number or overview.get("farmer_name", "guest")
    await wallet_service.update_user_expenses(db, phone, default_expenses)

    updated_overview = await wallet_service.get_wallet_overview(db, phone_number)
    return WalletOverviewResponse(**updated_overview)

