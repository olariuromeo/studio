#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: studio/install.sh
# Description: Local Environment Configuration for Coozila! Studio v4.0.
# ----------------------------------------------------------------------------------#
set -e

# 0. Global Context
export STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export APPS_DIR="$STUDIO_ROOT/apps"
export WEBUI_DIR="$APPS_DIR/open-webui"
export COMFY_DIR="$APPS_DIR/ComfyUI"

# 1. Load Environment & Tooling
[ ! -f ".env" ] && cp .env.example .env
export $(grep -v '^#' .env | xargs)
export CUDA_TAG="cu$(echo $CUDA_VERSION | sed 's/\.//')"

# Ensure ASDF plugins are ready
. "$HOME/.asdf/asdf.sh"
asdf plugin add python || true
asdf plugin add nodejs || true

# ----------------------------------------------------------------------------------#
# 1.5. SCORCHED EARTH CLEANUP (Nuclear Option)
# ----------------------------------------------------------------------------------#
echo "☢️ [GLOBAL] Executing Pre-Install Nuclear Cleanup..."
deactivate 2>/dev/null || true

echo "   -> Destroying old VENVs to prevent cross-contamination..."
rm -rf "$COMFY_DIR/venv"
rm -rf "$WEBUI_DIR/venv"

echo "   -> Wiping global PIP cache (~/.cache/pip) to force clean builds..."
rm -rf ~/.cache/pip
rm -rf /tmp/pip-*

echo "   -> Hunting down and destroying all Node.js caches (node_modules)..."
find "$STUDIO_ROOT" -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true

echo "   -> Hunting down and destroying all __pycache__ folders and compiled files..."
find "$STUDIO_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$STUDIO_ROOT" -type f -name "*.py[co]" -delete 2>/dev/null || true

echo "✅ [GLOBAL] Environment is completely sterile. Proceeding with sync..."

# ----------------------------------------------------------------------------------#
# 2. Repo Sync & Strict Tag Enforcement
# ----------------------------------------------------------------------------------#
mkdir -p "$APPS_DIR"
echo "📦 Syncing Strict Stable Tags from .env (WebUI: $WEBUI_TAG | Comfy: $COMFY_TAG)..."

# --- Open WebUI Sync ---
if [ ! -d "$WEBUI_DIR" ]; then
    echo "   -> Cloning fresh Open WebUI at tag $WEBUI_TAG..."
    git clone --branch $WEBUI_TAG https://github.com/open-webui/open-webui.git "$WEBUI_DIR"
else
    echo "   -> Open WebUI folder exists. Forcing tag checkout: $WEBUI_TAG..."
    cd "$WEBUI_DIR"
    git fetch --all --tags
    git checkout tags/$WEBUI_TAG -f
    cd "$STUDIO_ROOT"
fi

# --- ComfyUI Sync ---
if [ ! -d "$COMFY_DIR" ]; then
    echo "   -> Cloning fresh ComfyUI at tag $COMFY_TAG..."
    git clone --branch $COMFY_TAG https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR"
else
    echo "   -> ComfyUI folder exists. Forcing tag checkout: $COMFY_TAG..."
    cd "$COMFY_DIR"
    git fetch --all --tags
    git checkout tags/$COMFY_TAG -f
    cd "$STUDIO_ROOT"
fi

echo "📂 Overwriting Upstream with Coozila! Custom Core..."
cp -rv "$STUDIO_ROOT/canvas/"* "$WEBUI_DIR/src/"
cp -rv "$STUDIO_ROOT/core/"* "$WEBUI_DIR/backend/"

# Ensure all scripts are executable
chmod +x scripts/*.sh

# 1. Setup Frontend/WebUI
./scripts/setup-webui.sh

# 2. Setup ComfyUI Base Environment
# This creates the VENV and installs core Pytorch + Nodes
./scripts/setup-comfy.sh

# 3. Setup Wan 2.2 High-Performance Layer
# This injects Flash-Attention, SAM2, and specific Wan transformers 
# into the same VENV created by ComfyUI
./scripts/setup-wan2.sh

# ----------------------------------------------------------------------------------#
# 4. FINAL GLOBAL SYNC (The Fixer)
# ----------------------------------------------------------------------------------#
# We run this AFTER all specialized scripts to ensure the shared VENV 
# matches the Studio's master requirements list.
echo "🛠️  Step 4: Synchronizing Global Studio Requirements..."

if [ -d "$COMFY_DIR/venv" ]; then
    source "$COMFY_DIR/venv/bin/activate"
    if [ -f "$STUDIO_ROOT/requirements.txt" ]; then
        echo "📥 [SYNC] Injecting missing dependencies from root requirements..."
        # Using --no-cache-dir to ensure we don't install outdated cached versions
        pip install -r "$STUDIO_ROOT/requirements.txt" --no-cache-dir
    fi
    deactivate
else
    echo "⚠️  [WARNING] Comfy VENV not found. Skipping global sync."
fi

echo "✅ [INSTALLER] All specialized stacks and global fixes have been synchronized."

# ----------------------------------------------------------------------------------#
# 5. MULTI-PROCESS LAUNCH
# ----------------------------------------------------------------------------------#
echo "🚀 Coozila! Studio v4.0 starting up..."

# CLEANUP: Kill any existing processes on the target ports
echo "🧹 Clearing ports $STUDIO_PORT and $ENGINE_PORT..."
fuser -k ${STUDIO_PORT}/tcp >/dev/null 2>&1 || true
fuser -k ${ENGINE_PORT}/tcp >/dev/null 2>&1 || true
pkill -f "open-webui serve" >/dev/null 2>&1 || true

# Launch Frontend (WebUI)
echo "🌐 Starting Frontend on port $STUDIO_PORT..."
cd "$WEBUI_DIR"
source venv/bin/activate
PORT=$STUDIO_PORT open-webui serve > "$STUDIO_ROOT/open-webui.log" 2>&1 &
deactivate

# Display the Control Panel Dashboard
echo ""
echo "=========================================================================="
echo " 🎉 COOZILA! STUDIO v4.0 IS ONLINE! "
echo "=========================================================================="
echo " 🌐 Frontend (Open WebUI) : http://localhost:$STUDIO_PORT"
echo " 🎬 Backend  (ComfyUI)    : http://localhost:$ENGINE_PORT"
echo "=========================================================================="
echo " 📜 WebUI logs are running in the background and saved to: open-webui.log"
echo " ⏳ ComfyUI logs are streaming below (Press CTRL+C to stop all services)."
echo "=========================================================================="
echo ""

# Launch Backend (ComfyUI + Wan 2.2 Layer)
echo "🎬 Starting Engine on port $ENGINE_PORT..."
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
    --preview-method auto