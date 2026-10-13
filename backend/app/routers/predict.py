from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import json
import os
from app.model.model_loader import predict_disease

router = APIRouter()

# Load disease info to enrich predictions at module startup
DISEASE_INFO_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'disease_info.json')
with open(DISEASE_INFO_PATH, 'r') as f:
    disease_db = json.load(f)

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic"}


@router.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Upload a plant leaf image (JPEG/PNG/WEBP) to get disease prediction.

    Returns a flat JSON object with:
    - class_label, confidence, plant_name, disease_name, is_healthy, mock
    - disease_info: { plant, disease, description, symptoms, causes, management, severity }
    """
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type '{file.content_type}'. Only JPEG, PNG, and WEBP images are supported."
        )

    try:
        # Read uploaded image bytes
        contents = await file.read()

        if len(contents) == 0:
            raise HTTPException(status_code=400, detail="Uploaded file is empty.")

        # Run model inference
        prediction = predict_disease(contents)
        class_label = prediction.get("class_label", "")

        # Look up disease information from the database
        disease_info = disease_db.get(class_label, {})

        # Return a single flat response — easy to parse in Flutter
        response = {
            "class_label": prediction.get("class_label"),
            "confidence": prediction.get("confidence"),
            "plant_name": prediction.get("plant_name"),
            "disease_name": prediction.get("disease_name"),
            "is_healthy": prediction.get("is_healthy"),
            "mock": prediction.get("mock", False),
            "disease_info": disease_info,
        }

        return JSONResponse(content=response)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error processing image: {str(e)}"
        )

