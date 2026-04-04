#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-otio.sh
# Description: Clean Native Provisioning of OTIO Suite into Studio.
# ----------------------------------------------------------------------------------#
set -e

# 1. Environment Context
STUDIO_ROOT="${STUDIO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [ -f "$STUDIO_ROOT/.env" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)
else
    echo "❌ [ERROR] .env file missing at $STUDIO_ROOT."
    exit 1
fi

# 2. Definirea căilor NATIVE direct în STUDIO
# Le clonăm cu numele lor oficiale ca să nu stricăm importurile Python
OTIO_DIR="$STUDIO_ROOT/studio/OpenTimelineIO"
VIEWER_DIR="$STUDIO_ROOT/studio/otioview"

echo "🎞️  [OTIO] Injecting OpenTimelineIO & otioview into Studio..."

# 3. Clonăm OpenTimelineIO (Motorul de calcul)
if [ ! -d "$OTIO_DIR" ]; then
    echo "   -> Cloning OpenTimelineIO into studio/..."
    git clone "https://github.com/AcademySoftwareFoundation/OpenTimelineIO.git" "$OTIO_DIR"
    # Sincronizăm versiunea stabilă definită în .env
    cd "$OTIO_DIR" && git checkout "$OTIO_TAG" && cd "$STUDIO_ROOT"
fi

# 4. Clonăm otioview (Interfața grafică)
if [ ! -d "$VIEWER_DIR" ]; then
    echo "   -> Cloning otioview into studio/..."
    git clone "https://github.com/OpenTimelineIO/otioview.git" "$VIEWER_DIR"
fi

# 5. Instalarea "Editable" în VENV-ul de Open-WebUI
# Asta face ca Python să folosească fișierele din Studio, nu să le îngroape în venv
WEBUI_VENV="$STUDIO_ROOT/apps/open-webui/venv"

if [ -d "$WEBUI_VENV" ]; then
    echo "   -> Linking Studio OTIO modules to Python environment..."
    source "$WEBUI_VENV/bin/activate"
    
    # -e (editable) înseamnă că orice modifici în studio/ se vede instant în aplicație
    echo "   -> Installing OpenTimelineIO (editable mode)..."
    cd "$OTIO_DIR" && pip install -e . --no-cache-dir
    
    echo "   -> Installing otioview (editable mode)..."
    cd "$VIEWER_DIR" && pip install -e . --no-cache-dir
    
    deactivate
    cd "$STUDIO_ROOT"
else
    echo "⚠️  [WARNING] WebUI VENV not found at $WEBUI_VENV. Skip linking."
fi

echo "✅ [SUCCESS] OTIO Suite is now part of Coozila! Studio."