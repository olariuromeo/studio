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
# 1. HeartMuLA Submodule Setup (Self-Healing Logic)
# ----------------------------------------------------------------------------------#
echo "🔍 Checking HeartMuLA submodule status..."

if ! grep -q "path = $HEARTMULA_DIR" .gitmodules 2>/dev/null; then
    echo "→ Registering HeartMuLA as an official submodule..."
    git submodule add -f "$HEARTMULA_REPO" "$HEARTMULA_DIR"
fi

git submodule sync "$HEARTMULA_DIR"
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
    echo "❌ ERROR: VENV not found in $COMFY_DIR. Run setup-comfy.sh first."
    exit 1
fi

# Activate the existing ComfyUI environment
source venv/bin/activate

# Upgrade pip to match current VENV standards
pip install --upgrade pip

if [ -f "$HEARTMULA_TARGET/requirements.txt" ]; then
    echo "→ Installing from requirements.txt..."
    pip install -r "$HEARTMULA_TARGET/requirements.txt"
fi

# Use CUDA_TAG from environment (calculated in setup-comfy.sh or .env.dev)
# This ensures HeartMuLA matches the ComfyUI core version
echo "→ Installing extra modules for ${CUDA_TAG}: soundfile, torchtune, torchao, huggingface_hub..."

pip install \
    soundfile \
    torchtune \
    torchao \
    huggingface_hub \
    --extra-index-url "https://download.pytorch.org/whl/${CUDA_TAG}"

# FFmpeg check
if ! command -v ffmpeg &> /dev/null; then
    echo "⚠️ WARNING: FFmpeg is not installed on this system!"
fi

# ----------------------------------------------------------------------------------#
# 4. Download Model Weights (Physical Sync Engine)
# ----------------------------------------------------------------------------------#
MODELS_DIR="$STUDIO_ROOT/$COMFY_DIR/models"
HEARTMULA_MODELS_DIR="$MODELS_DIR/HeartMuLa"

echo "📥 Syncing HeartMuLA models (Physical Copy Mode)..."

export PATH="$HOME/.local/bin:$PATH"
# Fallback to huggingface-cli if custom 'hf' alias is not found
HF_BINARY=$(command -v hf || command -v huggingface-cli || echo "$HOME/.local/bin/hf")

# Auth Check (HF_TOKEN is already loaded from .env.dev at the top of the script)
if [ -n "${HF_TOKEN:-}" ]; then
    "$HF_BINARY" auth login --token "$HF_TOKEN" > /dev/null 2>&1
fi

# Function to download entire repo and convert symlinks to physical files
sync_repo() {
    local repo="$1"
    local local_target_dir="$2"

    echo "[SYNC] Checking repo $repo..."
    mkdir -p "$local_target_dir"

    # Download the entire repo
    "$HF_BINARY" download "$repo" --local-dir "$local_target_dir"

    # Convert HF cache symlinks to physical files
    find "$local_target_dir" -type l -print0 | while IFS= read -r -d '' symlink; do
        echo "[FIX] Converting symlink to physical file: $(basename "$symlink")..."
        cp --remove-destination "$(readlink -f "$symlink")" "$symlink"
        chmod 664 "$symlink"
    done

    echo "[OK] $repo verified and synchronized."
}

# 1. HeartMuLaGen (Root level of HeartMuLa models)
sync_repo "HeartMuLa/HeartMuLaGen" "$HEARTMULA_MODELS_DIR"

# 2. Base model (Using RL-oss-3B-20260123)
sync_repo "HeartMuLa/HeartMuLa-RL-oss-3B-20260123" "$HEARTMULA_MODELS_DIR/HeartMuLa-RL-oss-3B-20260123"

# 3. HeartCodec model (Matching the 20260123 version)
sync_repo "HeartMuLa/HeartCodec-oss-20260123" "$HEARTMULA_MODELS_DIR/HeartCodec-oss-20260123"

# 4. HeartTranscriptor
sync_repo "HeartMuLa/HeartTranscriptor-oss" "$HEARTMULA_MODELS_DIR/HeartTranscriptor-oss"

# ----------------------------------------------------------------------------------#
# 5. Finalize & Cleanup
# ----------------------------------------------------------------------------------#
echo "🧹 Finalizing setup..."

# Exit the virtual environment before finishing the script
deactivate

cd "$STUDIO_ROOT"
git add "$HEARTMULA_DIR"

echo "✅ HeartMuLA setup complete! Returning to master orchestrator."