#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-wan2.sh
# Description: Minimalist Environment Provisioning for Wan 2.2.
# ----------------------------------------------------------------------------------#
set -e

# 1. Path Alignment
[ -z "$COMFY_DIR" ] && COMFY_DIR="$(pwd)/apps/ComfyUI"
WRAPPER_DIR="$COMFY_DIR/custom_nodes/ComfyUI-WanVideoWrapper"
VENV_PATH="$COMFY_DIR/venv"

echo "🚀 [WAN 2.2] Syncing Wrapper & Dependencies..."

# 2. Clone Wrapper
if [ ! -d "$WRAPPER_DIR" ]; then
    echo "📦 [WRAPPER] Cloning WanVideoWrapper..."
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git "$WRAPPER_DIR"
fi

# 3. Dependency Injection
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    cd "$WRAPPER_DIR"
    
    echo "📥 [PIP] Upgrading build tools..."
    pip install --upgrade pip setuptools wheel --no-cache-dir

    echo "📥 [PIP] Installing Requirements..."
    [ -f "requirements.txt" ] && pip install -r requirements.txt --no-cache-dir
    
    echo "📥 [PIP] Injecting Specialized AI Acceleration..."

    pip install onnx onnxruntime-gpu sageattention matrix-nio --no-cache-dir
    
    deactivate
else
    echo "❌ [ERROR] VENV not found at $VENV_PATH. Run setup-comfy.sh first."
    exit 1
fi

echo "✅ [SUCCESS] Wan 2.2 Wrapper is fully provisioned with Face Restoration support."