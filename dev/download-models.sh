#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/download-models.sh
# Description: Professional Physical Provisioning via HF-CLI & Direct Downloads
# ----------------------------------------------------------------------------------#

set -e

# 1. PATHS
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUDIO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODELS_DIR="$STUDIO_ROOT/apps/ComfyUI/models"
CUSTOM_NODES_DIR="$STUDIO_ROOT/apps/ComfyUI/custom_nodes"
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

# 3. CORE SYNC FUNCTIONS
sync_model() {
    local repo="$1"
    local remote_path="$2"
    local local_target_dir="$3"
    local filename=$(basename "$remote_path")
    local final_dest="$local_target_dir/$filename"

    echo "[SYNC] Checking $filename..."
    mkdir -p "$local_target_dir"

    "$HF_BINARY" download "$repo" "$remote_path" --local-dir "$local_target_dir"

    if [ -f "$final_dest" ]; then
        if [ -L "$final_dest" ]; then
            echo "[FIX] Converting symlink to physical file..."
            cp --remove-destination "$(readlink -f "$final_dest")" "$final_dest"
        fi
        chmod 664 "$final_dest"
        echo "[OK] $filename verified."
    else
        echo "[ERROR] Sync failed for $filename"
        exit 1
    fi
}

download_direct() {
    local url="$1"
    local local_target_dir="$2"
    local filename="$3"
    local final_dest="$local_target_dir/$filename"

    if [ -f "$final_dest" ]; then
        echo "[SKIP] $filename already exists."
        return 0
    fi

    echo "[DOWNLOAD] $filename from external source..."
    mkdir -p "$local_target_dir"
    curl -L "$url" -o "$final_dest"
    chmod 664 "$final_dest"
    echo "[OK] $filename downloaded."
}

# --- 4. EXECUTION ---

# --- [ WAN 2.1 I2V 720P – 54% Faster Video Generation with SageAttention + TeaCache! ] ---
# https://civitai.com/articles/12250/wan-21-i2v-720p-54percent-faster-video-generation-with-sageattention-teacache

# 1. Wan 2.1 VAE
sync_model "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/vae/wan_2.1_vae.safetensors" "$MODELS_DIR/vae"

# 2. Wan 2.1 Text Encoder
sync_model "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$MODELS_DIR/text_encoders"

# 3. Wan 2.1 Diffusion Model BF16
sync_model "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/diffusion_models/wan2.1_t2v_14B_bf16.safetensors" "$MODELS_DIR/diffusion_models"

# 4. FILM Frame Interpolation (GitHub Direct)
download_direct "https://github.com/dajes/frame-interpolation-pytorch/releases/download/v1.0.2/film_net_fp32.pt" \
                "$CUSTOM_NODES_DIR/ComfyUI-Frame-Interpolation/ckpts/film" "film_net_fp32.pt"

# 5. Omni-SR Upscale Model
sync_model "Acly/Omni-SR" "OmniSR_X2_DIV2K.safetensors" "$MODELS_DIR/upscale_models"


# --- [ WAN 2.2 STANDARD ] ---

# 6. Wan 2.2 Audio Encoder
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/audio_encoders/wav2vec2_large_english_fp16.safetensors" "$MODELS_DIR/audio_encoders"

# 7. Wan 2.2 Diffusion Model FP8
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors" "$MODELS_DIR/diffusion_models"

# 8. Wan 2.2 LoRA (High Noise)
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" "$MODELS_DIR/loras"

# 9. Wan 2.2 LoRA (Low Noise)
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors" "$MODELS_DIR/loras"

# 10. CLIP L (Flux/Wan standard)
sync_model "comfyanonymous/flux_text_encoders" "clip_l.safetensors" "$MODELS_DIR/clip"

# 11. Wan 2.2 Diffusion Model BF16
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_s2v_14B_bf16.safetensors" "$MODELS_DIR/diffusion_models"

echo "Sync Complete. Total 11 assets verified."