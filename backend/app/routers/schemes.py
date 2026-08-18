from fastapi import APIRouter, Depends, Query
from typing import Optional, Dict, Any, List
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.services.user_service import user_service
from app.integrations.gemini import get_gemini_government_schemes

router = APIRouter(prefix="/api/v1/schemes", tags=["Government Schemes"])


@router.get("")
async def get_government_schemes(
    phone_number: Optional[str] = Query(None, description="Farmer phone number"),
    state: Optional[str] = Query(None, description="Farmer state"),
    language: str = Query("English", description="Requested language (English, Hindi, Marathi)"),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> Dict[str, Any]:
    """
    Get government agricultural schemes (Central and State) using Gemini integration.
    Respects farmer's actual state and requested language.
    """
    farmer_state = state or "Maharashtra"
    farmer_district = ""
    farmer_crop = ""

    if phone_number:
        user = await user_service.get_user_by_phone(db, phone_number)
        if user:
            farmer_state = user.state or farmer_state
            farmer_district = user.district or ""
            farmer_crop = user.current_crop or ""

    farmer_context = {
        "state": farmer_state,
        "district": farmer_district,
        "crop": farmer_crop,
    }

    schemes = await get_gemini_government_schemes(farmer_context, language)

    if schemes:
        return {
            "success": True,
            "source": "gemini",
            "state": farmer_state,
            "schemes": schemes,
        }

    # Fallback schemes if Gemini API key is missing or call fails
    fallbacks = _get_fallback_schemes(farmer_state, language)
    return {
        "success": True,
        "source": "fallback",
        "state": farmer_state,
        "schemes": fallbacks,
    }


def _get_fallback_schemes(farmer_state: str, language: str) -> List[Dict[str, Any]]:
    lang_lower = language.lower()
    is_hi = "hi" in lang_lower or "hindi" in lang_lower
    is_mr = "mr" in lang_lower or "marathi" in lang_lower

    if is_hi:
        return [
            {
                "id": "scheme_1",
                "name": "पीएम किसान सम्मान निधि",
                "category": "आय सहायता",
                "description": "पात्र किसान परिवारों को प्रति वर्ष ₹6,000 की सीधी वित्तीय सहायता। तीन किश्तों में हस्तांतरित।",
                "governmentLevel": "Central",
                "state": "All",
                "status": "सक्रिय",
                "officialUrl": "https://pmkisan.gov.in/",
            },
            {
                "id": "scheme_2",
                "name": "प्रधानमंत्री फसल बीमा योजना (PMFBY)",
                "category": "फसल बीमा",
                "description": "प्राकृतिक आपदाओं, कीटों और बीमारियों के कारण होने वाले फसल नुकसान से वित्तीय सुरक्षा प्रदान करता है।",
                "governmentLevel": "Central",
                "state": "All",
                "status": "सक्रिय",
                "officialUrl": "https://pmfby.gov.in/",
            },
            {
                "id": "scheme_3",
                "name": "किसान क्रेडिट कार्ड (KCC)",
                "category": "कृषि ऋण",
                "description": "खेती, इनपुट खरीद और फसल के बाद के खर्चों के लिए रियायती ब्याज दर पर ऋण सुविधा।",
                "governmentLevel": "Central",
                "state": "All",
                "status": "सक्रिय",
                "officialUrl": "https://myscheme.gov.in/schemes/kcc",
            },
            {
                "id": "scheme_4",
                "name": f"नमो शेतकरी महासन्मान निधि योजना ({farmer_state})",
                "category": "राज्य आय सहायता",
                "description": f"{farmer_state} के किसानों के लिए अतिरिक्त ₹6,000 वार्षिक सहायता जो पीएम-किसान योजना को पूरक बनाती है।",
                "governmentLevel": "State",
                "state": farmer_state,
                "status": "सक्रिय",
                "officialUrl": "https://krishi.maharashtra.gov.in/",
            },
            {
                "id": "scheme_5",
                "name": f"मागेल त्याला शेततळे (मागने पर खेत तालाब - {farmer_state})",
                "category": "जल संरक्षण",
                "description": f"{farmer_state} में व्यक्तिगत किसानों को खेत तालाब निर्माण के लिए वित्तीय सब्सिडी प्रदान की जाती है।",
                "governmentLevel": "State",
                "state": farmer_state,
                "status": "सक्रिय",
                "officialUrl": "https://krishi.maharashtra.gov.in/",
            },
            {
                "id": "scheme_6",
                "name": f"मुख्यमंत्री कृषि पंप योजना ({farmer_state})",
                "category": "सौर ऊर्जा एवं सिंचाई",
                "description": f"{farmer_state} के किसानों को दिन के समय सिंचाई सुविधा हेतु रियायती दरों पर सोलर पंप।",
                "governmentLevel": "State",
                "state": farmer_state,
                "status": "सक्रिय",
                "officialUrl": "https://krishi.maharashtra.gov.in/",
            },
        ]
    elif is_mr:
        return [
            {
                "id": "scheme_1",
                "name": "पीएम किसान सन्मान निधी",
                "category": "उत्पन्न मदत",
                "description": "पात्र शेतकरी कुटुंबांना दरवर्षी ₹६,००० ची थेट आर्थिक मदत. तीन समान हप्त्यांमध्ये दिली जाते.",
                "governmentLevel": "Central",
                "state": "All",
                "status": "सक्रिय",
                "officialUrl": "https://pmkisan.gov.in/",
            },
            {
                "id": "scheme_2",
                "name": "पंतप्रधान पीक विमा योजना (PMFBY)",
                "category": "पीक विमा",
                "description": "नैसर्गिक आपत्ती, कीड व रोगांमुळे होणाऱ्या पिकांच्या नुकसानीस सर्वसमावेशक विमा संरक्षण.",
                "governmentLevel": "Central",
                "state": "All",
                "status": "सक्रिय",
                "officialUrl": "https://pmfby.gov.in/",
            },
            {
                "id": "scheme_3",
                "name": "किसान क्रेडिट कार्ड (KCC)",
                "category": "शेती कर्ज",
                "description": "शेती खर्च, बियाणे, खते खरेदीसाठी सवलतीच्या व्याजदरात अल्पमुदतीचे कर्ज.",
                "governmentLevel": "Central",
                "state": "All",
                "status": "सक्रिय",
                "officialUrl": "https://myscheme.gov.in/schemes/kcc",
            },
            {
                "id": "scheme_4",
                "name": f"नमो शेतकरी महासन्मान निधी योजना ({farmer_state})",
                "category": "राज्य उत्पन्न मदत",
                "description": f"{farmer_state} मधील शेतकऱ्यांसाठी अतिरिक्त वार्षिक ₹६,००० अर्थसहाय्य.",
                "governmentLevel": "State",
                "state": farmer_state,
                "status": "सक्रिय",
                "officialUrl": "https://krishi.maharashtra.gov.in/",
            },
            {
                "id": "scheme_5",
                "name": f"मागेल त्याला शेततळे योजना ({farmer_state})",
                "category": "जलसंधारण",
                "description": f"{farmer_state} मधील शेतकऱ्यांना सिंचनासाठी शेततळे उभारण्यास शासकीय अनुदान.",
                "governmentLevel": "State",
                "state": farmer_state,
                "status": "सक्रिय",
                "officialUrl": "https://krishi.maharashtra.gov.in/",
            },
            {
                "id": "scheme_6",
                "name": f"मुख्यमंत्री सौर कृषि पंप योजना ({farmer_state})",
                "category": "सौर ऊर्जा व सिंचन",
                "description": f"{farmer_state} मधील शेतकऱ्यांना दिवसा सिंचन उपलब्ध होण्यासाठी सवलतीवर सोलर पंप संच.",
                "governmentLevel": "State",
                "state": farmer_state,
                "status": "सक्रिय",
                "officialUrl": "https://krishi.maharashtra.gov.in/",
            },
        ]
    else:
        return [
            {
                "id": "scheme_1",
                "name": "PM Kisan Samman Nidhi",
                "category": "Income Support",
                "description": "Direct financial benefit of ₹6,000 per year to eligible farmer families across India in 3 equal installments.",
                "governmentLevel": "Central",
                "state": "All",
                "status": "Active",
                "officialUrl": "https://pmkisan.gov.in/",
            },
            {
                "id": "scheme_2",
                "name": "Pradhan Mantri Fasal Bima Yojana (PMFBY)",
                "category": "Crop Insurance",
                "description": "Comprehensive insurance coverage for crop loss due to non-preventable natural risks, pests & diseases.",
                "governmentLevel": "Central",
                "state": "All",
                "status": "Active",
                "officialUrl": "https://pmfby.gov.in/",
            },
            {
                "id": "scheme_3",
                "name": "Kisan Credit Card (KCC)",
                "category": "Agricultural Credit",
                "description": "Timely access to short-term credit at subsidized interest rates for crop cultivation and farm maintenance.",
                "governmentLevel": "Central",
                "state": "All",
                "status": "Active",
                "officialUrl": "https://myscheme.gov.in/schemes/kcc",
            },
            {
                "id": "scheme_4",
                "name": f"Namo Shetkari MahaSanman Nidhi ({farmer_state})",
                "category": "State Income Support",
                "description": f"Additional annual income support of ₹6,000 provided by the {farmer_state} Government to local farmers.",
                "governmentLevel": "State",
                "state": farmer_state,
                "status": "Active",
                "officialUrl": "https://krishi.maharashtra.gov.in/",
            },
            {
                "id": "scheme_5",
                "name": f"Magel Tyala Shettale (Farm Pond Scheme - {farmer_state})",
                "category": "Water Conservation",
                "description": f"Financial subsidy for constructing individual farm ponds for sustainable irrigation in {farmer_state}.",
                "governmentLevel": "State",
                "state": farmer_state,
                "status": "Active",
                "officialUrl": "https://krishi.maharashtra.gov.in/",
            },
            {
                "id": "scheme_6",
                "name": f"Chief Minister Solar Agriculture Pump Scheme ({farmer_state})",
                "category": "Solar Energy & Irrigation",
                "description": f"Subsidized off-grid solar agricultural pumps for daytime irrigation security for farmers in {farmer_state}.",
                "governmentLevel": "State",
                "state": farmer_state,
                "status": "Active",
                "officialUrl": "https://krishi.maharashtra.gov.in/",
            },
        ]
