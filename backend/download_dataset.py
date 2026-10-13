"""
download_dataset.py
====================
Downloads the PlantVillage dataset from Kaggle using kagglehub.

Usage:
    python download_dataset.py

Requirements:
    pip install kagglehub

Authentication:
    First time: kagglehub will prompt you for your Kaggle username and API key.
    - Go to https://www.kaggle.com/settings -> Account -> API -> "Create New Token"
    - This downloads kaggle.json to your Downloads folder
    - kagglehub will pick it up automatically, OR you can set env vars:
        set KAGGLE_USERNAME=your_username
        set KAGGLE_KEY=your_api_key
"""

import kagglehub
import os
import shutil

DATASET_ID = "abdallahalidev/plantvillage-dataset"
TARGET_DIR = os.path.join(os.path.dirname(__file__), "datasets", "plantvillage")

def download_and_organize():
    print("=" * 60)
    print("  PlantVillage Dataset Downloader")
    print("=" * 60)
    print(f"\nDataset: {DATASET_ID}")
    print("Downloading from Kaggle (this may take a few minutes)...\n")

    # Download via kagglehub (caches in ~/.cache/kagglehub)
    path = kagglehub.dataset_download(DATASET_ID)
    print(f"\nDownloaded to cache: {path}")

    # Find the folder that contains the 38 class subfolders
    # The dataset structure may have an extra nesting level
    class_source = path
    for root, dirs, files in os.walk(path):
        # Look for the folder that has 38+ subdirectories (the disease class folders)
        if len(dirs) >= 30:
            class_source = root
            print(f"Found class folders at: {class_source}")
            break

    # Copy/link to our datasets/ folder
    if os.path.exists(TARGET_DIR):
        print(f"\nTarget directory already exists: {TARGET_DIR}")
        print("Skipping copy. Delete it first if you want to re-copy.")
    else:
        print(f"\nCopying dataset to: {TARGET_DIR}")
        print("(This may take a few minutes for 54,000+ images...)")
        shutil.copytree(class_source, TARGET_DIR)
        print("Copy complete!")

    # Count classes and images
    if os.path.exists(TARGET_DIR):
        classes = [d for d in os.listdir(TARGET_DIR)
                   if os.path.isdir(os.path.join(TARGET_DIR, d))]
        total_images = sum(
            len(files)
            for _, _, files in os.walk(TARGET_DIR)
        )
        print(f"\n{'=' * 60}")
        print(f"  Dataset ready!")
        print(f"  Classes found : {len(classes)}")
        print(f"  Total images  : {total_images:,}")
        print(f"  Location      : {TARGET_DIR}")
        print(f"{'=' * 60}")
        print(f"\nNow run the training script:")
        print(f"  python app/train/train.py --dataset_path datasets/plantvillage")

if __name__ == "__main__":
    download_and_organize()
