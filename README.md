# 🌿 PlantCare AI — AI-Based Plant Disease Detection System

PlantCare AI includes a mobile app and a browser-based leaf checker. The GitHub Pages checker runs a bundled TFLite model locally and does not upload images or call a disease API.

## Project Structure

```
├── backend/          Python FastAPI + TensorFlow AI Model
├── flutter_app/      Flutter Mobile Application
└── SETUP.md          Complete setup instructions
```

## Quick Start

👉 See [SETUP.md](./SETUP.md) for complete step-by-step instructions.

## Deploy the Web App

GitHub Pages deploys the static detector from `flutter_app/web` whenever `main` or `master` is updated. The browser model recognizes 17 trained classes across apple, corn, grape, pepper, potato, and tomato; other plants and unrelated images may be uncertain or misclassified.

## Tech Stack
- **Mobile App**: Flutter + Dart
- **Backend**: Python FastAPI
- **Web Disease Detection**: Local TFLite model; no prediction API
- **Database**: Firebase Firestore + Firebase Auth + Firebase Storage
- **Dataset**: PlantVillage (38 disease classes, 54,000+ images)

## Features
- 📸 Capture or upload plant leaf images
- 🤖 AI-powered disease classification (38 classes, 14 crops)
- 📊 Confidence percentage with color coding
- 📋 Disease information and management suggestions
- 🕐 Detection history with timestamps
- 👤 User authentication and profile
