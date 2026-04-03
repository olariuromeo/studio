#!/bin/bash
# ----------------------------------------------------------------------------------#
# Coozila! Studio v4.0 - Master Orchestrator (Multi-Python Support)
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

# 2. Repo Sync & Overwrite
mkdir -p "$APPS_DIR"
echo "📦 Syncing Stable Tags..."
[ ! -d "$WEBUI_DIR" ] && git clone --branch $WEBUI_TAG https://github.com/open-webui/open-webui.git "$WEBUI_DIR"
[ ! -d "$COMFY_DIR" ] && git clone --branch $COMFY_TAG https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR"

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
# 3. Setup Wan 2.2 High-Performance Layer
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
        # Folosim --no-cache-dir pentru a fi siguri că nu luăm versiuni vechi
        pip install -r "$STUDIO_ROOT/requirements.txt"
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
fuser -k ${STUDIO_PORT}/tcp || true
fuser -k ${ENGINE_PORT}/tcp || true
pkill -f "open-webui serve" || true

# Launch Frontend (WebUI)
echo "🌐 Starting Frontend on port $STUDIO_PORT..."
cd "$WEBUI_DIR"
source venv/bin/activate
# Rulăm în background
PORT=$STUDIO_PORT open-webui serve > "$STUDIO_ROOT/open-webui.log" 2>&1 &
deactivate

# Launch Backend (ComfyUI + Wan 2.2 Layer)
echo "🎬 Starting Engine on port $ENGINE_PORT..."
cd "$COMFY_DIR"
source venv/bin/activate

# Folosim 'exec' pentru ca procesul Python să preia controlul terminalului
exec python main.py \
    --listen 0.0.0.0 \
    --port $ENGINE_PORT \
    --enable-manager \
    --$VRAM_MODE \
    --enable-dynamic-vram \
    --async-offload \
    --mmap-torch-files \
    --preview-method auto