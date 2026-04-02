#!/bin/bash

# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: install.sh
# Description: Coozila! Studio v4.0 - Native Python & ASDF Orchestrator.
#              Automates file overwrite, asdf tool alignment, and Hatch builds.
# ----------------------------------------------------------------------------------#
set -e

# 0. Global Context
export STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export APPS_DIR="$STUDIO_ROOT/apps"
export WEBUI_DIR="$APPS_DIR/open-webui"
export COMFY_DIR="$APPS_DIR/ComfyUI"

# 1. Load .env
[ ! -f ".env" ] && cp .env.example .env
export $(grep -v '^#' .env | xargs)
export CUDA_TAG="cu$(echo $CUDA_VERSION | sed 's/\.//')"

# 2. System Check & Sync
sudo apt update && sudo apt install -y ffmpeg git build-essential curl jq
mkdir -p "$APPS_DIR"

echo "📦 Syncing Repos..."
[ ! -d "$WEBUI_DIR" ] && git clone --branch $WEBUI_TAG https://github.com/open-webui/open-webui.git "$WEBUI_DIR"
[ ! -d "$COMFY_DIR" ] && git clone --branch $COMFY_TAG https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR"

# 3. Overwrite Studio Core (Înainte de build)
cp -rv "$STUDIO_ROOT/canvas/"* "$WEBUI_DIR/src/"
cp -rv "$STUDIO_ROOT/core/"* "$WEBUI_DIR/backend/"

# 4. DELEGATE (Aici e magia)
chmod +x scripts/*.sh
./scripts/setup-webui.sh
./scripts/setup-comfy.sh

# 5. Launch
echo "🚀 All systems go! Launching..."
cd "$WEBUI_DIR"
source venv/bin/activate
PORT=$STUDIO_PORT open-webui serve > ../../open-webui.log 2>&1 &

cd "$COMFY_DIR"
source venv/bin/activate
exec python main.py --listen 0.0.0.0 --port $ENGINE_PORT --enable-manager --$VRAM_MODE --enable-dynamic-vram --async-offload --mmap-torch-files --preview-method auto