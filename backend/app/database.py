"""
Universal Database Handler for PlantCare AI
Supports:
1. MongoDB Atlas (Cloud NoSQL DB) via MONGODB_URI
2. Google Cloud Firestore via FIREBASE_CREDENTIALS_PATH
3. SQLite (Local / Offline persistent fallback)
"""

import os
import sqlite3
import datetime
import logging
from typing import List, Dict, Any, Optional
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger("plantcare.database")

# Environment configs
MONGODB_URI = os.getenv("MONGODB_URI", "")
FIREBASE_CREDENTIALS_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
SQLITE_DB_PATH = os.getenv("SQLITE_DB_PATH", os.path.join(os.path.dirname(os.path.dirname(__file__)), "plantcare.db"))

class DatabaseManager:
    def __init__(self):
        self.db_type = "none"
        self._mongo_client = None
        self._mongo_collection = None
        self._firestore_client = None
        self._init_database()

    def _init_database(self):
        # 1. Try MongoDB Atlas Cloud
        if MONGODB_URI:
            try:
                from pymongo import MongoClient
                logger.info("Connecting to MongoDB Atlas Cloud Database...")
                client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
                # Verify connection
                client.admin.command('ping')
                db = client.get_database(os.getenv("MONGODB_DB_NAME", "plantcare_ai"))
                self._mongo_client = client
                self._mongo_collection = db.get_collection("history")
                self.db_type = "mongodb_cloud"
                logger.info("Connected to MongoDB Atlas successfully!")
                return
            except Exception as e:
                logger.warning(f"MongoDB connection failed: {e}. Falling back...")

        # 2. Try Firebase Firestore Cloud
        if os.path.exists(FIREBASE_CREDENTIALS_PATH):
            try:
                import firebase_admin
                from firebase_admin import credentials, firestore
                logger.info(f"Connecting to Firebase Firestore using {FIREBASE_CREDENTIALS_PATH}...")
                if not firebase_admin._apps:
                    cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
                    firebase_admin.initialize_app(cred)
                self._firestore_client = firestore.client()
                self.db_type = "firestore_cloud"
                logger.info("Connected to Firebase Firestore successfully!")
                return
            except Exception as e:
                logger.warning(f"Firebase Firestore initialization failed: {e}. Falling back...")

        # 3. Fallback to Local Persistent SQLite DB
        self.db_type = "sqlite_local"
        logger.info(f"Using SQLite persistent database at {SQLITE_DB_PATH}")
        self._init_sqlite()

    def _init_sqlite(self):
        with sqlite3.connect(SQLITE_DB_PATH) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS history (
                    id TEXT PRIMARY KEY,
                    uid TEXT NOT NULL,
                    class_label TEXT,
                    plant_name TEXT NOT NULL,
                    disease_name TEXT NOT NULL,
                    confidence REAL NOT NULL,
                    image_url TEXT,
                    timestamp TEXT NOT NULL,
                    management_tips TEXT,
                    is_healthy INTEGER DEFAULT 0
                )
            """)
            conn.commit()

    def save_history(self, record: Dict[str, Any]) -> str:
        """Save detection record to active database."""
        import uuid
        record_id = record.get("id") or str(uuid.uuid4())
        ts = record.get("timestamp") or datetime.datetime.utcnow().isoformat()
        
        # 1. MongoDB Atlas
        if self.db_type == "mongodb_cloud" and self._mongo_collection is not None:
            doc = {
                "id": record_id,
                "uid": record["uid"],
                "class_label": record.get("class_label", ""),
                "plant_name": record["plant_name"],
                "disease_name": record["disease_name"],
                "confidence": float(record["confidence"]),
                "image_url": record.get("image_url", ""),
                "timestamp": ts,
                "management_tips": record.get("management_tips", []),
                "is_healthy": bool(record.get("is_healthy", False)),
                "created_at": datetime.datetime.utcnow()
            }
            self._mongo_collection.insert_one(doc)
            return record_id

        # 2. Firebase Firestore
        if self.db_type == "firestore_cloud" and self._firestore_client is not None:
            from firebase_admin import firestore
            doc_ref = self._firestore_client.collection("history").document(record_id)
            doc_ref.set({
                "uid": record["uid"],
                "class_label": record.get("class_label", ""),
                "plant_name": record["plant_name"],
                "disease_name": record["disease_name"],
                "confidence": float(record["confidence"]),
                "image_url": record.get("image_url", ""),
                "timestamp": ts,
                "management_tips": record.get("management_tips", []),
                "is_healthy": bool(record.get("is_healthy", False)),
                "created_at": firestore.SERVER_TIMESTAMP
            })
            return record_id

        # 3. SQLite Local
        import json
        with sqlite3.connect(SQLITE_DB_PATH) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO history (id, uid, class_label, plant_name, disease_name, confidence, image_url, timestamp, management_tips, is_healthy)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                record_id,
                record["uid"],
                record.get("class_label", ""),
                record["plant_name"],
                record["disease_name"],
                float(record["confidence"]),
                record.get("image_url", ""),
                ts,
                json.dumps(record.get("management_tips", [])),
                1 if record.get("is_healthy", False) else 0
            ))
            conn.commit()
        return record_id

    def get_history(self, uid: str) -> List[Dict[str, Any]]:
        """Fetch all detection records for a user."""
        # 1. MongoDB Atlas
        if self.db_type == "mongodb_cloud" and self._mongo_collection is not None:
            cursor = self._mongo_collection.find({"uid": uid}).sort("timestamp", -1)
            results = []
            for doc in cursor:
                doc.pop("_id", None)
                if "created_at" in doc:
                    doc["created_at"] = doc["created_at"].isoformat()
                results.append(doc)
            return results

        # 2. Firebase Firestore
        if self.db_type == "firestore_cloud" and self._firestore_client is not None:
            from firebase_admin import firestore
            docs = (
                self._firestore_client.collection("history")
                .where("uid", "==", uid)
                .order_by("timestamp", direction=firestore.Query.DESCENDING)
                .stream()
            )
            results = []
            for doc in docs:
                data = doc.to_dict()
                data["id"] = doc.id
                if "created_at" in data:
                    del data["created_at"]
                results.append(data)
            return results

        # 3. SQLite Local
        import json
        with sqlite3.connect(SQLITE_DB_PATH) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("""
                SELECT * FROM history WHERE uid = ? ORDER BY timestamp DESC
            """, (uid,))
            rows = cursor.fetchall()
            results = []
            for row in rows:
                item = dict(row)
                try:
                    item["management_tips"] = json.loads(item.get("management_tips") or "[]")
                except Exception:
                    item["management_tips"] = []
                item["is_healthy"] = bool(item.get("is_healthy", 0))
                results.append(item)
            return results

    def get_status(self) -> Dict[str, Any]:
        """Return diagnostic status of active database."""
        return {
            "active_database": self.db_type,
            "is_cloud": self.db_type in ["mongodb_cloud", "firestore_cloud"],
            "storage_target": (
                "MongoDB Atlas Cloud" if self.db_type == "mongodb_cloud" else
                "Google Firebase Firestore Cloud" if self.db_type == "firestore_cloud" else
                f"SQLite Persistent DB ({SQLITE_DB_PATH})"
            )
        }

db_manager = DatabaseManager()
