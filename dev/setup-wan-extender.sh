#!/bin/bash
# ----------------------------------------------------------------------------------#
# Coozila! Wan Video Extender Setup
# ----------------------------------------------------------------------------------#

set -euo pipefail

STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$STUDIO_ROOT/.env.dev"

# ----------------------------------------------------------------------------------#
# 1. LOAD ENV
# ----------------------------------------------------------------------------------#
set -a
source "$ENV_FILE"
set +a

echo "🚀 COOZILA WAN EXTENDER SETUP START"

# ----------------------------------------------------------------------------------#
# 2. INSTALL CUSTOM NODE
# ----------------------------------------------------------------------------------#
WAN_NODE_DIR="$STUDIO_ROOT/$COMFY_DIR/custom_nodes/wan-video-extender"

if [ ! -d "$WAN_NODE_DIR" ]; then
    git clone https://github.com/Granddyser/wan-video-extender.git "$WAN_NODE_DIR"
else
    echo "✔️ wan-video-extender already installed"
fi

# ----------------------------------------------------------------------------------#
# 3. INSTALL REQUIREMENTS
# ----------------------------------------------------------------------------------#
VENV_PIP="$STUDIO_ROOT/$COMFY_DIR/venv/bin/pip"

if [ -f "$WAN_NODE_DIR/requirements.txt" ]; then
    $VENV_PIP install -r "$WAN_NODE_DIR/requirements.txt" --no-cache-dir
fi

echo "✔️ dependencies installed"

# ----------------------------------------------------------------------------------#
# 4. LOAD ASSET ENGINE
# ----------------------------------------------------------------------------------#
source "$STUDIO_ROOT/dev/models-download.sh"

ASSETS=(
    # WAN base model
    "Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors|diffusion_models"

    # VAE
    "Comfy-Org/Wan_2.1_ComfyUI_repackaged|split_files/vae/wan_2.1_vae.safetensors|vae"

    # Text encoder
    "Comfy-Org/Wan_2.1_ComfyUI_repackaged|split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors|text_encoders"

    # CLIP
    "comfyanonymous/flux_text_encoders|clip_l.safetensors|clip"

    # LoRA (optional video motion extension)
    "Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors|loras"

    # Audio encoder (for VACE / extend workflows)
    "Comfy-Org/Wan_2.2_ComfyUI_Repackaged|split_files/audio_encoders/wav2vec2_large_english_fp16.safetensors|audio_encoders"
)

run_assets

echo "✅ WAN EXTENDER READY"