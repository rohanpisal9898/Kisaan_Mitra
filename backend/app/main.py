import warnings
import importlib.metadata

# Suppress noisy external deprecation and EOL FutureWarnings for clean console logs
warnings.filterwarnings("ignore", category=FutureWarning)
warnings.filterwarnings("ignore", category=DeprecationWarning)
warnings.filterwarnings("ignore", message=".*Python version 3.9.*")

# Compatibility shim for Python < 3.10 importlib.metadata
if not hasattr(importlib.metadata, "packages_distributions"):
    try:
        import importlib_metadata  # type: ignore
        importlib.metadata.packages_distributions = importlib_metadata.packages_distributions
    except Exception:
        importlib.metadata.packages_distributions = lambda: {}

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


import os
import asyncio
from datetime import datetime
from typing import Optional
import httpx
from fastapi.staticfiles import StaticFiles
from app.utils.http_client import get_http_client, close_http_client
from app.config import get_settings

_self_ping_task: Optional[asyncio.Task] = None


async def self_ping_worker():
    """
    Self-ping background task to keep Render free-tier instances alive.
    Runs every 10 minutes, pinging the /health endpoint.
    """
    await asyncio.sleep(15)  # Initial delay after boot

    settings = get_settings()
    render_url = (
        os.getenv("RENDER_EXTERNAL_URL")
        or os.getenv("SELF_PING_URL")
        or os.getenv("RENDER_URL")
        or settings.render_external_url
    )

    if not render_url:
        print("[SELF-PING] No RENDER_EXTERNAL_URL configured. Self-ping idle (will activate if RENDER_EXTERNAL_URL is set).")
        return

    if not render_url.startswith("http://") and not render_url.startswith("https://"):
        render_url = f"https://{render_url}"
    render_url = render_url.rstrip("/")
    health_url = f"{render_url}/health"

    interval = max(60, settings.self_ping_interval_seconds)
    print(f"[SELF-PING] Keep-alive worker started. Target: {health_url} (every {interval // 60}m)")

    async with httpx.AsyncClient(timeout=10.0) as client:
        while True:
            try:
                await asyncio.sleep(interval)
                resp = await client.get(health_url)
                if resp.status_code == 200:
                    print(f"[SELF-PING OK] Server kept alive via {health_url} at {datetime.now().strftime('%H:%M:%S')}")
                else:
                    print(f"[SELF-PING WARN] Status {resp.status_code} from {health_url}")
            except asyncio.CancelledError:
                print("[SELF-PING] Worker cancelled on shutdown.")
                break
            except Exception as e:
                print(f"[SELF-PING NOTICE] Ping attempt notice: {e}")


# Startup and shutdown events
@app.on_event("startup")
async def startup_event():
    """Initialize services on startup."""
    global _self_ping_task
    await connect_to_mongo()
    get_http_client()
    try:
        model_loader.load_models()
    except Exception as e:
        print(f"[WARNING] ML model loading warning: {e}")

    # Launch Render self-ping keep-alive task
    _self_ping_task = asyncio.create_task(self_ping_worker())

    print("=" * 50)
    print("  Kisaan Mitra Backend v2.0 Started")
    print("=" * 50)


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown."""
    global _self_ping_task
    if _self_ping_task and not _self_ping_task.done():
        _self_ping_task.cancel()
        try:
            await _self_ping_task
        except asyncio.CancelledError:
            pass
    await close_mongo_connection()
    await close_http_client()
    print("Kisaan Mitra Backend Stopped")


# Health check endpoints
@app.get("/")
async def root():
    return {
        "message": "Kisaan Mitra API",
        "status": "online",
        "version": "2.0.0",
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/health")
@app.get("/api/v1/health")
async def health():
    return {
        "status": "healthy",
        "service": "kisaan_mitra_backend",
        "version": "2.0.0",
        "timestamp": datetime.utcnow().isoformat(),
    }


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

