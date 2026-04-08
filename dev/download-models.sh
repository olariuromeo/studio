#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/download-models.sh
# Description: Container-native Provisioning for ComfyUI Engine (ComfyUI v1.0+)
# ----------------------------------------------------------------------------------#

# Halt execution on critical errors
set -e

# 1. AUTO-PATH DETECTION
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUDIO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODELS_DIR="$STUDIO_ROOT/apps/ComfyUI/models"
DOT_ENV="$STUDIO_ROOT/.env.dev"

echo -e "\n📂 \033[1;34mProject Root:\033[0m $STUDIO_ROOT"
echo -e "📂 \033[1;34mModels Path:\033[0m $MODELS_DIR"

# 2. LOAD ENVIRONMENT (SAFE GREP)
HF_TOKEN=""
if [ -f "$DOT_ENV" ]; then
    # Using '|| true' to prevent script failure (due to 'set -e') if the token is missing
    HF_TOKEN=$(grep '^HF_TOKEN=' "$DOT_ENV" | cut -d'=' -f2- | tr -d '"' | tr -d "'" || true)
    if [ -n "$HF_TOKEN" ]; then
        echo -e "🔑 \033[32mHF_TOKEN loaded from .env.dev\033[0m"
    else
        echo -e "⚠️ \033[33mHF_TOKEN not found in .env.dev. Downloading public models only.\033[0m"
    fi
fi

# 3. SMART SYNC ENGINE
smart_sync() {
    local url="$1"
    local dest="$2"
    local min_size="${3:-1024}" # Default 1KB (protection against HTML 404/403 errors)
    local filename=$(basename "$dest")
    local work_dir=$(dirname "$dest")

    # Create folder structure (Safety first)
    mkdir -p "$work_dir"

    # --- VALIDATION GATE ---
    if [ -f "$dest" ]; then
        local actual_size=$(stat -c%s "$dest")
        if [ "$actual_size" -lt "$min_size" ]; then
            echo -e "🧹 \033[33m$filename is corrupted/empty ($actual_size bytes). Deleting...\033[0m"
            rm -f "$dest"
        else
            echo -e "✅ \033[32m[SKIP] $filename is valid.\033[0m"
            return 0
        fi
    fi

    echo -e "📥 \033[34m[DOWNLOAD] $filename...\033[0m"

    # --- EXECUTION GATE (Aria2c vs Wget) ---
    if command -v aria2c &> /dev/null; then
        if [ -n "$HF_TOKEN" ]; then
            aria2c -x 16 -s 16 -k 1M --continue=true --max-tries=5 --retry-wait=5 \
                --header="Authorization: Bearer $HF_TOKEN" \
                "$url" -d "$work_dir" -o "$filename"
        else
            aria2c -x 16 -s 16 -k 1M --continue=true --max-tries=5 --retry-wait=5 \
                "$url" -d "$work_dir" -o "$filename"
        fi
    else
        echo -e "⚠️ \033[33mAria2c missing, falling back to Wget...\033[0m"
        if [ -n "$HF_TOKEN" ]; then
            wget -c --header="Authorization: Bearer $HF_TOKEN" "$url" -O "$dest"
        else
            wget -c "$url" -O "$dest"
        fi
    fi

    # --- FINAL VERIFICATION ---
    if [ -s "$dest" ]; then
        local check_size=$(stat -c%s "$dest")
        if [ "$check_size" -ge "$min_size" ]; then
            echo -e "✔️ \033[32m[OK] $filename verified.\033[0m"
        else
            echo -e "❌ \033[31m[FAIL] $filename is smaller than minimum size ($check_size < $min_size).\033[0m"
            exit 1
        fi
    else
        echo -e "❌ \033[31m[FAIL] $filename is completely empty or missing.\033[0m"
        exit 1
    fi
}

# --- 4. ASSET LIST (The "Box" Setup) ---

# FIX: Using the stable 2.1 repo for common elements (VAE, Text Encoders, Audio)
BASE_COMFY="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files"

# 1. Text Encoder (UMT5)
smart_sync "$BASE_COMFY/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
           "$MODELS_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# 2. VAE (Wan 2.1/2.2 use the same VAE)
smart_sync "$BASE_COMFY/vae/wan_2.1_vae.safetensors" \
           "$MODELS_DIR/vae/wan_2.1_vae.safetensors"

# 3. CLIP (Universal model pulled from the main ComfyUI repo)
smart_sync "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" \
           "$MODELS_DIR/clip/clip_l.safetensors"

# 4. Audio Encoder (Wav2Vec2)
smart_sync "$BASE_COMFY/audio_encoders/wav2vec2_large_english_fp16.safetensors" \
           "$MODELS_DIR/audio_encoders/wav2vec2_large_english_fp16.safetensors"

# 5. Diffusion Model (Wan 2.2 S2V 14B FP8 from Kijai)
smart_sync "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/wan2.2_s2v_14B_fp8_scaled.safetensors" \
           "$MODELS_DIR/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors"

# 6. LoRA (High Noise for LightX2V)
smart_sync "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" \
           "$MODELS_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"

echo -e "\n🚀 \033[1;32m[COMPLETE] Coozila! Studio is armed and ready.\033[0m\n"