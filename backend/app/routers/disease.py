from fastapi import APIRouter, HTTPException
import json
import os

router = APIRouter()

# Load disease info at module level
DISEASE_INFO_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'disease_info.json')

def get_disease_db():
    if not os.path.exists(DISEASE_INFO_PATH):
        return {}
    with open(DISEASE_INFO_PATH, 'r') as f:
        return json.load(f)

disease_db = get_disease_db()

@router.get("/diseases")
async def get_all_diseases():
    """Return all diseases and their information."""
    if not disease_db:
        raise HTTPException(status_code=404, detail="Disease database not found.")
    return disease_db

@router.get("/diseases/{class_label}")
async def get_disease(class_label: str):
    """Return information for a specific disease class label."""
    if not disease_db:
        raise HTTPException(status_code=404, detail="Disease database not found.")
        
    info = disease_db.get(class_label)
    if not info:
        raise HTTPException(status_code=404, detail=f"Disease info not found for {class_label}.")
        
    return info
