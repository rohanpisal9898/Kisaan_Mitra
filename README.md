## Project Overview

**Kisaan Mitra v2.0** - AI-Driven Yield Optimization Platform for Indian Farmers.

Rebuilt as a **Flutter mobile app** backed by **FastAPI + MongoDB Atlas**.

## Architecture

```
Kisaan_Mitra/
├── backend/              # FastAPI backend
│   ├── data/             # district_coords.csv (seed source)
│   ├── scripts/          # seed_districts.py (run once)
│   ├── app/              # FastAPI application
│   │   ├── main.py       # Entry point
│   │   ├── config.py     # Settings from .env
│   │   ├── database.py   # MongoDB connection
│   │   ├── routers/      # API endpoints
│   │   ├── services/     # Business logic
│   │   ├── models/       # Pydantic schemas
│   │   └── utils/        # Haversine, constants
│   ├── .env              # Environment variables
│   └── requirements.txt
│
├── flutter_app/          # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart     # App entry point
│   │   ├── theme/        # Color palette, typography
│   │   ├── l10n/         # 3 languages: en, hi, mr
│   │   ├── screens/      # Splash, Language, Profile, Farm, Analysis, Dashboard
│   │   ├── services/     # API communication
│   │   └── widgets/      # Reusable components
│   └── pubspec.yaml
│
└── district_coords.csv   # Source CSV (755 districts)
```

## Key Design Decisions

### 1. District Data Flow (Single Source of Truth)
```
district_coords.csv → seed_districts.py → MongoDB → FastAPI → Flutter
```
- CSV is ONLY the initial seed source
- Flutter NEVER touches the CSV
- All state/district data comes via API from MongoDB
- Adding/updating districts only requires re-seeding (no Flutter update needed)

### 2. Three Languages Only
- English (en), Hindi (hi), Marathi (mr)
- All strings in `lib/l10n/app_localizations.dart`
- Language preference stored in SharedPreferences + user document

### 3. GPS Auto-Detect
- Phone GPS → lat/lon → FastAPI `/nearest-district` → Haversine distance → State + District
- Same MongoDB `districts` collection used for dropdown AND GPS matching

## Tech Stack

- **Backend**: FastAPI (Python 3.9+)
- **Database**: MongoDB Atlas (database: `kisaan_mitra`)
- **Frontend**: Flutter (Dart)
- **ML Models**: CatBoost (to be added)
- **LLM**: Google Gemini API (gemini-2.5-flash, gemini-3.5-flash-lite, gemini-3.6-flash, gemini-3.6-flash-lite, gemini-3.6-lite)

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/api/v1/locations/states` | GET | List all states |
| `/api/v1/locations/districts/{state}` | GET | List districts for state |
| `/api/v1/locations/nearest-district` | GET | GPS → nearest district |
| `/api/v1/locations/district-coords` | GET | Get coords for district |
| `/api/v1/users/register` | POST | Register/update user |
| `/api/v1/users/{phone}` | GET | Get user by phone |
| `/api/v1/users/{phone}` | PUT | Update user |
| `/api/v1/schemes` | GET | Fetch Central & State govt schemes (Gemini + 1-Week MongoDB TTL Cache) |

## Commands

```powershell
# Backend
cd backend
pip install -r requirements.txt
python scripts/seed_districts.py          # Run once to seed MongoDB
python -m uvicorn app.main:app --reload   # Start backend

# Flutter (after installing Flutter SDK)
cd flutter_app
flutter pub get
flutter run
```

## Environment Variables

```
GEMINI_API_KEY=<Google Gemini API Key>
MONGODB_URI=<MongoDB Atlas Connection String>
```

## Supported Crops

Groundnut, Soyabean, Castor seed, Sunflower, Sesamum, Rapeseed &Mustard, Linseed, Safflower, Niger seed
