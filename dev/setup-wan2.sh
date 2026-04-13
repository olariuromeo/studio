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
    ENV_FILE="$STUDIO_ROOT/.env"
fi

echo "🚀 [WAN 2.2] Loading environment from $(basename "$ENV_FILE")..."
set -a
source <(sed 's/#.*//g; /^[[:space:]]*$/d' "$ENV_FILE")
set +a

# Ensure mandatory paths are derived from ENV
WAN_WRAPPER_DIR="$STUDIO_ROOT/$COMFY_DIR/custom_nodes/ComfyUI-WanVideoWrapper"
COMFY_VENV="$STUDIO_ROOT/$COMFY_DIR/venv"

echo "🚀 [WAN 2.2] Syncing Wrapper & Dependencies..."

# ----------------------------------------------------------------------------------#
# 1. Repository Registration & Sync
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"

# Auto-register WAN Wrapper submodule if missing from .gitmodules
# Note: We treat the wrapper as a submodule to maintain Studio integrity
if ! grep -q "path = $WAN_REPO_DIR" .gitmodules 2>/dev/null; then
    echo "   -> [REGISTER] Submodule $WAN_REPO_DIR not found. Adding..."
    git submodule add -f "$WAN_REPO" "$WAN_REPO_DIR"
fi

echo "   -> Syncing WanVideoWrapper submodule..."
git submodule update --init --recursive -- "$WAN_REPO_DIR"

# ----------------------------------------------------------------------------------#
# 2. Dependency Injection (ComfyUI VENV)
# ----------------------------------------------------------------------------------#
if [ -d "$COMFY_VENV" ]; then
    echo "⚙️  Injecting dependencies into ComfyUI VENV..."
    VENV_PIP="$COMFY_VENV/bin/pip"

    echo "   -> Upgrading build tools..."
    $VENV_PIP install --upgrade pip "setuptools<82" wheel --no-cache-dir

    echo "   -> Installing Wrapper requirements..."
    if [ -f "$STUDIO_ROOT/$WAN_REPO_DIR/requirements.txt" ]; then
        $VENV_PIP install -r "$STUDIO_ROOT/$WAN_REPO_DIR/requirements.txt" --no-cache-dir
    fi
    
    echo "   -> Injecting Specialized AI Acceleration (SageAttention/Matrix-NIO)..."
    $VENV_PIP install onnx onnxruntime-gpu sageattention matrix-nio --no-cache-dir
else
    echo "❌ [ERROR] ComfyUI VENV not found at $COMFY_VENV. Run setup-comfy.sh first!"
    exit 1
fi

# ----------------------------------------------------------------------------------#
# 3. Linking & Finalize Index
# ----------------------------------------------------------------------------------#
# Create Symlink inside ComfyUI custom_nodes if it doesn't exist
if [ ! -L "$WAN_WRAPPER_DIR" ]; then
    echo "🔗 [WAN 2.2] Linking Wrapper into ComfyUI custom_nodes..."
    mkdir -p "$(dirname "$WAN_WRAPPER_DIR")"
    ln -s "../../$(basename "$WAN_REPO_DIR")" "$WAN_WRAPPER_DIR"
fi

cd "$STUDIO_ROOT"
# Update git index for the submodule
git add "$WAN_REPO_DIR"

# ----------------------------------------------------------------------------------#
# 4. Hardware Optimization (10GB VRAM Guard for RTX 3080)
# ----------------------------------------------------------------------------------#
echo "🧠 [HARDWARE] Tuning $ENV_FILE for 10GB VRAM + 64GB RAM..."

# Disable High VRAM if enabled, otherwise Wan 2.2 will crash at 14B
if grep -q "VRAM_MODE=highvram" "$ENV_FILE"; then
    echo "   -> [PATCH] Switching VRAM_MODE to lowvram (Required for Wan 2.2 14B)."
    sed -i 's/VRAM_MODE=highvram/VRAM_MODE=lowvram/g' "$ENV_FILE"
fi

# Apply optimized arguments to the environment file if missing
if ! grep -q "COMFY_ARGS" "$ENV_FILE" 2>/dev/null; then
    echo "   -> [OPTIMIZE] Adding memory-safe arguments to $ENV_FILE."
    echo 'COMFY_ARGS="--lowvram --fp8_e4m3fn-text-enc --fast-lowvram --preview-method auto"' >> "$ENV_FILE"
fi

echo -e "\n✅ [SUCCESS] Wan 2.2 Wrapper is fully provisioned and linked."
echo -e "🚀 \033[1;32mCoozila! Studio is armed and ready.\033[0m"
echo -e "💡 \033[1;33m[TIP]\033[0m Start the engine with \033[1;34mpython main.py \$COMFY_ARGS\033[0m to enable the 64GB RAM buffer.\n"

# ----------------------------------------------------------------------------------#
# 5. Download Wan 2.2 Assets (Physical Sync Engine)
# ----------------------------------------------------------------------------------#
MODELS_DIR="$STUDIO_ROOT/$COMFY_DIR/models"
echo -e "\n📥 [WAN 2.2] Starting Physical Model Sync..."

# Ensure we have the HF binary and Token
export PATH="$HOME/.local/bin:$PATH"
HF_BINARY=$(command -v hf || command -v huggingface-cli || echo "$HOME/.local/bin/hf")

if [ -n "${HF_TOKEN:-}" ]; then
    "$HF_BINARY" auth login --token "$HF_TOKEN" > /dev/null 2>&1
fi

# Core Sync Function (Physical Copy)
sync_asset() {
    local repo="$1"
    local remote_path="$2"
    local local_target_dir="$3"
    local filename=$(basename "$remote_path")
    local final_dest="$local_target_dir/$filename"

    echo "   -> [SYNC] Checking $filename..."
    mkdir -p "$local_target_dir"

    "$HF_BINARY" download "$repo" "$remote_path" --local-dir "$local_target_dir"

    # Convert HF symlink to physical file for portability
    if [ -L "$final_dest" ]; then
        echo "      [FIX] Converting symlink to physical..."
        cp --remove-destination "$(readlink -f "$final_dest")" "$final_dest"
        chmod 664 "$final_dest"
    fi
}

# --- WAN 2.2 CORE ASSETS ---

# 1. VAE
sync_asset "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/vae/wan_2.1_vae.safetensors" "$MODELS_DIR/vae"

# 2. Text Encoders (UMT5 XXL FP8 optimized for 10GB VRAM)
sync_asset "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$MODELS_DIR/text_encoders"
sync_asset "comfyanonymous/flux_text_encoders" "clip_l.safetensors" "$MODELS_DIR/clip"

# 3. Diffusion Models (S2V 14B FP8 Scaled - The Sweet Spot for RTX 3080)
sync_asset "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors" "$MODELS_DIR/diffusion_models"

# 4. Audio Encoders (For Video-to-Audio / LipSync)
sync_asset "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/audio_encoders/wav2vec2_large_english_fp16.safetensors" "$MODELS_DIR/audio_encoders"

# 5. Specialized LoRAs (4-Step Lightning)
sync_asset "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" "$MODELS_DIR/loras"

echo -e "\n✅ [SUCCESS] Wan 2.2: Environment, Wrapper, and Physical Models are READY."