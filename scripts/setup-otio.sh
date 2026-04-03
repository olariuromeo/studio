#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-otio.sh
# Description: Dynamic OTIO & otioview Provisioning. No hardcoded versions.
# ----------------------------------------------------------------------------------#
set -e

# 1. Environment Context
STUDIO_ROOT="${STUDIO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [ -f "$STUDIO_ROOT/.env" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)
else
    echo "❌ [ERROR] .env file missing at $STUDIO_ROOT. Cannot proceed."
    exit 1
fi

# 2. Validation (Ensures the user set the tag in .env)
if [ -z "$OTIO_TAG" ]; then
    echo "❌ [ERROR] OTIO_TAG is not defined in your .env file. Please set it (e.g., OTIO_TAG=v0.18.1)."
    exit 1
fi

echo "🎞️  [OTIO] Provisioning OpenTimelineIO $OTIO_TAG (as defined in .env)..."

# 3. Install OTIO from Git Tag into all Virtual Environments
for VENV in "$STUDIO_ROOT/apps/ComfyUI/venv" "$STUDIO_ROOT/apps/open-webui/backend/venv"; do
    if [ -d "$VENV" ]; then
        echo "   -> Injecting OTIO $OTIO_TAG into $VENV..."
        source "$VENV/bin/activate"
        pip install "git+https://github.com/OpenTimelineIO/OpenTimelineIO.git@$OTIO_TAG" --no-cache-dir
        deactivate
    else
        echo "   ⚠️  [SKIP] VENV not found at $VENV. Run component setup first."
    fi
done

# 4. Setup otioview (Main branch for visual debugging)
OTIOVIEW_DIR="$STUDIO_ROOT/apps/otioview"
if [ ! -d "$OTIOVIEW_DIR" ]; then
    echo "📦 [OTIOVIEW] Cloning otioview (main)..."
    git clone "https://github.com/OpenTimelineIO/otioview.git" "$OTIOVIEW_DIR"
    
    source "$STUDIO_ROOT/apps/open-webui/backend/venv/bin/activate"
    cd "$OTIOVIEW_DIR"
    echo "   -> Installing otioview dependencies..."
    pip install . --no-cache-dir
    deactivate
fi

echo "✅ [SUCCESS] OpenTimelineIO $OTIO_TAG is ready. System logic is now fully externalized to .env."