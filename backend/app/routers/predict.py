from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import httpx
import os

router = APIRouter()

PLANTNET_API_URL = "https://my-api.plantnet.org/v2/diseases/identify"
ALLOWED_TYPES = {"image/jpeg", "image/png"}
MAX_IMAGE_BYTES = 50 * 1024 * 1024


@router.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Upload a JPEG or PNG leaf image to PlantNet for disease identification.

    Returns a flat JSON object with:
    - class_label, confidence, plant_name, disease_name, is_healthy, mock
    - disease_info: { plant, disease, description, symptoms, causes, management, severity }
    """
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type '{file.content_type}'. PlantNet accepts JPEG and PNG images."
        )

    api_key = os.getenv("PLANTNET_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail="PlantNet is not configured. Set PLANTNET_API_KEY on the backend host."
        )

    try:
        contents = await file.read()
        if not contents:
            raise HTTPException(status_code=400, detail="Uploaded file is empty.")
        if len(contents) > MAX_IMAGE_BYTES:
            raise HTTPException(status_code=413, detail="Image exceeds PlantNet's 50 MB limit.")

        async with httpx.AsyncClient(timeout=30.0) as client:
            upstream = await client.post(
                PLANTNET_API_URL,
                params={"api-key": api_key, "lang": "en", "nb-results": 5},
                files={
                    "image": (
                        file.filename or "leaf.jpg",
                        contents,
                        file.content_type,
                    )
                },
            )

        if upstream.status_code in (401, 403):
            raise HTTPException(status_code=502, detail="PlantNet rejected the configured API key.")
        if upstream.status_code == 429:
            raise HTTPException(status_code=429, detail="PlantNet request quota has been reached.")
        if upstream.is_error:
            raise HTTPException(status_code=502, detail="PlantNet could not process this image.")

        payload = upstream.json()
        results = payload.get("results", [])
        if not results:
            raise HTTPException(
                status_code=422,
                detail="PlantNet found no supported disease match for this image.",
            )

        best_match = results[0]
        disease_name = best_match.get("description") or best_match.get("name") or "Plant disease"
        confidence = float(best_match.get("score", 0.0))
        disease_info = {
            "plant": "Plant",
            "disease": disease_name,
            "description": disease_name,
            "symptoms": [],
            "causes": "",
            "management": [],
            "severity": "Unknown",
        }

        response = {
            "class_label": best_match.get("name", ""),
            "confidence": confidence,
            "plant_name": "Plant",
            "disease_name": disease_name,
            "is_healthy": False,
            "mock": False,
            "disease_info": disease_info,
        }

        return JSONResponse(content=response)
    except HTTPException:
        raise
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="PlantNet took too long to respond.")
    except httpx.HTTPError:
        raise HTTPException(status_code=502, detail="Could not connect to PlantNet.")
    except ValueError:
        raise HTTPException(
            status_code=502,
            detail="PlantNet returned an invalid response.",
        )

