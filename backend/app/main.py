import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import logging
from app.routers import predict, disease, history, upload
from app.model.model_loader import load_model_on_startup

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Ensure uploads directory exists
UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load ML model at startup
    logger.info("Loading plant disease detection model...")
    load_model_on_startup()
    logger.info("Model loaded successfully.")
    yield
    logger.info("Shutting down...")

app = FastAPI(
    title="Plant Disease Detection API",
    description="AI-powered plant leaf disease detection using MobileNetV2 CNN with Multi-Cloud Database support.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static file serving for scan images
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

app.include_router(predict.router, prefix="/api", tags=["Prediction"])
app.include_router(disease.router, prefix="/api", tags=["Diseases"])
app.include_router(history.router, prefix="/api", tags=["History & Cloud DB"])
app.include_router(upload.router, prefix="/api", tags=["Upload"])

@app.get("/", tags=["Health"])
async def health_check():
    """API health check endpoint."""
    return {"status": "ok", "message": "Plant Disease Detection API is running."}
