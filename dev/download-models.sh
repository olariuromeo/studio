#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/download-models.sh
# Description: Professional Physical Provisioning via HF-CLI
# ----------------------------------------------------------------------------------#

set -e

# 1. PATHS
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUDIO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODELS_DIR="$STUDIO_ROOT/apps/ComfyUI/models"
DOT_ENV="$STUDIO_ROOT/.env.dev"

export PATH="$HOME/.local/bin:$PATH"
HF_BINARY=$(command -v hf || echo "$HOME/.local/bin/hf")

echo "Coozila! Studio - Physical Sync Engine"

# 2. AUTH
if [ -f "$DOT_ENV" ]; then
    HF_TOKEN=$(grep '^HF_TOKEN=' "$DOT_ENV" | cut -d'=' -f2- | tr -d '"' | tr -d "'" || true)
    if [ -n "$HF_TOKEN" ]; then
        "$HF_BINARY" auth login --token "$HF_TOKEN" > /dev/null 2>&1
    fi
fi

# 3. CORE SYNC FUNCTION
sync_model() {
    local repo="$1"
    local remote_path="$2"
    local local_target_dir="$3"
    local filename=$(basename "$remote_path")
    local final_dest="$local_target_dir/$filename"

    echo "[SYNC] Checking $filename..."
    mkdir -p "$local_target_dir"

    # Descarcă direct în folderul final. hf-cli verifică singur integritatea.
    # Dacă fișierul există și e valid, hf-cli va da skip automat.
    "$HF_BINARY" download "$repo" "$remote_path" --local-dir "$local_target_dir"

    if [ -f "$final_dest" ]; then
        # Ne asigurăm că nu este un symlink (dacă hf-cli a încercat să fie "deștept")
        if [ -L "$final_dest" ]; then
            echo "[FIX] Converting symlink to physical file..."
            cp --remove-destination "$(readlink -f "$final_dest")" "$final_dest"
        fi
        chmod 664 "$final_dest"
        echo "[OK] $filename is verified."
    else
        echo "[ERROR] Download failed for $filename"
        exit 1
    fi
}

# --- 4. EXECUTION ---

# Text Encoder
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$MODELS_DIR/text_encoders"

# VAE
sync_model "wose/comfyui-models" "wan_2.1_vae.safetensors" "$MODELS_DIR/vae"

# CLIP
sync_model "comfyanonymous/flux_text_encoders" "clip_l.safetensors" "$MODELS_DIR/clip"

# Audio Encoder
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/audio_encoders/wav2vec2_large_english_fp16.safetensors" "$MODELS_DIR/audio_encoders"

# Diffusion Models
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors" "$MODELS_DIR/diffusion_models"
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_s2v_14B_bf16.safetensors" "$MODELS_DIR/diffusion_models"

# LoRAs
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" "$MODELS_DIR/loras"
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors" "$MODELS_DIR/loras"

echo "Sync Complete."