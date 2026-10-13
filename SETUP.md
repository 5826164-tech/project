# 🌿 PlantCare AI — Complete Setup Guide

Follow these steps **in order** to get the app fully running.

---

## Prerequisites

Install these tools first:

| Tool | Download |
|------|----------|
| Python 3.10+ | https://www.python.org/downloads/ |
| Flutter SDK 3.22+ | https://docs.flutter.dev/get-started/install/windows |
| Android Studio | https://developer.android.com/studio |
| VS Code | https://code.visualstudio.com/ |
| Git | https://git-scm.com/ |
| Kaggle Account (free) | https://www.kaggle.com/ |

---

## Cloud Database Options (MongoDB Atlas or Firebase Firestore)

PlantCare AI now comes with **Universal Cloud Database Support**:
- **Option 1: MongoDB Atlas (Cloud NoSQL)** — Free & instant: just paste your connection string in `backend/.env`.
- **Option 2: Google Firebase Firestore (Cloud NoSQL)** — Connect via `firebase-credentials.json`.
- **Option 3: Persistent Local Database (Zero-Config)** — Automatically active out-of-the-box so the app is always fully functional even without cloud credentials!

---

## STEP 1A — Connect to MongoDB Atlas (Easiest Cloud Setup)

1. Create a free account at [https://www.mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)
2. Create a free Shared Cluster (M0 Free).
3. Under **Database Access**, create a user with a password.
4. Under **Network Access**, click **Add IP Address** -> `0.0.0.0/0` (Allow Access from Anywhere).
5. Click **Connect** -> **Drivers** (Python) -> copy your connection URI.
6. Open [backend/.env](file:///c:/Users/vedan/OneDrive/Desktop/om%20bhaiya/backend/.env) and set:
   ```env
   MONGODB_URI=mongodb+srv://<username>:<password>@cluster0.yourid.mongodb.net/?retryWrites=true&w=majority
   ```

---

## STEP 1B — Set Up Firebase Project (Alternative Cloud Option)

1. Go to https://console.firebase.google.com/
2. Click **Add project** → Name it `PlantCareAI` → Continue
3. Disable Google Analytics (optional) → **Create project**

### Enable Firebase Auth
4. Go to **Authentication** → **Get started**
5. Click **Email/Password** → Enable → **Save**

### Enable Firestore
6. Go to **Firestore Database** → **Create database**
7. Choose **Start in test mode** → Select your region → **Enable**

### Enable Firebase Storage
8. Go to **Storage** → **Get started**
9. Choose **Start in test mode** → **Done**

### Get Firebase Admin Credentials (for Backend)
10. Go to **Project Settings** (gear icon) → **Service accounts**
11. Click **Generate new private key** → **Generate key**
12. Save the downloaded JSON file as:
    ```
    backend/firebase-credentials.json
    ```

### Get Firebase Config (for Flutter)
13. In Project Settings → **General** → scroll to **Your apps**
14. Click the **Android** icon to add an Android app
15. **Android package name**: `com.plantcareai.app`
16. Click **Register app**
17. Download `google-services.json`
18. Place it at:
    ```
    flutter_app/android/app/google-services.json
    ```

---

## STEP 2 — Set Up Backend

```bash
cd "c:\Users\vedan\OneDrive\Desktop\om bhaiya\backend"
python -m venv venv
venv\Scripts\activate
pip install -r requirements-api.txt
copy .env.example .env
```

Set `PLANTNET_API_KEY` in `backend/.env` for local use. For a cloud deployment, add it as a secret environment variable on the backend host. Never put this key in the Flutter app or commit it to GitHub.

---

## STEP 3 — Optional Legacy Model Training

Plant disease predictions now use the PlantNet API. Training the local TensorFlow model is not required for the current API path.

> **IMPORTANT**: Requires a Kaggle account. Training takes 30-60 min (GPU) or 2-4 hours (CPU).

1. Go to: https://www.kaggle.com/datasets/abdallahalidev/plantvillage-dataset
2. Download and extract the dataset
3. Place folders inside:
   ```
   backend/datasets/plantvillage/
     Apple___Apple_scab/
     Apple___Black_rot/
     ... (38 folders total)
   ```
4. Train:
   ```bash
   python app/train/train.py --dataset_path datasets/plantvillage
   ```
   Model saved to: `app/model/plant_model.h5`

> The locally trained model is retained for experimentation but is not used by the PlantNet prediction route.

---

## STEP 4 — Run the Backend

```bash
# From inside backend/ with venv activated
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

- API health check: http://localhost:8000
- Interactive docs: http://localhost:8000/docs

---

## STEP 5 — Set Up and Run Flutter App

```bash
cd "c:\Users\vedan\OneDrive\Desktop\om bhaiya\flutter_app"

# Create asset directories
mkdir assets\images
mkdir assets\icons

# Install dependencies
flutter pub get

# Run on emulator
flutter run
```

> **IMPORTANT**: The app uses `http://10.0.2.2:8000` (Android emulator localhost).
> For physical device on same WiFi, change `baseUrl` in `lib/services/api_service.dart` to your PC's local IP.

---

## STEP 6 — Test the Full Flow

1. Register a new account
2. Login
3. Tap **Scan** → select a leaf image
4. Wait for AI analysis
5. View results: disease name, confidence %, info, management tips
6. Save to History
7. Check History tab

---

## Folder Structure

```
om bhaiya/
├── backend/                    ← Python FastAPI + AI Model
│   ├── app/
│   │   ├── main.py             ← FastAPI entry point
│   │   ├── firebase_config.py
│   │   ├── disease_info.json   ← 38 disease class info
│   │   ├── routers/
│   │   │   ├── predict.py      ← POST /api/predict
│   │   │   ├── disease.py      ← GET /api/diseases
│   │   │   └── history.py      ← GET/POST /api/history
│   │   ├── model/
│   │   │   ├── model_loader.py
│   │   │   └── plant_model.h5  ← Generated after training
│   │   └── train/
│   │       ├── train.py        ← Run this to train the model
│   │       └── class_labels.json
│   ├── firebase-credentials.json  ← Download from Firebase Console
│   ├── requirements.txt
│   └── .env
│
└── flutter_app/                ← Flutter Mobile App
    ├── lib/
    │   ├── main.dart
    │   ├── screens/            ← 8 screens
    │   ├── services/           ← API, Auth, Storage
    │   ├── providers/          ← State management
    │   ├── models/             ← Data models
    │   └── widgets/            ← Reusable components
    ├── android/app/
    │   └── google-services.json  ← Download from Firebase Console
    └── pubspec.yaml
```

---

## Common Issues

| Problem | Solution |
|---------|----------|
| Firebase error on startup | Ensure `google-services.json` is at `android/app/google-services.json` |
| Backend 500 on predict | Model not trained yet — mock mode is active |
| App cannot reach backend | Use `10.0.2.2:8000` for emulator; PC LAN IP for physical device |
| Firebase history not saving | Check `firebase-credentials.json` exists in `backend/` |
| Training out of memory | Reduce `batch_size` in `train.py` from 32 to 16 |
| `pip install tensorflow` fails | Use Python 3.10 or 3.11 (not 3.12+) |

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Mobile App | Flutter 3.22 + Dart |
| State Management | Provider 6 |
| AI Model | MobileNetV2 (Transfer Learning) |
| Training Framework | TensorFlow 2.16 / Keras |
| Dataset | PlantVillage (38 classes, 54K+ images) |
| Backend API | Python FastAPI + Uvicorn |
| Authentication | Firebase Auth (Email/Password) |
| Database | Firestore |
| Image Storage | Firebase Storage |
