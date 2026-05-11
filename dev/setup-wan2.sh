#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/setup-wan2.sh
# Description: Environment-driven Wan 2.2 Wrapper Provisioning (RTX 3080 Optimized)
# ----------------------------------------------------------------------------------#

set -e

# ----------------------------------------------------------------------------------#
# 0. Context & Environment Loading
# ----------------------------------------------------------------------------------#
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$STUDIO_ROOT/.env.dev"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Missing .env.dev"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

WAN_WRAPPER_DIR="$STUDIO_ROOT/$COMFY_DIR/custom_nodes/ComfyUI-WanVideoWrapper"
COMFY_VENV="$STUDIO_ROOT/$COMFY_DIR/venv"

echo "🚀 [WAN 2.2] Syncing Wrapper & Dependencies..."

# ----------------------------------------------------------------------------------#
# 1. SUBMODULE (NO ADD, ONLY SYNC)
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"

if [ ! -f .gitmodules ] || ! grep -q "$WAN_REPO_DIR" .gitmodules; then
    echo "❌ WAN submodule not registered in .gitmodules"
    exit 1
fi

git submodule update --init --recursive "$WAN_REPO_DIR"

# ----------------------------------------------------------------------------------#
# 2. DEPENDENCIES
# ----------------------------------------------------------------------------------#
if [ ! -d "$COMFY_VENV" ]; then
    echo "❌ ComfyUI venv missing"
    exit 1
fi

VENV_PIP="$COMFY_VENV/bin/pip"

$VENV_PIP install --upgrade pip "setuptools<82" wheel --no-cache-dir

if [ -f "$STUDIO_ROOT/$WAN_REPO_DIR/requirements.txt" ]; then
    $VENV_PIP install -r "$STUDIO_ROOT/$WAN_REPO_DIR/requirements.txt" --no-cache-dir
fi

$VENV_PIP install onnx onnxruntime-gpu sageattention matrix-nio --no-cache-dir


# ----------------------------------------------------------------------------------#
# 3. WRAPPER LINK
# ----------------------------------------------------------------------------------#
WAN_WRAPPER_TARGET="$STUDIO_ROOT/$COMFY_DIR/custom_nodes/ComfyUI-WanVideoWrapper"

if [ ! -L "$WAN_WRAPPER_TARGET" ]; then
    mkdir -p "$(dirname "$WAN_WRAPPER_TARGET")"
    ln -s "../../$(basename "$WAN_REPO_DIR")" "$WAN_WRAPPER_TARGET"
fi

# ----------------------------------------------------------------------------------#
# 4. HARDWARE PATCH
# ----------------------------------------------------------------------------------#
if grep -q "VRAM_MODE=highvram" "$ENV_FILE"; then
    sed -i 's/VRAM_MODE=highvram/VRAM_MODE=lowvram/g' "$ENV_FILE"
fi

if ! grep -q "COMFY_ARGS" "$ENV_FILE"; then
    echo 'COMFY_ARGS="--lowvram --fp8_e4m3fn-text-enc --fast-lowvram --preview-method auto"' >> "$ENV_FILE"
fi

# Plugins
pip install rotary-embedding-torch imageio-ffmpeg

# ----------------------------------------------------------------------------------#
# 7. ASSETS (WAN 2.2)
# ----------------------------------------------------------------------------------#

# LOAD ENGINE
source "$STUDIO_ROOT/dev/models-download.sh"

ASSETS=(
    # WAN 2.2 diffusion model
    "Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors|diffusion_models"
    "Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/diffusion_models/wan2.2_s2v_14B_bf16.safetensors|diffusion_models"

    # WAN 2.1 VAE
    "Comfy-Org/Wan_2.1_ComfyUI_repackaged|split_files/vae/wan_2.1_vae.safetensors|vae"

    # WAN 2.1 text encoder
    "Comfy-Org/Wan_2.1_ComfyUI_repackaged|split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors|text_encoders"

    # FLUX CLIP
    "comfyanonymous/flux_text_encoders|clip_l.safetensors|clip"

    # WAN 2.2 LoRA motion extension
    "Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors|loras"

    # WAN audio encoder
    "Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/audio_encoders/wav2vec2_large_english_fp16.safetensors|audio_encoders"
)

export ASSETS

# EXECUTE
run_assets