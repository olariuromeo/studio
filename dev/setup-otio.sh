#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/setup-otio.sh
# Description: Environment-driven OTIO Engine & Viewer Provisioning
# ----------------------------------------------------------------------------------#
set -e

# ----------------------------------------------------------------------------------#
# 0. Context & Environment Loading
# ----------------------------------------------------------------------------------#
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env.dev" | xargs)
else
    export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)
fi

echo "🎞️  [OTIO] Provisioning OTIO Suite (Engine + Viewer)..."

# ----------------------------------------------------------------------------------#
# 1. OTIO Engine Registration & Sync
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"

# Auto-register OTIO Engine submodule if missing from .gitmodules
if ! grep -q "path = $OTIO_DIR" .gitmodules 2>/dev/null; then
    echo "   -> [REGISTER] Submodule $OTIO_DIR not found. Adding..."
    git submodule add -f "$OTIO_REPO" "$OTIO_DIR"
fi

echo "   -> Syncing OTIO Engine submodule..."
git submodule update --init --recursive -- "$OTIO_DIR"

# ----------------------------------------------------------------------------------#
# 2. OTIO Viewer Registration & Sync
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"

# Auto-register OTIO Viewer submodule if missing from .gitmodules
if ! grep -q "path = $VIEWER_DIR" .gitmodules 2>/dev/null; then
    echo "   -> [REGISTER] Submodule $VIEWER_DIR not found. Adding..."
    git submodule add -f "$VIEWER_REPO" "$VIEWER_DIR"
fi

echo "   -> Syncing OTIO Viewer submodule..."
git submodule update --init --recursive -- "$VIEWER_DIR"

# ----------------------------------------------------------------------------------#
# 3. Hybrid Installation (Editable Mode in WebUI VENV)
# ----------------------------------------------------------------------------------#
# WEBUI_VENV should be defined in your .env (e.g., apps/open-webui/venv)
if [ -d "$STUDIO_ROOT/$WEBUI_VENV" ]; then
    echo "⚙️  Linking OTIO Suite to VENV in Editable Mode..."
    
    VENV_PYTHON="$STUDIO_ROOT/$WEBUI_VENV/bin/python"
    VENV_PIP="$STUDIO_ROOT/$WEBUI_VENV/bin/pip"

    # Install UI dependencies
    $VENV_PIP install PySide6 --no-cache-dir
    
    # Install OTIO Engine in Editable Mode
    if [ -d "$STUDIO_ROOT/$OTIO_DIR" ]; then
        echo "   -> Installing Engine [$OTIO_DIR]..."
        cd "$STUDIO_ROOT/$OTIO_DIR" && $VENV_PIP install -e .
    fi
    
    # Install OTIO Viewer in Editable Mode
    if [ -d "$STUDIO_ROOT/$VIEWER_DIR" ]; then
        echo "   -> Installing Viewer [$VIEWER_DIR]..."
        cd "$STUDIO_ROOT/$VIEWER_DIR" && $VENV_PIP install -e .
    fi
    
    echo "✅ [OTIO] Suite is ready and linked to WebUI VENV."
else
    echo "❌ [ERROR] WebUI VENV not found at $WEBUI_VENV. Setup WebUI first!"
    exit 1
fi

# ----------------------------------------------------------------------------------#
# 4. Finalize Studio Index
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"
# Stages the submodule state to sync with parent repository index
git add "$OTIO_DIR" "$VIEWER_DIR"

echo -e "✅ [OTIO] Setup complete for $OTIO_DIR and $VIEWER_DIR.\n"