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
echo "🔧 [COMFY] Starting Backend AI Setup..."

# 1. Align versions
cp "$STUDIO_ROOT/.tool-versions" "$COMFY_DIR/.tool-versions"
cd "$COMFY_DIR"
. "$HOME/.asdf/asdf.sh"
asdf reshim

# 2. Venv & Torch
[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

echo "📥 [COMFY] Installing Torch for $CUDA_TAG..."
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/$CUDA_TAG
pip install -r requirements.txt

# Manager
[ ! -d "custom_nodes/ComfyUI-Manager" ] && git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
pip install -r custom_nodes/ComfyUI-Manager/requirements.txt
deactivate
echo "✅ [COMFY] Backend Ready."