#!/bin/bash

# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: install.sh
# Description: Coozila! Studio v4.0 - Full Local Stack (No-Docker).
#              Orchestrates dual Python environments for Backend & Frontend.
# ----------------------------------------------------------------------------------#

set -e

# 0. Base Configuration
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="$STUDIO_ROOT/apps"

echo "--------------------------------------------------------"
echo "🚀 Coozila! Studio v4.0: Local Non-Docker Deployment"
echo "--------------------------------------------------------"

# 1. Environment Loading
if [ ! -f "$STUDIO_ROOT/.env" ]; then
    cp "$STUDIO_ROOT/.env.example" "$STUDIO_ROOT/.env"
fi
export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)

# Paths
COMFY_DIR="$APPS_DIR/ComfyUI"
WEBUI_DIR="$APPS_DIR/open-webui"
CUDA_TAG="cu$(echo $CUDA_VERSION | sed 's/\.//')"

# 2. System Core
echo "🔐 Step 1: System Dependencies..."
sudo apt update && sudo apt install -y \
    ffmpeg git build-essential libssl-dev python3-dev curl jq \
    python3-venv libgl1-mesa-glx libglib2.0-0 unzip

# 3. ASDF Setup
. "$HOME/.asdf/asdf.sh"
asdf plugin add python || true
asdf install python "$PYTHON_VERSION" || true

# 4. Repo Sync (Tags)
mkdir -p "$APPS_DIR"
[ ! -d "$WEBUI_DIR" ] && git clone --branch $WEBUI_TAG https://github.com/open-webui/open-webui.git "$WEBUI_DIR"
[ ! -d "$COMFY_DIR" ] && git clone --branch $COMFY_TAG https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR"

# --------------------------------------------------------
# 5. FRONTEND SETUP (Open-WebUI Local)
# --------------------------------------------------------
echo "🌐 Step 4: Building Frontend Environment (Open-WebUI)..."
cd "$WEBUI_DIR"
asdf local python "$PYTHON_VERSION"

[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
python -m pip install --upgrade pip
# Install Open-WebUI via pip for local serving
python -m pip install open-webui
deactivate

# --------------------------------------------------------
# 6. BACKEND SETUP (ComfyUI Local)
# --------------------------------------------------------
echo "🔧 Step 5: Building Backend Environment (ComfyUI)..."
cd "$COMFY_DIR"
asdf local python "$PYTHON_VERSION"

[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
python -m pip install --upgrade pip

echo "📥 Installing Torch Stack ($CUDA_TAG)..."
python -m pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/$CUDA_TAG

echo "📥 Installing Engine Dependencies..."
python -m pip install GitPython opencv-python-headless matplotlib librosa imageio-ffmpeg pydub ffmpeg-python \
    accelerate diffusers transformers insightface pandas -r requirements.txt

# ComfyUI-Manager
if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
fi
python -m pip install -r custom_nodes/ComfyUI-Manager/requirements.txt

# --------------------------------------------------------
# 7. FINAL LAUNCH ORCHESTRATION
# --------------------------------------------------------
echo "--------------------------------------------------------"
echo "✅ LOCAL DEPLOYMENT COMPLETE"
echo "--------------------------------------------------------"

# Start Open-WebUI in background
echo "🚀 Starting Frontend (Port $STUDIO_PORT)..."
cd "$WEBUI_DIR"
source venv/bin/activate
PORT=$STUDIO_PORT open-webui serve & 

# Start ComfyUI in foreground (Main Process)
echo "🎬 Starting Backend Engine (Port $ENGINE_PORT)..."
cd "$COMFY_DIR"
source venv/bin/activate
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