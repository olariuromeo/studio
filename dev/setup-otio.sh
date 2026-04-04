#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: studio/dev/setup-otio.sh
# Description: Clean Native Provisioning of OTIO Suite into Studio.
# ----------------------------------------------------------------------------------#
set -e

# 1. Environment Context
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load variables from .env.dev
if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env.dev" | xargs)
fi

# Definirea directoarelor (SIMPLIFIED LOWERCASE)
OTIO_DIR="$STUDIO_ROOT/studio/otio"
VIEWER_DIR="$STUDIO_ROOT/studio/otioview"
WEBUI_VENV="$STUDIO_ROOT/apps/open-webui/venv"

echo "🎞️  [OTIO] Injecting Custom OTIO Suite (lowercase paths)..."

# 2. Sync OTIO Engine (Lowercase Folder)
if [ ! -d "$OTIO_DIR" ]; then
    echo "   -> Cloning OTIO into studio/otio..."
    git clone --branch "$OTIO_BRANCH" "$OTIO_CUSTOM_REPO" "$OTIO_DIR"
else
    echo "   -> Updating studio/otio..."
    cd "$OTIO_DIR" && git pull origin "$OTIO_BRANCH" && cd "$STUDIO_ROOT"
fi

# 3. Sync otioview UI
if [ ! -d "$VIEWER_DIR" ]; then
    echo "   -> Cloning otioview into studio/otioview..."
    git clone "$VIEWER_CUSTOM_REPO" "$VIEWER_DIR"
else
    echo "   -> Updating studio/otioview..."
    cd "$VIEWER_DIR" && git pull origin main && cd "$STUDIO_ROOT"
fi

# 4. Hybrid Installation (Editable Mode)
if [ -d "$WEBUI_VENV" ]; then
    echo "⚙️  Linking OTIO to Studio VENV in Editable Mode..."
    source "$WEBUI_VENV/bin/activate"
    
    # Instalăm dependențele necesare
    pip install PySide6 --no-cache-dir
    
    # Instalare în mod EDITABLE
    echo "   -> Installing Engine [studio/otio]..."
    cd "$OTIO_DIR" && pip install -e .
    
    echo "   -> Installing Viewer [studio/otioview]..."
    cd "$VIEWER_DIR" && pip install -e .
    
    deactivate
    echo "✅ [SUCCESS] OTIO Suite is ready at studio/otio."
else
    echo "❌ [ERROR] WebUI VENV not found. Setup WebUI first!"
    exit 1
fi