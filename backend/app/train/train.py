"""
Plant Disease Detection Model Training Script
=============================================
Uses MobileNetV2 transfer learning on the PlantVillage dataset.

Setup:
    1. Download the PlantVillage dataset from:
       https://www.kaggle.com/datasets/abdallahalidev/plantvillage-dataset
    2. Extract to a folder, e.g. datasets/plantvillage/
       Expected structure:
         datasets/plantvillage/
           Apple___Apple_scab/  (folder of images)
           Apple___Black_rot/
           ...
    3. Run this script:
       python app/train/train.py --dataset_path datasets/plantvillage
    4. The trained model will be saved to: app/model/plant_model.h5

Requirements: tensorflow, pillow, numpy
"""

import os
import argparse
import json
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import GlobalAveragePooling2D, Dense, Dropout
from tensorflow.keras.models import Model
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau

def train_model(dataset_path):
    print(f"Starting training process using dataset at: {dataset_path}")
    
    # Model parameters
    IMG_SIZE = (224, 224)
    BATCH_SIZE = 32
    EPOCHS_PHASE_1 = 10
    EPOCHS_PHASE_2 = 15
    NUM_CLASSES = 38
    
    # 1. Prepare Data Generators
    print("Preparing data generators...")
    datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        validation_split=0.2
    )

    train_generator = datagen.flow_from_directory(
        dataset_path,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='training'
    )

    val_generator = datagen.flow_from_directory(
        dataset_path,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='validation'
    )

    # Save class indices
    class_indices = train_generator.class_indices
    # Reverse mapping: index to label
    class_labels = {v: k for k, v in class_indices.items()}
    
    labels_path = os.path.join(os.path.dirname(__file__), 'class_labels.json')
    with open(labels_path, 'w') as f:
        json.dump(class_labels, f, indent=2)
    print(f"Saved class labels to {labels_path}")

    # 2. Build Model
    print("Building model based on MobileNetV2...")
    base_model = MobileNetV2(
        weights='imagenet',
        include_top=False,
        input_shape=IMG_SIZE + (3,)
    )

    # Freeze base model for Phase 1
    base_model.trainable = False

    # Add custom top layers
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dense(256, activation='relu')(x)
    x = Dropout(0.3)(x)
    predictions = Dense(NUM_CLASSES, activation='softmax')(x)

    model = Model(inputs=base_model.input, outputs=predictions)

    # 3. Phase 1: Train Top Layers
    print("Phase 1: Training top layers (base model frozen)...")
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    model_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'model')
    os.makedirs(model_dir, exist_ok=True)
    model_save_path = os.path.join(model_dir, 'plant_model.h5')

    callbacks = [
        ModelCheckpoint(model_save_path, monitor='val_accuracy', save_best_only=True, verbose=1),
        EarlyStopping(monitor='val_loss', patience=3, verbose=1, restore_best_weights=True),
        ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=2, verbose=1)
    ]

    history_1 = model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=EPOCHS_PHASE_1,
        callbacks=callbacks
    )

    # 4. Phase 2: Fine-Tuning
    print("Phase 2: Fine-tuning last 30 layers of base model...")
    base_model.trainable = True
    
    # Freeze all layers except the last 30
    for layer in base_model.layers[:-30]:
        layer.trainable = False

    # Recompile with a lower learning rate
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    history_2 = model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=EPOCHS_PHASE_2,
        callbacks=callbacks
    )
    
    print(f"Training complete. Best model saved to: {model_save_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train Plant Disease Detection Model")
    parser.add_argument("--dataset_path", type=str, required=True, help="Path to the plant village dataset directory")
    args = parser.parse_args()
    
    train_model(args.dataset_path)
