"""Constants for the Kisaan Mitra backend"""

# Supported oilseed crops
OILSEED_CROPS = [
    "Groundnut",
    "Soyabean",
    "Castor seed",
    "Sunflower",
    "Sesamum",
    "Rapeseed &Mustard",
    "Linseed",
    "Safflower",
    "Niger seed"
]

# Seasons
SEASONS = ["Kharif", "Rabi", "Zaid"]

# Supported languages
SUPPORTED_LANGUAGES = {
    "en": "English",
    "hi": "Hindi",
    "mr": "Marathi"
}


# Pest risk thresholds
def categorize_pest_risk(observed_days: int) -> str:
    """Categorize pest risk based on observed pest risk days"""
    if observed_days == 0:
        return "low"
    elif observed_days <= 3:
        return "medium"
    elif observed_days <= 7:
        return "high"
    else:
        return "critical"


# Season determination
def get_season_from_month(month: int) -> str:
    """Determine agricultural season from month"""
    if 6 <= month <= 10:
        return "Kharif"
    elif month >= 11 or month <= 3:
        return "Rabi"
    else:  # 4, 5
        return "Zaid"


# Alias for backward compatibility
get_season = get_season_from_month
