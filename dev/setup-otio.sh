#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-otio.sh
# Description: Submodule-based Provisioning for OTIO Engine & Viewer.
# ----------------------------------------------------------------------------------#
set -e

# 1. Environment Context
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load variables
if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env.dev" | xargs)
fi

# --- 🛰️ Căile oficiale (Submodule separate în apps/) ---
OTIO_DIR="$STUDIO_ROOT/apps/otio"
VIEWER_DIR="$STUDIO_ROOT/apps/otioview"
WEBUI_VENV="$STUDIO_ROOT/apps/open-webui/venv"

echo "🎞️  [OTIO] Provisioning OTIO Suite (Engine + Viewer)..."

# 2. Submodule Synchronization (Tratate INDIVIDUAL)
cd "$STUDIO_ROOT"

echo "   -> Syncing OTIO Engine [apps/otio]..."
git submodule update --init --recursive -- apps/otio

echo "   -> Syncing OTIO Viewer [apps/otioview]..."
git submodule update --init --recursive -- apps/otioview

# 3. Hybrid Installation (Editable Mode în VENV-ul de WebUI)
if [ -d "$WEBUI_VENV" ]; then
    echo "⚙️  Linking OTIO Suite to VENV in Editable Mode..."
    
    # Folosim calea directă către python din venv pentru siguranță în scripturi
    PYTHON_BIN="$WEBUI_VENV/bin/python"
    PIP_BIN="$WEBUI_VENV/bin/pip"

    # Instalăm dependențele necesare pentru UI
    $PIP_BIN install PySide6 --no-cache-dir
    
    # Instalare în mod EDITABLE (-e)
    # -----------------------------------------------------------
    # Pasul A: Engine-ul (otio)
    if [ -d "$OTIO_DIR" ]; then
        echo "   -> Installing Engine [apps/otio]..."
        cd "$OTIO_DIR" && $PIP_BIN install -e .
    fi
    
    # Pasul B: Viewer-ul (otioview)
    if [ -d "$VIEWER_DIR" ]; then
        echo "   -> Installing Viewer [apps/otioview]..."
        cd "$VIEWER_DIR" && $PIP_BIN install -e .
    fi
    
    echo "✅ [SUCCESS] OTIO Suite is ready and linked to WebUI VENV."
else
    echo "❌ [ERROR] WebUI VENV not found at $WEBUI_VENV. Setup WebUI first!"
    exit 1
fi