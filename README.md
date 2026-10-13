# 🌿 PlantCare AI — AI-Based Plant Disease Detection System

An AI-powered mobile application to detect plant diseases from leaf images using the PlantNet disease identification API.

## Project Structure

```
├── backend/          Python FastAPI + TensorFlow AI Model
├── flutter_app/      Flutter Mobile Application
└── SETUP.md          Complete setup instructions
```

## Quick Start

👉 See [SETUP.md](./SETUP.md) for complete step-by-step instructions.

## Deploy the Web App

The Flutter web app can be published with GitHub Pages using the workflow in `.github/workflows/deploy-pages.yml`. In the repository settings, enable **Pages** with **GitHub Actions** as the source and add these repository variables:

- `API_BASE_URL`: the public FastAPI URL ending in `/api` (for example, `https://your-api.example.com/api`). The API must be hosted separately; GitHub Pages only serves static files. The web app can publish without this variable, but scanning and history need the backend.
- `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, and `FIREBASE_PROJECT_ID`: values from the Firebase web app configuration, required for Firebase authentication and storage. Without these, the app uses demo authentication.
- `FIREBASE_AUTH_DOMAIN` and `FIREBASE_STORAGE_BUCKET`: optional Firebase web app values.

Push to `main` or `master` after configuring the variables. The workflow publishes the app to Pages; its URL appears in the workflow deployment summary.

### Deploy the Disease API

The repository includes a Render Blueprint for the lightweight PlantNet proxy. In Render, create a new Blueprint from this repository and enter a newly generated PlantNet API key when prompted for `PLANTNET_API_KEY`. Do not put the key in Flutter or commit it to GitHub.

After Render gives the service a public URL, set the GitHub Actions repository variable `API_BASE_URL` to that URL plus `/api` (for example, `https://plantcare-api.onrender.com/api`), then rerun the Pages workflow. PlantNet supports a limited set of diseases and plant species, accepts JPEG/PNG images, and spends one identification credit per request. Render's free service may sleep when idle.

## Tech Stack
- **Mobile App**: Flutter + Dart
- **Backend**: Python FastAPI
- **Disease Detection**: PlantNet diseases identification API
- **Database**: Firebase Firestore + Firebase Auth + Firebase Storage
- **Dataset**: PlantVillage (38 disease classes, 54,000+ images)

## Features
- 📸 Capture or upload plant leaf images
- 🤖 AI-powered disease classification (38 classes, 14 crops)
- 📊 Confidence percentage with color coding
- 📋 Disease information and management suggestions
- 🕐 Detection history with timestamps
- 👤 User authentication and profile
