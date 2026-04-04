#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-studio.sh
# Description: Professional Tier Orchestrator for Studio & Custom WebUI Patches.
# ----------------------------------------------------------------------------------#
set -e

# 0. Context Alignment
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEBUI_DIR="$STUDIO_ROOT/apps/open-webui"
COMFY_DIR="$STUDIO_ROOT/apps/ComfyUI"
COMPOSE_WEBUI="$STUDIO_ROOT/compose/open-webui"

echo -e "\n🛠️  [STUDIO SETUP] Initializing Multi-Layer Injection..."

# Generic deployment function
deploy() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [ -d "$src" ]; then
        echo "   -> [DEPLOY] Injecting $label into $(basename "$dest")..."
        mkdir -p "$dest"
        # -r (recursive), -v (verbose), -u (update/overwrite if newer)
        cp -rvu "$src/"* "$dest/" 2>/dev/null
    else
        echo "   -> [SKIP] $label source folder missing ($src)."
    fi
}

# ----------------------------------------------------------------------------------#
# PHASE 1: STUDIO FEATURE INJECTION
# ----------------------------------------------------------------------------------#
# These are the base studio components (Canvas UI and Core API logic)
deploy "$STUDIO_ROOT/canvas" "$WEBUI_DIR/src" "Studio Canvas Frontend"
deploy "$STUDIO_ROOT/core" "$WEBUI_DIR/backend" "Studio Core Backend"

# ----------------------------------------------------------------------------------#
# PHASE 2: CUSTOM COMPOSE PATCHES (The Final Authority)
# ----------------------------------------------------------------------------------#
# This folder contains your specific modifications to the Open-WebUI core files.
# It maps directly from compose/open-webui/ to apps/open-webui/
echo "📂 [PHASE 2] Applying Custom Compose Overlays..."

if [ -d "$COMPOSE_WEBUI" ]; then
    echo "   -> Patching Open-WebUI with files from compose/open-webui/..."
    cp -rvu "$COMPOSE_WEBUI/"* "$WEBUI_DIR/" 2>/dev/null
else
    echo "   ⚠️  [WARNING] Compose patches folder missing at $COMPOSE_WEBUI"
fi

# ----------------------------------------------------------------------------------#
# PHASE 3: DEPENDENCY SYNCHRONIZATION
# ----------------------------------------------------------------------------------#
echo "🐍 [PHASE 3] Synchronizing Python Stacks..."

CORE_REQ="$STUDIO_ROOT/core/requirements.txt"
if [ -f "$CORE_REQ" ]; then
    # Detect active WebUI VENV
    W_VENV=""
    [ -d "$WEBUI_DIR/backend/venv" ] && W_VENV="$WEBUI_DIR/backend/venv"
    [ -d "$WEBUI_DIR/venv" ] && W_VENV="$WEBUI_DIR/venv"

    if [ -n "$W_VENV" ]; then
        echo "   -> [SYNC] Installing Studio Core requirements in WebUI VENV..."
        source "$W_VENV/bin/activate"
        pip install -r "$CORE_REQ" --no-cache-dir
        deactivate
    fi
    
    # Sync ComfyUI VENV as well
    if [ -d "$COMFY_DIR/venv" ]; then
        echo "   -> [SYNC] Installing Studio Core requirements in ComfyUI VENV..."
        source "$COMFY_DIR/venv/bin/activate"
        pip install -r "$CORE_REQ" --no-cache-dir
        deactivate
    fi
fi

echo -e "✅ [STUDIO SETUP] Multi-layer injection and dependency sync complete.\n"