import os
import uuid
from fastapi import APIRouter, File, UploadFile, HTTPException, Request
from fastapi.responses import JSONResponse

router = APIRouter()

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/jpg"}

@router.post("/upload")
async def upload_image(request: Request, file: UploadFile = File(...)):
    """Upload leaf image to server and get persistent accessible URL."""
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type '{file.content_type}'. Supported formats: JPEG, PNG, WEBP."
        )

    try:
        content = await file.read()
        if len(content) == 0:
            raise HTTPException(status_code=400, detail="Uploaded file is empty.")

        ext = file.filename.split(".")[-1] if file.filename and "." in file.filename else "jpg"
        unique_name = f"{uuid.uuid4().hex}.{ext}"
        save_path = os.path.join(UPLOAD_DIR, unique_name)

        with open(save_path, "wb") as f:
            f.write(content)

        base_url = str(request.base_url).rstrip("/")
        image_url = f"{base_url}/uploads/{unique_name}"

        return JSONResponse(content={
            "status": "success",
            "filename": unique_name,
            "url": image_url
        })
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image upload failed: {str(e)}")
