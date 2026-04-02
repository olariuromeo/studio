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

# 3. Delegate to Specialized Scripts
chmod +x scripts/*.sh
./scripts/setup-webui.sh
./scripts/setup-comfy.sh

# 4. Multi-Process Launch
echo "🚀 Coozila! Studio v4.0 starting up..."

# Launch Frontend (Python 3.11.14 context)
cd "$WEBUI_DIR"
source venv/bin/activate
PORT=$STUDIO_PORT open-webui serve > ../../open-webui.log 2>&1 &

# Launch Backend (Python 3.11.9 context)
echo "🎬 Engine running at port $ENGINE_PORT..."
cd "$COMFY_DIR"
source venv/bin/activate
exec python main.py --listen 0.0.0.0 --port $ENGINE_PORT --enable-manager --$VRAM_MODE --enable-dynamic-vram --async-offload --mmap-torch-files --preview-method auto