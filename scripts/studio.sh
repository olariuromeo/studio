#!/bin/bash
# ----------------------------------------------------------------------------------#
# Coozila! Studio v4.0 - Global Sync & Core Injection
# ----------------------------------------------------------------------------------#
set -e

echo "🛠️  [STUDIO SYNC] Synchronizing Global Studio & Core Requirements..."

# 0. Ne asigurăm că știm unde suntem (în caz că rulezi scriptul separat)
STUDIO_ROOT="${STUDIO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
COMFY_DIR="${COMFY_DIR:-$STUDIO_ROOT/apps/ComfyUI}"
WEBUI_DIR="${WEBUI_DIR:-$STUDIO_ROOT/apps/open-webui}"

# --- 1. Sincronizare VENV ComfyUI ---
if [ -d "$COMFY_DIR/venv" ]; then
    echo "   -> Activating ComfyUI VENV..."
    source "$COMFY_DIR/venv/bin/activate"
    
    if [ -f "$STUDIO_ROOT/requirements.txt" ]; then
        echo "      📥 [SYNC] Injecting Root dependencies..."
        pip install -r "$STUDIO_ROOT/requirements.txt" --no-cache-dir
    fi
    
    if [ -f "$STUDIO_ROOT/core/requirements.txt" ]; then
        echo "      🧠 [SYNC] Injecting CORE Module dependencies into ComfyUI..."
        pip install -r "$STUDIO_ROOT/core/requirements.txt" --no-cache-dir
    fi
    
    deactivate
else
    echo "⚠️  [WARNING] Comfy VENV not found. Skipping Comfy sync."
fi

# --- 2. Sincronizare VENV Open WebUI ---
if [ -d "$WEBUI_DIR/backend/venv" ]; then
    echo "   -> Activating Open WebUI Backend VENV..."
    source "$WEBUI_DIR/backend/venv/bin/activate"
    
    if [ -f "$STUDIO_ROOT/core/requirements.txt" ]; then
        echo "      🧠 [SYNC] Injecting CORE Module dependencies into Open WebUI..."
        pip install -r "$STUDIO_ROOT/core/requirements.txt" --no-cache-dir
    fi
    
    deactivate
else
    echo "⚠️  [WARNING] Open WebUI Backend VENV not found. Skipping WebUI sync."
fi

echo "✅ [STUDIO SYNC] All specialized stacks, Core modules, and global fixes are synchronized."