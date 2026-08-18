from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import connect_to_mongo, close_mongo_connection
from app.ml.model_loader import model_loader

# Initialize FastAPI app
app = FastAPI(
    title="Kisaan Mitra API",
    description="AI-Driven Yield Optimization Platform for Indian Farmers",
    version="2.0.0",
)

# CORS middleware - allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Startup and shutdown events
@app.on_event("startup")
async def startup_event():
    """Initialize services on startup."""
    await connect_to_mongo()
    try:
        model_loader.load_models()
    except Exception as e:
        print(f"[WARNING] ML model loading warning: {e}")
    print("=" * 50)
    print("  Kisaan Mitra Backend v2.0 Started")
    print("=" * 50)


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown."""
    await close_mongo_connection()
    print("Kisaan Mitra Backend Stopped")


# Health check
@app.get("/")
async def root():
    return {
        "message": "Kisaan Mitra API",
        "status": "online",
        "version": "2.0.0",
    }


@app.get("/health")
async def health():
    return {"status": "healthy"}


import os
from fastapi.staticfiles import StaticFiles

# Mount static uploads directory for serving scan photos
uploads_dir = os.path.join(os.getcwd(), "uploads")
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

# Import and include routers
from app.routers import locations, users, pest_detection, dashboard, wallet, schemes

app.include_router(locations.router)
app.include_router(users.router)
app.include_router(pest_detection.router)
app.include_router(dashboard.router)
app.include_router(wallet.router)
app.include_router(schemes.router)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)

