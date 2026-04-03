#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-comfy.sh
# Description: Self-contained ComfyUI Provisioning (Clone + VENV + Torch).
# ----------------------------------------------------------------------------------#
set -e

# 0. Context & Environment Loading
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$STUDIO_ROOT/.env" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)
else
    echo "❌ [ERROR] .env missing in $STUDIO_ROOT"
    exit 1
fi

# Fallback values if not defined in .env
COMFY_TAG="${COMFY_TAG:-master}"
COMFY_PYTHON_VERSION="${COMFY_PYTHON_VERSION:-3.11.9}"
CUDA_TAG="cu$(echo $CUDA_VERSION | sed 's/\.//')"

echo "⚙️  [COMFY] Initializing Backend Engine (Tag: $COMFY_TAG)..."

# ----------------------------------------------------------------------------------#
# 1. Repository Synchronization
# ----------------------------------------------------------------------------------#
mkdir -p "$STUDIO_ROOT/apps"
if [ ! -d "$COMFY_DIR" ]; then
    echo "   -> Cloning fresh ComfyUI at branch/tag $COMFY_TAG..."
    git clone --branch "$COMFY_TAG" https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR"
else
    echo "   -> Folder exists. Forcing checkout for consistency: $COMFY_TAG..."
    cd "$COMFY_DIR"
    git fetch --all --tags
    git checkout "tags/$COMFY_TAG" -f || git checkout "$COMFY_TAG" -f
fi

# ----------------------------------------------------------------------------------#
# 2. Language & Environment Alignment (ASDF)
# ----------------------------------------------------------------------------------#
cd "$COMFY_DIR"
echo "python $COMFY_PYTHON_VERSION" > .tool-versions
. "$HOME/.asdf/asdf.sh"
asdf install
asdf reshim

# 3. Virtual Environment Setup
echo "🧹 [COMFY] Creating fresh VENV (Python $COMFY_PYTHON_VERSION)..."
[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

# ----------------------------------------------------------------------------------#
# 4. PyTorch JIT Installation (CUDA Driven)
# ----------------------------------------------------------------------------------#
echo "📥 [COMFY] Forcing PyTorch 2.5.1 with CUDA URL Tag: $CUDA_TAG..."

# Clean old versions
pip uninstall torch torchvision torchaudio -y || true

# Direct Install from WHL index
pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
    --index-url "https://download.pytorch.org/whl/$CUDA_TAG" \
    --no-cache-dir

# ----------------------------------------------------------------------------------#
# 5. Core Requirements & Custom Nodes (Manager)
# ----------------------------------------------------------------------------------#
echo "📥 [COMFY] Installing Official Requirements..."
[ -f "requirements.txt" ] && pip install -r requirements.txt

# --- Manager Installation ---
MANAGER_DIR="$COMFY_DIR/custom_nodes/ComfyUI-Manager"
if [ ! -d "$MANAGER_DIR" ]; then
    echo "📦 [COMFY] Cloning ComfyUI-Manager..."
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git "$MANAGER_DIR"
fi

echo "📦 [COMFY] Installing Manager dependencies..."
if [ -f "$MANAGER_DIR/requirements.txt" ]; then
    pip install -r "$MANAGER_DIR/requirements.txt"
fi

deactivate
echo "✅ [COMFY] Environment ready. Backend is fully provisioned and locked."