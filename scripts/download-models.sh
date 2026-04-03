#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/download-models.sh
# Description: Smart Data Fetching with HF API Auth and Existence Checks.
# ----------------------------------------------------------------------------------#
set -e

# 1. Path Alignment & Environment Loading
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMFY_DIR="$STUDIO_ROOT/apps/ComfyUI"
MODELS_DIR="$COMFY_DIR/models"
INPUT_DIR="$COMFY_DIR/input"

# Load HF_TOKEN from .env if it exists
if [ -f "$STUDIO_ROOT/.env" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)
fi

echo "📥 [MODELS] Starting AI Weights verification & sync..."

# Smart Download Function with Header Support
safe_download() {
    local url=$1
    local dest=$2
    local filename=$(basename "$dest")
    local dir=$(dirname "$dest")
    
    if [ -f "$dest" ]; then
        echo "   ✅ [EXISTS] $filename is already present. Skipping."
    else
        echo "   📡 [MISSING] $filename not found. Downloading..."
        mkdir -p "$dir"
        
        # Prepare Auth Header if token is available
        local auth_header=""
        if [ -n "$HF_TOKEN" ] && [[ "$url" == *"huggingface.co"* ]]; then
            auth_header="--header=\"Authorization: Bearer $HF_TOKEN\""
            echo "      -> Using Hugging Face API Token for authentication."
        fi

        # Execute wget with optional header
        eval wget -q --show-progress "$auth_header" "$url" -O "$dest"
    fi
}

# --- 2. Wan 2.2 Core Weights (Hugging Face) ---

safe_download "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/wan2.2_s2v_14B_fp8_scaled.safetensors" \
              "$MODELS_DIR/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors"

safe_download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wan_2.1_vae.safetensors" \
              "$MODELS_DIR/vae/wan_2.1_vae.safetensors"

safe_download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
              "$MODELS_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

safe_download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wav2vec2_large_english_fp16.safetensors" \
              "$MODELS_DIR/audio_encoders/wav2vec2_large_english_fp16.safetensors"

safe_download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" \
              "$MODELS_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"

# --- 3. Workflow Validation Assets (Public) ---

echo "🖼️  [MEDIA] Syncing dummy assets..."
safe_download "https://picsum.photos/512/512.jpg" "$INPUT_DIR/video_wan2_2_14B_s2v_reference_image.jpg"
safe_download "https://upload.wikimedia.org/wikipedia/commons/b/be/Hidden_Tribe_-_The_Hunted.mp3" "$INPUT_DIR/video_wan2_2_14B_s2v_input_audio.MP3"

echo "✨ [COMPLETE] Verification finished. Systems ready."