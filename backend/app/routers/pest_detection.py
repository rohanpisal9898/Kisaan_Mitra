import os
import uuid
import base64
from datetime import datetime
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field
from fastapi import APIRouter, HTTPException, status
from app.database import get_database
from app.models.pest_scan import PestScanJsonRequest, PestScanCreateResponse
from app.integrations.gemini import get_gemini_pest_questions, get_gemini_pest_diagnosis, validate_crop_image

router = APIRouter(
    prefix="/api/v1/pest-detection",
    tags=["Pest Detection"],
)

UPLOAD_DIR = os.path.join(os.getcwd(), "uploads", "pest_scans")
os.makedirs(UPLOAD_DIR, exist_ok=True)


class PestValidationRequest(BaseModel):
    image_base64: str
    language: Optional[str] = "English"


@router.post(
    "/validate",
    summary="Validate whether uploaded image is relevant for crop pest diagnosis",
)
async def validate_pest_image_endpoint(body: PestValidationRequest):
    """
    Lightweight validation endpoint to check image relevance before full pest scan.
    """
    if not body.image_base64:
        raise HTTPException(
            status_code=400,
            detail="Image base64 content is required",
        )

    raw_b64 = body.image_base64
    if "," in raw_b64:
        raw_b64 = raw_b64.split(",", 1)[1]

    result = await validate_crop_image(image_base64=raw_b64, language=body.language or "English")
    return {
        "status": "success",
        "validation": result,
    }


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
    Generates dynamic Gemini Yes/No questions.
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
    # Validate image relevance before generating scan record or questions
    requested_lang = body.language or "English"
    val = await validate_crop_image(image_base64=raw_b64, language=requested_lang)
    if not val.get("is_valid_for_pest_detection", True):
        cat = val.get("category", "random_object")
        raise HTTPException(
            status_code=400,
            detail=f"INVALID_CROP_IMAGE:{cat}",
        )

    # Generate dynamic Yes/No questions via Gemini
    questions = await get_gemini_pest_questions(image_base64=raw_b64, language=requested_lang)

    created_at = datetime.utcnow()

    scan_doc = {
        "scan_id": scan_id,
        "user_id": body.user_id or "guest",
        "image_reference": save_path,
        "image_url": image_url,
        "source": source,
        "questions": questions,
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
        questions=questions,
    )


class PestDiagnosisRequest(BaseModel):
    scan_id: Optional[str] = None
    user_id: Optional[str] = "guest"
    image_base64: Optional[str] = None
    answers: Optional[Dict[str, str]] = None
    language: Optional[str] = "English"


@router.post(
    "/diagnosis",
    summary="Generate dynamic AI Diagnosis Report based on scan image and 5 Yes/No answers",
)
async def generate_pest_diagnosis_endpoint(body: PestDiagnosisRequest):
    """
    Generates dynamic Diagnosis Report details using Gemini integration,
    and persists full diagnosis results to MongoDB scan record.
    """
    requested_lang = body.language or "English"
    report = await get_gemini_pest_diagnosis(
        image_base64=body.image_base64,
        answers=body.answers,
        language=requested_lang,
    )

    scan_id = body.scan_id or f"scan_{uuid.uuid4().hex[:12]}"
    now = datetime.utcnow()

    db = await get_database()
    # Update existing scan record if present or create record
    update_data = {
        "diagnosis": report,
        "answers": body.answers,
        "language": requested_lang,
        "status": "completed",
        "updated_at": now,
    }
    if body.user_id:
        update_data["user_id"] = body.user_id

    result = await db.pest_scans.find_one_and_update(
        {"scan_id": scan_id},
        {"$set": update_data},
        return_document=True,
    )

    image_url = result.get("image_url") if result else None

    return {
        "status": "success",
        "scan_id": scan_id,
        "image_url": image_url,
        "diagnosis": report,
    }


@router.get(
    "/history",
    summary="Fetch past pest scan reports for user",
)
async def get_pest_history_endpoint(user_id: Optional[str] = "guest", limit: int = 50):
    """
    Returns list of saved pest scan reports for a given user sorted by timestamp descending.
    """
    db = await get_database()
    query = {}
    if user_id and user_id != "all":
        query["user_id"] = user_id

    cursor = db.pest_scans.find(query).sort("created_at", -1).limit(limit)
    scans = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        if "created_at" in doc and isinstance(doc["created_at"], datetime):
            doc["created_at"] = doc["created_at"].isoformat()
        if "updated_at" in doc and isinstance(doc["updated_at"], datetime):
            doc["updated_at"] = doc["updated_at"].isoformat()
        scans.append(doc)

    return {
        "status": "success",
        "count": len(scans),
        "reports": scans,
    }


@router.get(
    "/scans/{scan_id}",
    summary="Fetch single pest scan report details by scan ID",
)
async def get_pest_scan_by_id_endpoint(scan_id: str):
    """
    Returns full scan record and diagnosis data for a given scan_id.
    """
    db = await get_database()
    doc = await db.pest_scans.find_one({"scan_id": scan_id})
    if not doc:
        raise HTTPException(
            status_code=404,
            detail=f"Pest scan report with ID {scan_id} not found",
        )

    doc["_id"] = str(doc["_id"])
    if "created_at" in doc and isinstance(doc["created_at"], datetime):
        doc["created_at"] = doc["created_at"].isoformat()
    if "updated_at" in doc and isinstance(doc["updated_at"], datetime):
        doc["updated_at"] = doc["updated_at"].isoformat()

    return {
        "status": "success",
        "scan": doc,
    }


