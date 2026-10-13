import datetime
from typing import Optional, List, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from app.database import db_manager

router = APIRouter()

class DetectionRecord(BaseModel):
    id: Optional[str] = None
    uid: str
    class_label: Optional[str] = ""
    plant_name: str
    disease_name: str
    confidence: float
    image_url: Optional[str] = ""
    is_healthy: Optional[bool] = False
    timestamp: Optional[str] = None
    management_tips: Optional[List[str]] = Field(default_factory=list)

@router.get("/db/status")
async def database_status():
    """Check active database type (MongoDB Atlas, Firebase, or SQLite)."""
    return db_manager.get_status()

@router.post("/history")
async def save_history(record: DetectionRecord):
    """Save a detection record to active cloud/local database."""
    try:
        record_dict = record.model_dump()
        record_id = db_manager.save_history(record_dict)
        return {
            "status": "success",
            "id": record_id,
            "database": db_manager.db_type
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save record: {str(e)}")

@router.get("/history/{uid}")
async def get_history(uid: str):
    """Fetch all detection records for a user from active database."""
    try:
        results = db_manager.get_history(uid)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch history: {str(e)}")
