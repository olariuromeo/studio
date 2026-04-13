#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/setup-heartmula.sh
# Description: Submodule-native Provisioning for HeartMuLA_ComfyUI
# ----------------------------------------------------------------------------------#
set -euo pipefail

# 0. Context & Environment Loading
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

trap 'echo "❌ Error at line $LINENO"; exit 1' ERR

ENV_DEV="$STUDIO_ROOT/.env.dev"

if [ ! -f "$ENV_DEV" ]; then
    echo "❌ Missing .env.dev file."
    exit 1
fi

echo "✔️ Using .env.dev"

# Load env safely
set -a
source "$ENV_DEV"
set +a

# Validate required ENV
: "${COMFY_DIR:?Missing COMFY_DIR}"
: "${HEARTMULA_REPO:?Missing HEARTMULA_REPO}"
: "${HEARTMULA_DIR:?Missing HEARTMULA_DIR}"

cd "$STUDIO_ROOT"

# ----------------------------------------------------------------------------------#
# 1. HeartMuLA Submodule Setup
# ----------------------------------------------------------------------------------#
if ! grep -q "path = $HEARTMULA_DIR" .gitmodules 2>/dev/null; then
    echo "→ Registering HeartMuLA submodule..."
    git submodule add -f "$HEARTMULA_REPO" "$HEARTMULA_DIR"
fi

git submodule update --init --recursive -- "$HEARTMULA_DIR"

# ----------------------------------------------------------------------------------#
# 2. Symlink HeartMuLA (SAFE)
# ----------------------------------------------------------------------------------#
HEARTMULA_TARGET="$STUDIO_ROOT/$COMFY_DIR/custom_nodes/HeartMuLa_ComfyUI"

if [ ! -L "$HEARTMULA_TARGET" ]; then
    echo "🔗 Linking HeartMuLA..."
    ln -s "$STUDIO_ROOT/$HEARTMULA_DIR" "$HEARTMULA_TARGET"
fi

# ----------------------------------------------------------------------------------#
# 3. HeartMuLA Requirements (Using ComfyUI VENV)
# ----------------------------------------------------------------------------------#
echo "📦 Installing HeartMuLA dependencies..."

cd "$STUDIO_ROOT/$COMFY_DIR"

if [ ! -f "venv/bin/activate" ]; then
    echo "❌ VENV not found in $COMFY_DIR. Please run setup-comfy.sh first."
    exit 1
fi

source venv/bin/activate

if [ -f "$HEARTMULA_TARGET/requirements.txt" ]; then
    pip install -r "$HEARTMULA_TARGET/requirements.txt"
fi

# Install required extra modules as per documentation
echo "📦 Installing extra modules (soundfile, torchtune, torchao, huggingface_hub)..."
pip install soundfile torchtune torchao huggingface_hub

# Check for FFmpeg (Required for audio processing)
if ! command -v ffmpeg &> /dev/null; then
    echo "⚠️ WARNING: FFmpeg is not installed on this system!"
    echo "👉 Linux: sudo apt-get install ffmpeg | Windows: Download shared build and add to PATH"
fi

# ----------------------------------------------------------------------------------#
# 4. Download Model Weights
# ----------------------------------------------------------------------------------#
MODELS_PATH="$STUDIO_ROOT/$COMFY_DIR/models"
echo "📥 Downloading HeartMuLA models to $MODELS_PATH/HeartMuLa..."

mkdir -p "$MODELS_PATH/HeartMuLa"
cd "$MODELS_PATH"

# 1. HeartMuLaGen
echo "→ Downloading HeartMuLaGen..."
huggingface-cli download HeartMuLa/HeartMuLaGen --local-dir ./HeartMuLa

# 2. Base model (Using RL-oss-3B-20260123)
echo "→ Downloading HeartMuLa-RL-oss-3B-20260123..."
huggingface-cli download HeartMuLa/HeartMuLa-RL-oss-3B-20260123 --local-dir ./HeartMuLa/HeartMuLa-RL-oss-3B-20260123

# 3. HeartCodec model (Matching the 20260123 version)
echo "→ Downloading HeartCodec-oss-20260123..."
huggingface-cli download HeartMuLa/HeartCodec-oss-20260123 --local-dir ./HeartMuLa/HeartCodec-oss-20260123

# 4. HeartTranscriptor
echo "→ Downloading HeartTranscriptor-oss..."
huggingface-cli download HeartMuLa/HeartTranscriptor-oss --local-dir ./HeartMuLa/HeartTranscriptor-oss

deactivate

# ----------------------------------------------------------------------------------#
# 5. Finalize
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"
git add "$HEARTMULA_DIR"

echo "✅ HeartMuLA setup complete! Models downloaded and submodule linked."