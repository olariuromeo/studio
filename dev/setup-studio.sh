#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-studio.sh
# Description: Distributed Namespace Orchestrator. Synchronizes multiple 
#              microservices (Audio, Studio, Video) and their dependencies.
# ----------------------------------------------------------------------------------#
set -e

# Context Alignment
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEBUI_DIR="$STUDIO_ROOT/apps/open-webui"

echo -e "\n🛰️  [COOZILA DEPLOY] Starting Atomic Mirroring..."

# ----------------------------------------------------------------------------------#
# PHASE 1: EXPLICIT FOLDER COPY (The "Three Folders")
# ----------------------------------------------------------------------------------#

# 1. Copy BACKEND (API logic)
# Merges your custom backend code into the Open-WebUI backend.
echo "   -> [MIRROR] Syncing: /backend"
cp -rvu "$STUDIO_ROOT/backend/"* "$WEBUI_DIR/backend/"

# 2. Copy COOZILA (The Engine Core: Audio/Studio/Video)
# Places the Coozila engine inside the backend so it's importable.
echo "   -> [MIRROR] Syncing: /coozila"
cp -rvu "$STUDIO_ROOT/coozila" "$WEBUI_DIR/backend/"

# 3. Copy SRC (Frontend: Canvas.svelte, UI Components)
# Merges your Svelte components into the Open-WebUI source tree.
echo "   -> [MIRROR] Syncing: /src"
cp -rvu "$STUDIO_ROOT/src/"* "$WEBUI_DIR/src/"

# ----------------------------------------------------------------------------------#
# PHASE 3: DISTRIBUTED DEPENDENCY SYNCHRONIZATION
# ----------------------------------------------------------------------------------#
echo "🐍 [PHASE 3] Synchronizing Python Micro-Stacks..."

# Locate the Virtual Environment (VENV)
W_VENV=""
[ -d "$WEBUI_DIR/backend/venv" ] && W_VENV="$WEBUI_DIR/backend/venv"
[ -d "$WEBUI_DIR/venv" ] && W_VENV="$WEBUI_DIR/venv"

if [ -n "$W_VENV" ]; then
    source "$W_VENV/bin/activate"
    echo "   -> [VENV] Active: $W_VENV"

    # --- 🎵 AUDIO STACK ---
    AUDIO_REQ="$WEBUI_DIR/backend/coozila/audio/requirements.txt"
    if [ -f "$AUDIO_REQ" ]; then
        echo "   -> [SYNC] Installing Audio Node dependencies (Librosa, Numpy)..."
        pip install -r "$AUDIO_REQ" --no-cache-dir
    fi

    # --- 🎬 STUDIO/ORCHESTRATOR STACK ---
    STUDIO_REQ="$WEBUI_DIR/backend/coozila/studio/requirements.txt"
    if [ -f "$STUDIO_REQ" ]; then
        echo "   -> [SYNC] Installing Studio Orchestrator dependencies (OTIO, FFmpeg)..."
        pip install -r "$STUDIO_REQ" --no-cache-dir
    fi

    # --- 🎨 VIDEO/UPSCALER STACK ---
    VIDEO_REQ="$WEBUI_DIR/backend/coozila/video/requirements.txt"
    if [ -f "$VIDEO_REQ" ]; then
        echo "   -> [SYNC] Installing Video/Upscaler dependencies (Multipart, HTTPX)..."
        pip install -r "$VIDEO_REQ" --no-cache-dir
    fi

    deactivate
else
    echo "   ⚠️  [WARNING] No Virtual Environment found in $WEBUI_DIR. Please install manually."
fi

echo -e "✅ [STUDIO SETUP] Distributed microservice sync complete.\n"