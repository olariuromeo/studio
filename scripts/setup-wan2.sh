#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: studio/scripts/setup-wan2.sh
# Description: Local Environment Configuration for Coozila! Studio v4.0.
# ----------------------------------------------------------------------------------#
set -e

# 1. Recalculăm căile în caz că variabilele globale nu au fost exportate
if [ -z "$COMFY_DIR" ]; then
    COMFY_DIR="$(pwd)/apps/ComfyUI"
fi

MODELS_DIR="$COMFY_DIR/models"
INPUT_DIR="$COMFY_DIR/input"
WRAPPER_DIR="$COMFY_DIR/custom_nodes/ComfyUI-WanVideoWrapper"
VENV_PATH="$COMFY_DIR/venv"

echo "🚀 [WAN 2.2] Initializing from: $COMFY_DIR"

# 2. Clonare Wrapper
if [ ! -d "$WRAPPER_DIR" ]; then
    echo "📦 Cloning WanVideoWrapper..."
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git "$WRAPPER_DIR"
fi

# 3. Activare VENV, Requirements & MODULE LIPSA
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    cd "$WRAPPER_DIR"
    
    echo "📥 Installing Wrapper requirements..."
    pip install -r requirements.txt --no-cache-dir
    
    echo "📥 Installing missing modules (ONNX for FantasyPortrait & Matrix-NIO for Manager)..."
    pip install onnx matrix-nio --no-cache-dir
else
    echo "❌ [ERROR] VENV not found at $VENV_PATH. Check setup-comfy.sh"
    exit 1
fi

# 4. Creăm toate folderele necesare în avans
mkdir -p "$MODELS_DIR/diffusion_models"
mkdir -p "$MODELS_DIR/vae"
mkdir -p "$MODELS_DIR/text_encoders"
mkdir -p "$MODELS_DIR/audio_encoders"
mkdir -p "$MODELS_DIR/loras"
mkdir -p "$INPUT_DIR"

# 5. Descărcare Modele Principale (FP8 Scaled pentru RTX 3080)
echo "📥 [MODELS] Downloading AI Weights & Encoders..."

# Main Model (Transformer)
if [ ! -f "$MODELS_DIR/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors" ]; then
    echo "   -> Downloading UNET/Transformer (14B FP8)..."
    wget -q --show-progress "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/wan2.2_s2v_14B_fp8_scaled.safetensors" -O "$MODELS_DIR/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors"
fi

# VAE
if [ ! -f "$MODELS_DIR/vae/wan_2.1_vae.safetensors" ]; then
    echo "   -> Downloading VAE..."
    wget -q --show-progress "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wan_2.1_vae.safetensors" -O "$MODELS_DIR/vae/wan_2.1_vae.safetensors"
fi

# Text Encoders (T5)
if [ ! -f "$MODELS_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" ]; then
    echo "   -> Downloading CLIP/T5 Encoder..."
    wget -q --show-progress "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors" -O "$MODELS_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
fi

# Audio Encoder (Pus in audio_encoders)
if [ ! -f "$MODELS_DIR/audio_encoders/wav2vec2_large_english_fp16.safetensors" ]; then
    echo "   -> Downloading Audio Encoder (Wav2Vec2)..."
    wget -q --show-progress "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wav2vec2_large_english_fp16.safetensors" -O "$MODELS_DIR/audio_encoders/wav2vec2_large_english_fp16.safetensors"
fi

# LoRA (Turbo 4-Steps)
if [ ! -f "$MODELS_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" ]; then
    echo "   -> Downloading Turbo LoRA..."
    wget -q --show-progress "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" -O "$MODELS_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
fi

# 6. Fișiere de INPUT (Placeholder-uri pentru workflow)
echo "📥 [MEDIA] Providing dummy input files for the workflow..."

if [ ! -f "$INPUT_DIR/video_wan2_2_14B_s2v_reference_image.jpg" ]; then
    echo "   -> Downloading placeholder JPG..."
    wget -q --show-progress "https://picsum.photos/512/512.jpg" -O "$INPUT_DIR/video_wan2_2_14B_s2v_reference_image.jpg"
fi

if [ ! -f "$INPUT_DIR/video_wan2_2_14B_s2v_input_audio.MP3" ]; then
    echo "   -> Downloading placeholder MP3..."
    wget -q --show-progress "https://upload.wikimedia.org/wikipedia/commons/b/be/Hidden_Tribe_-_The_Hunted.mp3" -O "$INPUT_DIR/video_wan2_2_14B_s2v_input_audio.MP3"
fi

deactivate
echo "✅ [SUCCESS] Wan 2.2 Stack is 100% complete and warnings-free!"