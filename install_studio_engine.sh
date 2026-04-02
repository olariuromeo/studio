#!/bin/bash

# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: install_studio_engine.sh
# Description: Coozila! Studio v4.0 - Universal Engine Installer & Bootstrapper.
#              Automates environment setup, dependency sync, and engine launch.
# ----------------------------------------------------------------------------------#

set -e

# 1. Mapare Căi (Rădăcina Studio)
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMFY_DIR="$STUDIO_ROOT/apps/ComfyUI"
VENV_PATH="$COMFY_DIR/venv"

echo "🚀 Coozila! Studio: Initializing Environment..."

# 2. Configurare Runtime (asdf)
if command -v asdf >/dev/null 2>&1; then
    cd "$COMFY_DIR"
    asdf local python 3.11.9 || echo "Using system python..."
    asdf reshim python
    cd "$STUDIO_ROOT"
fi

# 3. Creare Virtual Env în interiorul folderului de aplicație
if [ ! -d "$VENV_PATH" ]; then
    echo "📦 Creating Virtual Environment for Studio Backend..."
    python3 -m venv "$VENV_PATH"
fi

# 4. Activare mediu
source "$VENV_PATH/bin/activate"

# 5. Instalare Dependențe (Studio Core + ComfyUI Upstream)
echo "🛠️ Installing Studio & Engine dependencies..."

# Upgrade minimal
python -m pip install --upgrade pip --quiet

# Instalare hibridă: Requirements-ul ComfyUI + Cerințele noastre pentru Studio
python -m pip install --quiet \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    -r "$COMFY_DIR/requirements.txt" \
    -r "$COMFY_DIR/custom_nodes/ComfyUI-Manager/requirements.txt" \
    opencv-python-headless matplotlib librosa GitPython imageio-ffmpeg pydub ffmpeg-python

# 6. Lansare Motor (Configurație RTX 3080)
echo "🎬 Starting Studio Engine..."

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