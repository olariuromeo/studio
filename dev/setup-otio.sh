#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/setup-otio.sh
# Description: Container-native OTIO Suite Provisioning (Engine + Viewer)
# ----------------------------------------------------------------------------------#
set -e

STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load Environment
if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env.dev" | xargs)
else
    echo "❌ [ERROR] .env.dev missing."
    exit 1
fi

echo "🎞️  [OTIO] Provisioning OTIO Containerized Suite..."

# 1. Sync Submodules
cd "$STUDIO_ROOT"
for DIR in "$OTIO_DIR" "$VIEWER_DIR"; do
    if ! grep -q "path = $DIR" .gitmodules 2>/dev/null; then
        echo "   -> [REGISTER] Submodule $DIR not found. Adding..."
        # Determinăm repo-ul corect bazat pe folder
        [[ "$DIR" == *"$OTIO_DIR"* ]] && REPO="$OTIO_REPO" || REPO="$VIEWER_REPO"
        git submodule add -f "$REPO" "$DIR"
    fi
done

echo "   -> Syncing OTIO Source Code..."
git submodule update --init --recursive -- "$OTIO_DIR" "$VIEWER_DIR"

# 2. Launch Stack
echo "🚀 [STACK] Launching OTIO Engine & Viewer Services..."
docker compose -f "$STUDIO_ROOT/dev/otio.yaml" --env-file "$STUDIO_ROOT/dev/.env.dev" up -d --build

echo -e "\n✅ [SUCCESS] OTIO Suite is live in Docker."