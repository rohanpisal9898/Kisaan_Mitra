import os
import uuid
import base64
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, HTTPException, status
from app.database import get_database
from app.models.pest_scan import PestScanJsonRequest, PestScanCreateResponse

router = APIRouter(
    prefix="/api/v1/pest-detection",
    tags=["Pest Detection"],
)

UPLOAD_DIR = os.path.join(os.getcwd(), "uploads", "pest_scans")
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.post(
    "/scan",
    response_model=PestScanCreateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload image via JSON Base64 and create new pest scan record in MongoDB",
)
async def create_pest_scan(body: PestScanJsonRequest):
    """
    Creates a persistent pest scan record in MongoDB and saves the uploaded image.
    Accepts JSON payload with Base64 encoded image string.
    Source must be either 'camera' or 'gallery'.
    """
    source = body.source if body.source in ["camera", "gallery"] else "camera"

    if not body.image_base64:
        raise HTTPException(
            status_code=400,
            detail="Image base64 content is required",
        )

    # Clean base64 string if data URI header is present (e.g. data:image/jpeg;base64,...)
    raw_b64 = body.image_base64
    if "," in raw_b64:
        raw_b64 = raw_b64.split(",", 1)[1]

    try:
        image_bytes = base64.b64decode(raw_b64)
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid base64 image data: {str(e)}",
        )

    if not image_bytes:
        raise HTTPException(
            status_code=400,
            detail="Decoded image file is empty",
        )

    # Generate unique scan ID
    scan_id = f"scan_{uuid.uuid4().hex[:12]}"
    file_extension = ".jpg"
    if body.filename and "." in body.filename:
        file_extension = os.path.splitext(body.filename)[1]

    safe_filename = f"{scan_id}{file_extension}"
    save_path = os.path.join(UPLOAD_DIR, safe_filename)

    # Write file to local uploads directory
    try:
        with open(save_path, "wb") as f:
            f.write(image_bytes)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to save image file: {str(e)}",
        )

    image_url = f"/uploads/pest_scans/{safe_filename}"
    created_at = datetime.utcnow()

    scan_doc = {
        "scan_id": scan_id,
        "user_id": body.user_id or "guest",
        "image_reference": save_path,
        "image_url": image_url,
        "source": source,
        "status": "created",
        "created_at": created_at,
    }

    db = await get_database()
    await db.pest_scans.insert_one(scan_doc)

    return PestScanCreateResponse(
        status="success",
        scan_id=scan_id,
        image_url=image_url,
        source=source,
        message="Pest scan image uploaded and stored in MongoDB successfully",
    )
