"""
Shared HTTP client pool for Kisaan Mitra backend.
Reuses connection pools and SSL sessions across requests instead of re-establishing TCP handshakes.
"""

from typing import Optional
import httpx
from app.config import get_settings

_http_client: Optional[httpx.AsyncClient] = None

def get_http_client() -> httpx.AsyncClient:
    """Returns the shared httpx.AsyncClient instance."""
    global _http_client
    if _http_client is None or _http_client.is_closed:
        settings = get_settings()
        timeout = httpx.Timeout(
            timeout=settings.gemini_total_timeout,
            connect=settings.gemini_connect_timeout,
            read=settings.gemini_read_timeout,
        )
        limits = httpx.Limits(max_keepalive_connections=20, max_connections=50, keepalive_expiry=30.0)
        _http_client = httpx.AsyncClient(timeout=timeout, limits=limits)
    return _http_client

async def close_http_client() -> None:
    """Closes the shared HTTP client pool gracefully on shutdown."""
    global _http_client
    if _http_client is not None and not _http_client.is_closed:
        await _http_client.aclose()
        _http_client = None
