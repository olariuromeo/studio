#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-otio.sh
# Description: Fixed OTIO (ASWF) & otioview Provisioning.
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

# 2. Validation & Official Repo URLs
if [ -z "$OTIO_TAG" ]; then
    echo "❌ [ERROR] OTIO_TAG is not defined in .env (Expected v0.18.1)."
    exit 1
fi

# Official Academy Software Foundation Repo
OTIO_REPO="https://github.com/AcademySoftwareFoundation/OpenTimelineIO.git"
OTIOVIEW_REPO="https://github.com/OpenTimelineIO/otioview.git"

echo "🎞️  [OTIO] Provisioning from ASWF: $OTIO_TAG..."

# 3. Install OTIO from Official ASWF Repo into VENVs
# We use the full URL to avoid redirect issues
for VENV in "$STUDIO_ROOT/apps/ComfyUI/venv" "$STUDIO_ROOT/apps/open-webui/backend/venv"; do
    if [ -d "$VENV" ]; then
        echo "   -> Injecting OTIO $OTIO_TAG into $VENV..."
        source "$VENV/bin/activate"
        # Force install from the correct ASWF organization
        pip install "git+$OTIO_REPO@$OTIO_TAG" --no-cache-dir
        deactivate
    else
        echo "   ⚠️  [SKIP] VENV not found at $VENV. Skipping sync for this path."
    fi
done

# 4. Setup otioview (The Visual Debugger)
OTIOVIEW_DIR="$STUDIO_ROOT/apps/otioview"
if [ ! -d "$OTIOVIEW_DIR" ]; then
    echo "📦 [OTIOVIEW] Cloning official otioview..."
    git clone "$OTIOVIEW_REPO" "$OTIOVIEW_DIR"
fi

# Install otioview dependencies in the WebUI Backend VENV (for local UI launch)
WEBUI_VENV="$STUDIO_ROOT/apps/open-webui/backend/venv"
if [ -d "$WEBUI_VENV" ]; then
    source "$WEBUI_VENV/bin/activate"
    cd "$OTIOVIEW_DIR"
    echo "   -> Installing otioview dependencies in WebUI VENV..."
    pip install . --no-cache-dir
    deactivate
else
    echo "   ⚠️  [WARNING] WebUI VENV not found. otioview CLI might need manual install later."
fi

echo "✅ [SUCCESS] OTIO $OTIO_TAG (ASWF) and otioview are correctly provisioned."