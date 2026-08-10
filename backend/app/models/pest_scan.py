from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class PestScanJsonRequest(BaseModel):
    """Request model for uploading pest scan via JSON Base64."""
    image_base64: str = Field(..., description="Base64 encoded image string")
    source: str = Field("camera", description="Source of image: camera or gallery")
    user_id: Optional[str] = Field("guest", description="Optional user phone number or ID")
    filename: Optional[str] = Field("pest_scan.jpg", description="Original image filename")


class PestScanCreateResponse(BaseModel):
    """Response model after uploading a pest scan image."""
    status: str = Field(..., example="success")
    scan_id: str = Field(..., description="Unique ID for the created scan")
    image_url: str = Field(..., description="Relative or absolute URL of stored image")
    source: str = Field(..., description="Source of image: camera or gallery")
    message: str = Field("Scan image saved successfully", description="Status message")


class PestScanDocument(BaseModel):
    """Database model for pest scan records in MongoDB."""
    scan_id: str
    user_id: Optional[str] = "guest"
    image_reference: str
    image_url: str
    source: str  # "camera" or "gallery"
    status: str = "created"
    created_at: datetime
