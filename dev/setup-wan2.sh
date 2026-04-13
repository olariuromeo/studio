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