#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/download-models.sh
# Description: Official Provisioning Engine using Hugging Face Hub API
# ----------------------------------------------------------------------------------#

set -e

# 1. AUTO-PATH DETECTION
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUDIO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODELS_DIR="$STUDIO_ROOT/apps/ComfyUI/models"
PYTHON_BIN="$STUDIO_ROOT/apps/ComfyUI/venv/bin/python"
DOT_ENV="$STUDIO_ROOT/.env.dev"

echo -e "\n📂 \033[1;34mProject Root:\033[0m $STUDIO_ROOT"

# 2. BOOTSTRAP: ENSURE HF-HUB IS INSTALLED
echo -e "⚙️ \033[34mChecking HF Downloader Requirements...\033[0m"
if ! $PYTHON_BIN -m pip show huggingface_hub &> /dev/null; then
    echo -e "📥 Installing huggingface_hub in virtual environment..."
    $PYTHON_BIN -m pip install huggingface_hub
fi

# 3. LOAD ENVIRONMENT
HF_TOKEN=""
if [ -f "$DOT_ENV" ]; then
    HF_TOKEN=$(grep '^HF_TOKEN=' "$DOT_ENV" | cut -d'=' -f2- | tr -d '"' | tr -d "'" || true)
    if [ -n "$HF_TOKEN" ]; then
        echo -e "🔑 \033[32mHF_TOKEN loaded from .env.dev\033[0m"
    fi
fi

# 4. SMART SYNC ENGINE (Hugging Face Hub Edition)
smart_sync_hf() {
    local repo="$1"
    local filename="$2"
    local local_dir="$3"
    local min_size="$4"
    local dest="$local_dir/$filename"

    mkdir -p "$local_dir"

    # Validation: Check if file exists and exceeds the LFS pointer size
    if [ -f "$dest" ]; then
        local actual_size=$(stat -c%s "$dest")
        if [ "$actual_size" -ge "$min_size" ]; then
            echo -e "✅ \033[32m[SKIP] $filename is valid ($((actual_size / 1024 / 1024)) MB).\033[0m"
            return 0
        else
            echo -e "🧹 \033[33m$filename is a pointer or corrupted ($actual_size bytes). Replacing...\033[0m"
            rm -f "$dest"
        fi
    fi

    echo -e "📥 \033[34m[HF-DOWNLOAD] $filename from $repo...\033[0m"
    
    # Use official HF Python API to force real binary download (resolves LFS)
    $PYTHON_BIN -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='$repo', filename='$filename', local_dir='$local_dir', local_dir_use_symlinks=False, token='$HF_TOKEN' if '$HF_TOKEN' else None)"

    # Final Integrity Check
    if [ ! -s "$dest" ]; then
        echo -e "❌ \033[31m[FAIL] $filename download failed.\033[0m"
        exit 1
    fi
    echo -e "✔️ \033[32m[OK] $filename verified.\033[0m"
}

# --- 5. ASSET LIST (Verified Byte-Exact Thresholds) ---

# 1. Text Encoder (UMT5)
smart_sync_hf "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$MODELS_DIR/text_encoders" 6735906897

# 2. VAE
smart_sync_hf "wose/comfyui-models" "wan_2.1_vae.safetensors" "$MODELS_DIR/vae" 253815318

# 3. CLIP (Flux/Wan compatible)
smart_sync_hf "comfyanonymous/flux_text_encoders" "clip_l.safetensors" "$MODELS_DIR/clip" 246513732

# 4. Audio Encoder (Specific for Wan 2.2)
smart_sync_hf "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "wav2vec2_large_english_fp16.safetensors" "$MODELS_DIR/audio_encoders" 631114770

# 5. Diffusion Model (Wan 2.2 - 14B S2V)
smart_sync_hf "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "wan2.2_s2v_14B_fp8_scaled.safetensors" "$MODELS_DIR/diffusion_models" 16653330620

# 6. LoRA (Turbo 4-Step)
smart_sync_hf "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" "$MODELS_DIR/loras" 153253116

echo -e "\n🚀 \033[1;32m[COMPLETE] Coozila! Studio is armed and ready for action.\033[0m\n"