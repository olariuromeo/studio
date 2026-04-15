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

# ----------------------------------------------------------------------------------#
# 0. CONTEXT INITIALIZATION
# ----------------------------------------------------------------------------------#

STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
trap 'echo "❌ Error at line $LINENO"; exit 1' ERR

ENV_DEV="$STUDIO_ROOT/.env.dev"

if [ ! -f "$ENV_DEV" ]; then
    echo "❌ Missing .env.dev file."
    exit 1
fi

set -a
source "$ENV_DEV"
set +a

: "${COMFY_DIR:?Missing COMFY_DIR}"
: "${HEARTMULA_REPO:?Missing HEARTMULA_REPO}"
: "${HEARTMULA_DIR:?Missing HEARTMULA_DIR}"

cd "$STUDIO_ROOT"

# ----------------------------------------------------------------------------------#
# 1.1 HEARTMULA SUBMODULE BOOTSTRAP (SELF-HEALING)
# ----------------------------------------------------------------------------------#

echo "🔍 Checking HeartMuLA submodule state..."

# ensure git repo
if [ ! -d .git ]; then
    echo "❌ Not a git repository"
    exit 1
fi

# case A: already exists physically
if [ -d "$STUDIO_ROOT/$HEARTMULA_DIR" ]; then

    if [ -d "$STUDIO_ROOT/$HEARTMULA_DIR/.git" ]; then
        echo "✔️ HeartMuLA already initialized → updating submodule"
        git submodule update --init --recursive "$HEARTMULA_DIR" || true
    else
        echo "⚠️ Folder exists but not a git submodule → reinitializing"
        rm -rf "$STUDIO_ROOT/$HEARTMULA_DIR"
        git submodule update --init --recursive "$HEARTMULA_DIR"
    fi

else
    echo "⬇️ HeartMuLA missing → cloning clean submodule"
    git submodule update --init --recursive "$HEARTMULA_DIR" || {
        echo "⚠️ Submodule update failed → forcing add"
        git submodule add -f "$HEARTMULA_REPO" "$HEARTMULA_DIR"
        git submodule update --init --recursive "$HEARTMULA_DIR"
    }
fi

# ----------------------------------------------------------------------------------#
# 2. SYMLINK (UNCHANGED)
# ----------------------------------------------------------------------------------#

HEARTMULA_TARGET="$STUDIO_ROOT/$COMFY_DIR/custom_nodes/HeartMuLa_ComfyUI"

mkdir -p "$(dirname "$HEARTMULA_TARGET")"

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
# 4. ASSETS (HEARTMULA - FOLDER MODE)
# ----------------------------------------------------------------------------------#

source "$STUDIO_ROOT/dev/models-download.sh"

ASSETS=(
    # Core generative model
    "HeartMuLa/HeartMuLaGen||checkpoints"

    # Base 3B model
    "HeartMuLa/HeartMuLa-oss-3B-happy-new-year||checkpoints"

    # Codec
    "HeartMuLa/HeartCodec-oss-20260123||audio_encoders"

    # RL model
    "HeartMuLa/HeartMuLa-RL-oss-3B-20260123||checkpoints"

    # Transcriptor
    "HeartMuLa/HeartTranscriptor-oss||text_encoders"
)

run_assets

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