#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/setup-wan2.sh
# Description: Environment-driven Wan 2.2 Wrapper Provisioning
# ----------------------------------------------------------------------------------#
set -e

# ----------------------------------------------------------------------------------#
# 0. Context & Environment Loading
# ----------------------------------------------------------------------------------#
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env.dev" | xargs)
else
    export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)
fi

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
    $VENV_PIP install --upgrade pip setuptools wheel --no-cache-dir

    echo "   -> Installing Wrapper requirements..."
    if [ -f "$STUDIO_ROOT/$WAN_REPO_DIR/requirements.txt" ]; then
        $VENV_PIP install -r "$STUDIO_ROOT/$WAN_REPO_DIR/requirements.txt" --no-cache-dir
    fi
    
    echo "   -> Injecting Specialized AI Acceleration..."
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
# Sync parent index
git add "$WAN_REPO_DIR"

echo -e "✅ [SUCCESS] Wan 2.2 Wrapper is fully provisioned and linked.\n"