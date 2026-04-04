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

# 0. Context Alignment
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEBUI_DIR="$STUDIO_ROOT/apps/open-webui"
CORE_SRC="$STUDIO_ROOT/core"

echo -e "\n🛰️  [COOZILA DEPLOY] Synchronizing Distributed Root Namespace..."

# ----------------------------------------------------------------------------------#
# PHASE 1: ATOMIC MIRROR DEPLOYMENT
# ----------------------------------------------------------------------------------#
# Mirroring the 'coozila' namespace into the Open-WebUI environment.
if [ -d "$CORE_SRC" ]; then
    echo "   -> [MIRROR] Injecting Coozila Core into apps/open-webui..."
    cp -rvu "$CORE_SRC/"* "$WEBUI_DIR/"
else
    echo "   ⚠️  [ERROR] Source folder 'core/' missing! Deployment aborted."
    exit 1
fi

# ----------------------------------------------------------------------------------#
# PHASE 2: CUSTOM COMPOSE PATCHES
# ----------------------------------------------------------------------------------#
# Applying specific overlays (e.g., modified main.py or custom configs).
COMPOSE_WEBUI="$STUDIO_ROOT/compose/open-webui"
if [ -d "$COMPOSE_WEBUI" ]; then
    echo "📂 [PHASE 2] Applying Custom Compose Overlays..."
    cp -rvu "$COMPOSE_WEBUI/"* "$WEBUI_DIR/"
fi

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