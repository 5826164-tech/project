from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import json
import os
from app.model.model_loader import predict_disease

router = APIRouter()

DISEASE_INFO_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "disease_info.json")
with open(DISEASE_INFO_PATH, "r") as disease_file:
    disease_db = json.load(disease_file)

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic"}


@router.post("/predict")
async def predict(file: UploadFile = File(...)):
    """Classify an uploaded plant image using the locally hosted model."""
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type '{file.content_type}'. Only JPEG, PNG, WEBP, and HEIC images are supported.",
        )

    try:
        contents = await file.read()
        if not contents:
            raise HTTPException(status_code=400, detail="Uploaded file is empty.")

        prediction = predict_disease(contents)
        class_label = prediction.get("class_label", "")
        return JSONResponse(content={
            "class_label": class_label,
            "confidence": prediction.get("confidence"),
            "plant_name": prediction.get("plant_name"),
            "disease_name": prediction.get("disease_name"),
            "is_healthy": prediction.get("is_healthy"),
            "mock": prediction.get("mock", False),
            "disease_info": disease_db.get(class_label, {}),
        })
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(status_code=500, detail=f"Error processing image: {error}")