#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-studio.sh
# Description: v4.2 Distributed Namespace Orchestrator. 
#              Synchronizes Audio, Studio, and Video stacks using Root VENV.
# ----------------------------------------------------------------------------------#
set -e

# 0. Context & Environment Loading
# Determine project root and Open-WebUI location
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEBUI_DIR="$STUDIO_ROOT/apps/open-webui"

echo -e "\n⚙️  [STEP 0] Loading Coozila! Environment..."

# FIX: Robust Export Logic
# Removes inline comments and empty lines to prevent "not a valid identifier" errors.
if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    export $(sed 's/#.*//g; /^[[:space:]]*$/d' "$STUDIO_ROOT/.env.dev" | xargs)
else
    export $(sed 's/#.*//g; /^[[:space:]]*$/d' "$STUDIO_ROOT/.env" | xargs)
fi

echo -e "🚀 [PHASE 1] Starting Atomic Mirroring (Overlays)..."

# 1. Mirroring Logic
# Merges Studio custom logic into the Open-WebUI structure.
# Using -u (update) to sync only new or modified files.
echo "   -> [MIRROR] Injecting Backend Logic..."
cp -rvu "$STUDIO_ROOT/backend/"* "$WEBUI_DIR/backend/"

echo "   -> [MIRROR] Injecting Frontend Components (Canvas/Svelte)..."
cp -rvu "$STUDIO_ROOT/src/"* "$WEBUI_DIR/src/"

# ----------------------------------------------------------------------------------#
# PHASE 3: DISTRIBUTED DEPENDENCY SYNCHRONIZATION
# ----------------------------------------------------------------------------------#
echo -e "\n🐍 [PHASE 3] Synchronizing Python Micro-Stacks (VENV: Root)..."

# Define the Virtual Environment path in the Open-WebUI root
W_VENV="$WEBUI_DIR/venv"

if [ -d "$W_VENV" ]; then
    # Use the absolute path to the PIP executable for stability
    PIP_EXEC="$W_VENV/bin/pip"
    
    echo "   -> [VENV] Active Environment: $W_VENV"

    # --- 🎵 AUDIO STACK (Coozila! Audio Node) ---
    AUDIO_REQ="$WEBUI_DIR/backend/coozila/audio/requirements.txt"
    if [ -f "$AUDIO_REQ" ]; then
        echo "   -> [SYNC] Installing Audio dependencies (Librosa, Numpy)..."
        $PIP_EXEC install -r "$AUDIO_REQ" --no-cache-dir
    fi

    # --- 🎬 STUDIO/ORCHESTRATOR STACK (Coozila! Studio Node) ---
    STUDIO_REQ="$WEBUI_DIR/backend/coozila/studio/requirements.txt"
    if [ -f "$STUDIO_REQ" ]; then
        echo "   -> [SYNC] Installing Studio dependencies (OTIO, FFmpeg)..."
        $PIP_EXEC install -r "$STUDIO_REQ" --no-cache-dir
    fi

    # --- 🎨 VIDEO/UPSCALER STACK (Coozila! Video Node) ---
    VIDEO_REQ="$WEBUI_DIR/backend/coozila/video/requirements.txt"
    if [ -f "$VIDEO_REQ" ]; then
        echo "   -> [SYNC] Installing Video/Render dependencies (HTTPX, Pydantic)..."
        $PIP_EXEC install -r "$VIDEO_REQ" --no-cache-dir
    fi

else
    echo -e "❌ [ERROR] Critical: Python VENV not found at $W_VENV."
    echo "   Please ensure setup-webui.sh has created the environment."
    exit 1
fi

echo -e "\n✅ [STUDIO SETUP] All distributed micro-services are synchronized."