#!/bin/bash

# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: install.sh
# Description: Coozila! Studio v4.0 - Universal Full Stack Installer.
# Optimized for: Ubuntu Desktop 22.04 LTS, CUDA 12.5 (Pre-installed).
# ----------------------------------------------------------------------------------#

set -e

# 0. Paths & Variables
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="$STUDIO_ROOT/apps"
COMFY_DIR="$APPS_DIR/ComfyUI"
WEBUI_DIR="$APPS_DIR/open-webui"
VENV_PATH="$COMFY_DIR/venv"
PYTHON_VERSION="3.11.9"

echo "--------------------------------------------------------"
echo "🚀 Coozila! Studio v4.0 Deployment Initiated"
echo "--------------------------------------------------------"

# 1. System Requirements Check (Pre-installed CUDA/Drivers)
echo "🔍 Checking System Prerequisites..."
if ! command -v nvidia-smi &> /dev/null; then
    echo "❌ ERROR: NVIDIA Drivers not found. Please install Drivers and CUDA 12.5 before running this script."
    exit 1
fi

# 2. System Dependencies (Apt)
echo "🔐 Step 1: Installing System Dependencies..."
sudo apt update && sudo apt install -y \
    ffmpeg git build-essential libssl-dev python3-dev curl jq \
    python3-venv libgl1-mesa-glx libglib2.0-0 unzip dirmngr gpg

# 3. ASDF Runtime Manager Installation & Configuration
echo "🐍 Step 2: Configuring ASDF Runtime Manager..."
if [ ! -d "$HOME/.asdf" ]; then
    echo "📥 Installing asdf..."
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
    . "$HOME/.asdf/asdf.sh"
    grep -q "asdf.sh" ~/.bashrc || echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc
    grep -q "asdf.bash" ~/.bashrc || echo ". $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc
else
    echo "✅ asdf is already installed."
    . "$HOME/.asdf/asdf.sh"
fi

# Python plugin and version check
if ! asdf plugin list | grep -q "python"; then
    echo "📥 Adding asdf python plugin..."
    asdf plugin add python
fi

if ! asdf list python | grep -q "$PYTHON_VERSION"; then
    echo "📥 Installing Python $PYTHON_VERSION via asdf (this may take a while)..."
    asdf install python "$PYTHON_VERSION"
fi

# 4. Ecosystem Cloning (Existence Checks)
echo "📦 Step 3: Synchronizing Apps Ecosystem..."
mkdir -p "$APPS_DIR"

# Open-WebUI
if [ ! -d "$WEBUI_DIR" ]; then
    echo "📥 Cloning Open-WebUI..."
    git clone https://github.com/open-webui/open-webui.git "$WEBUI_DIR"
else
    echo "✅ Open-WebUI repository found."
fi

# ComfyUI
if [ ! -d "$COMFY_DIR" ]; then
    echo "📥 Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR"
else
    echo "✅ ComfyUI repository found."
fi

# 5. Local Configuration & VENV Setup
echo "🔧 Step 4: Building Local Python Environment..."
cd "$COMFY_DIR"
asdf local python "$PYTHON_VERSION"
asdf reshim python

if [ ! -d "$VENV_PATH" ]; then
    echo "📦 Creating Virtual Environment in apps/ComfyUI/venv..."
    python -m venv venv
fi

source venv/bin/activate

# 6. Dependency Sync (Optimized for RTX 3080 / CUDA 12.5)
echo "🛠️ Step 5: Installing Studio & Engine Requirements..."
python -m pip install --upgrade pip --quiet

# Core AI Stack & Studio Tools
python -m pip install --quiet \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    -r requirements.txt \
    opencv-python-headless matplotlib librosa GitPython imageio-ffmpeg pydub ffmpeg-python \
    accelerate diffusers transformers insightface pandas

# ComfyUI Manager (Auto-install)
if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
    echo "📥 Installing ComfyUI-Manager..."
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
fi

# 7. Final Execution
echo "--------------------------------------------------------"
echo "✅ Coozila! Studio Setup Complete."
echo "🎬 Launching Engine (Optimized for RTX 3080)..."
echo "--------------------------------------------------------"

cd "$COMFY_DIR"
exec python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --enable-manager \
    --lowvram \
    --enable-dynamic-vram \
    --async-offload \
    --mmap-torch-files \
    --preview-method auto \
    --headless