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
# System Library Check (libsndfile1)
# ----------------------------------------------------------------------------------#
# Check package status without sudo to keep the execution light
if dpkg-query -W -f='${Status}' libsndfile1 2>/dev/null | grep -q "ok installed"; then
    echo "✔️ libsndfile1 is already installed. Skipping system tasks."
else
    echo "⚠️ libsndfile1 not found. Starting automated installation..."
    
    # Execute system update and installation only when necessary
    sudo apt-get update -y -qq
    sudo apt-get install -y libsndfile1
    
    echo "✅ libsndfile1 installed successfully."
fi

# ----------------------------------------------------------------------------------#
# 3. HeartMuLA Requirements (Using ComfyUI VENV)
# ----------------------------------------------------------------------------------#
echo "📦 Installing HeartMuLA specialized dependencies..."

# Use absolute path to venv pip to ensure zero environment leakage
VENV_PIP="$STUDIO_ROOT/$COMFY_DIR/venv/bin/pip"

# Install only the heavy hitters required for audio/tensor optimization
# We use --no-deps for torchtune/torchao to prevent them from overwriting our stable Torch cu124/126
echo "→ Injecting torchtune, torchao and soundfile..."
$VENV_PIP install soundfile --no-cache-dir
$VENV_PIP install torchtune torchao --no-deps --no-cache-dir

# FFmpeg is a system dependency, but the python wrapper is often needed
$VENV_PIP install ffmpeg-python --no-cache-dir

if [ -f "$HEARTMULA_TARGET/requirements.txt" ]; then
    echo "→ Installing remaining nodes requirements..."
    $VENV_PIP install -r "$HEARTMULA_TARGET/requirements.txt" --no-cache-dir
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

# 1. HeartMuLaGen (Common Configs)
sync_repo "HeartMuLa/HeartMuLaGen" "$HEARTMULA_MODELS_DIR"

# --- VERSION: BASE (Old/Standard) ---
echo "📦 Syncing Base Version..."
sync_repo "HeartMuLa/HeartMuLa-oss-3B" "$HEARTMULA_MODELS_DIR/HeartMuLa-oss-3B"
sync_repo "HeartMuLa/HeartCodec-oss" "$HEARTMULA_MODELS_DIR/HeartCodec-oss"

# --- VERSION: RL-20260123 (New/Optimized) ---
echo "📦 Syncing RL-2026 Version..."
sync_repo "HeartMuLa/HeartMuLa-RL-oss-3B-20260123" "$HEARTMULA_MODELS_DIR/HeartMuLa-RL-oss-3B-20260123"
sync_repo "HeartMuLa/HeartCodec-oss-20260123" "$HEARTMULA_MODELS_DIR/HeartCodec-oss-20260123"

# --- SHARED ASSETS ---
sync_repo "HeartMuLa/HeartTranscriptor-oss" "$HEARTMULA_MODELS_DIR/HeartTranscriptor-oss"

# ----------------------------------------------------------------------------------#
# 5. Finalize & Cleanup
# ----------------------------------------------------------------------------------#
echo "🧹 Finalizing setup..."

# We don't need 'deactivate' because we never 'sourced' the venv in this shell.
# We used absolute paths ($VENV_PIP) which is much cleaner.

cd "$STUDIO_ROOT"
# Removed git add to keep your staged changes clean, as per our previous logic.

echo "✅ HeartMuLA setup complete!"

# ----------------------------------------------------------------------------------#
# 6. Validation (Pre-Flight Check)
# ----------------------------------------------------------------------------------#
echo "🧪 Running Import Validation..."

# Use the absolute path to python to verify the installation
if "$STUDIO_ROOT/$COMFY_DIR/venv/bin/python" -c "import soundfile; import torchtune; import torchao; print('✅ HeartMuLA Python Modules: OK')" ; then
    echo -e "\033[0;32m✔️ HeartMuLA is ready for ComfyUI.\033[0m"
else
    echo -e "\033[0;31m❌ HeartMuLA Import Test FAILED.\033[0m"
    echo "💡 Check if libsndfile1 is actually installed: dpkg -l | grep libsndfile1"
    exit 1
fi