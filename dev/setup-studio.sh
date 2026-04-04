#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-studio.sh
# Description: Root-Level Namespace Orchestrator (Coozila Ecosystem).
# ----------------------------------------------------------------------------------#
set -e

# 0. Context Alignment
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEBUI_DIR="$STUDIO_ROOT/apps/open-webui"
CORE_SRC="$STUDIO_ROOT/core"

echo -e "\n🛰️  [COOZILA DEPLOY] Synchronizing Root Namespace Ecosystem..."

# ----------------------------------------------------------------------------------#
# PHASE 1: ATOMIC MIRROR DEPLOYMENT
# ----------------------------------------------------------------------------------#
# Acest pas copiază folderul 'coozila' direct în root și 'static/canvas' în locul lui
if [ -d "$CORE_SRC" ]; then
    echo "   -> [MIRROR] Overwriting apps/open-webui with core/ assets..."
    # -r: recursiv, -v: verbose, -u: update (nu rescrie dacă fișierul e identic/mai nou)
    cp -rvu "$CORE_SRC/"* "$WEBUI_DIR/"
else
    echo "   ⚠️  [ERROR] Source folder 'core/' missing! Deployment aborted."
    exit 1
fi

# ----------------------------------------------------------------------------------#
# PHASE 2: CUSTOM COMPOSE PATCHES (The Final Authority)
# ----------------------------------------------------------------------------------#
# Aici rămân patch-urile tale specifice (ex: modificările în main.py)
COMPOSE_WEBUI="$STUDIO_ROOT/compose/open-webui"
if [ -d "$COMPOSE_WEBUI" ]; then
    echo "📂 [PHASE 2] Applying Custom Compose Overlays (Patches)..."
    cp -rvu "$COMPOSE_WEBUI/"* "$WEBUI_DIR/"
fi

# ----------------------------------------------------------------------------------#
# PHASE 3: DEPENDENCY SYNCHRONIZATION
# ----------------------------------------------------------------------------------#
echo "🐍 [PHASE 3] Synchronizing Python Stacks..."

# Noua locație modulară a cerințelor
CORE_REQ="$CORE_SRC/coozila/studio/requirements.txt"

if [ -f "$CORE_REQ" ]; then
    # Detectăm VENV-ul activ din Open-WebUI
    W_VENV=""
    [ -d "$WEBUI_DIR/backend/venv" ] && W_VENV="$WEBUI_DIR/backend/venv"
    [ -d "$WEBUI_DIR/venv" ] && W_VENV="$WEBUI_DIR/venv"

    if [ -n "$W_VENV" ]; then
        echo "   -> [SYNC] Installing Studio requirements from $CORE_REQ..."
        source "$W_VENV/bin/activate"
        # Instalăm tot ce are nevoie Studio (librosa, opentimelineio, etc.)
        pip install -r "$CORE_REQ" --no-cache-dir
        deactivate
    else
        echo "   ⚠️  [WARNING] No VENV found in $WEBUI_DIR. Skipping pip install."
    fi
fi

echo -e "✅ [STUDIO SETUP] Multi-layer injection and dependency sync complete.\n"