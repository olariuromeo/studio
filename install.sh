#!/bin/bash

# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: install.sh
# Description: Coozila! Studio v4.0 - Universal Dynamic Installer.
#              All versions and tags are pulled from .env for strict consistency.
# ----------------------------------------------------------------------------------#

set -e

# 0. Base Path
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="$STUDIO_ROOT/apps"

echo "--------------------------------------------------------"
echo "🚀 Coozila! Studio v4.0: Dynamic Environment Boot"
echo "--------------------------------------------------------"

# 1. Environment Guard & Loading
if [ ! -f "$STUDIO_ROOT/.env" ]; then
    echo "📝 Initializing .env from template..."
    cp "$STUDIO_ROOT/.env.example" "$STUDIO_ROOT/.env"
fi

# Export all variables from .env
export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)

# Calculated Variables
CUDA_TAG="cu$(echo $CUDA_VERSION | sed 's/\.//')"
COMFY_DIR="$APPS_DIR/ComfyUI"
WEBUI_DIR="$APPS_DIR/open-webui"
VENV_PATH="$COMFY_DIR/venv"

echo "📍 Target Python: $PYTHON_VERSION"
echo "📍 Target CUDA: $CUDA_VERSION ($CUDA_TAG)"
echo "📍 Target ComfyUI: $COMFY_TAG"
echo "📍 Target WebUI: $WEBUI_TAG"

# 2. System Core Dependencies
echo "🔐 Step 1: Installing System Prerequisites..."
sudo apt update && sudo apt install -y \
    ffmpeg git build-essential libssl-dev python3-dev curl jq \
    python3-venv libgl1-mesa-glx libglib2.0-0 unzip dirmngr gpg

# 3. ASDF Runtime Setup
echo "🐍 Step 2: Configuring Python $PYTHON_VERSION via ASDF..."
. "$HOME/.asdf/asdf.sh" || { echo "❌ ASDF not found."; exit 1; }

asdf plugin add python || true
if ! asdf list python | grep -q "$PYTHON_VERSION"; then
    echo "📥 Installing Python $PYTHON_VERSION..."
    asdf install python "$PYTHON_VERSION"
fi

# 4. Repository Synchronization (Strict Tag Checkout)
echo "📦 Step 3: Syncing Stable Repositories..."
mkdir -p "$APPS_DIR"

# Open-WebUI Sync
if [ ! -d "$WEBUI_DIR" ]; then
    git clone --branch $WEBUI_TAG https://github.com/open-webui/open-webui.git "$WEBUI_DIR"
else
    cd "$WEBUI_DIR" && git fetch --tags && git checkout $WEBUI_TAG && cd "$STUDIO_ROOT"
fi

# ComfyUI Sync
if [ ! -d "$COMFY_DIR" ]; then
    git clone --branch $COMFY_TAG https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR"
else
    cd "$COMFY_DIR" && git fetch --tags && git checkout $COMFY_TAG && cd "$STUDIO_ROOT"
fi

# 5. Backend Environment (Total Purge for Version Matching)
echo "🔧 Step 4: Building Backend Environment..."
cd "$COMFY_DIR"

if [ -d "$VENV_PATH" ]; then
    echo "🧹 Purging existing VENV to match Python $PYTHON_VERSION..."
    rm -rf "$VENV_PATH"
fi

asdf local python "$PYTHON_VERSION"
asdf reshim python
python -m venv venv
source venv/bin/activate

python -m pip install --upgrade pip

echo "📥 Installing AI Stack for $CUDA_TAG..."
python -m pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/$CUDA_TAG

echo "🛠️ Installing Studio & Node Dependencies..."
python -m pip install GitPython opencv-python-headless matplotlib librosa imageio-ffmpeg pydub ffmpeg-python \
    accelerate diffusers transformers insightface pandas -r requirements.txt

# ComfyUI-Manager
if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
fi
python -m pip install -r custom_nodes/ComfyUI-Manager/requirements.txt

# 6. Frontend Launch (Docker)
echo "🐳 Step 5: Booting Frontend UI (Docker Compose)..."
cd "$STUDIO_ROOT"
docker compose up -d --build

# 7. Final Execution
echo "--------------------------------------------------------"
echo "✅ DEPLOYMENT COMPLETE"
echo "--------------------------------------------------------"

cd "$COMFY_DIR"
exec python main.py \
    --listen 0.0.0.0 \
    --port $ENGINE_PORT \
    --enable-manager \
    --$VRAM_MODE \
    --enable-dynamic-vram \
    --async-offload \
    --mmap-torch-files \
    --preview-method auto \
    --headless