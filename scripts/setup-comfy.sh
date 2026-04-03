#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: studio/scripts/setup-comfy.sh
# Description: Local Environment Configuration for Coozila! Studio v4.0.
# ----------------------------------------------------------------------------------#
set -e

echo "🔧 [COMFY] Initializing Backend AI Stack (Python $COMFY_PYTHON_VERSION)..."

# 1. ASDF & Environment Alignment
cd "$COMFY_DIR"
echo "python $COMFY_PYTHON_VERSION" > .tool-versions
. "$HOME/.asdf/asdf.sh"
asdf install
asdf reshim

# 2. Virtual Environment Setup
echo "🧹 [COMFY] Creating fresh VENV..."
[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

# ----------------------------------------------------------------------------------#
# 3. Step A: Dynamic Torch Install (Driven by .env)
# ----------------------------------------------------------------------------------#
echo "📥 [MANUAL] Forcing PyTorch 2.5.1 with CUDA $CUDA_VERSION (Target URL tag: $CUDA_TAG)..."

# Remove any previous torch installations to prevent conflicts and ensure a clean slate
pip uninstall torch torchvision torchaudio -y || true

# Install the verified version directly from the official repository using the dynamic tag
pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
    --index-url "https://download.pytorch.org/whl/$CUDA_TAG" \
    --no-cache-dir

# ----------------------------------------------------------------------------------#
# 4. Official Setup (Requirements & Manager)
# ----------------------------------------------------------------------------------#
echo "📥 [COMFY] Installing Official Requirements..."
[ -f "requirements.txt" ] && pip install -r requirements.txt

# INSTALL MANAGER (As per official documentation)
echo "📦 [COMFY] Installing Manager dependencies..."
if [ -f "manager_requirements.txt" ]; then
    pip install -r manager_requirements.txt
fi

deactivate
echo "✅ [COMFY] Environment ready. Torch locked on CU$CUDA_TAG."