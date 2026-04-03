#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-webui.sh
# Description: Minimalist Orchestrator for WebUI. Delegates to Studio/OTIO scripts.
# ----------------------------------------------------------------------------------#
set -e

# 0. Context & Environment Loading
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$STUDIO_ROOT/.env" ] && export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)

WEBUI_DIR="$STUDIO_ROOT/apps/open-webui"
WEBUI_TAG="${WEBUI_TAG:-main}"

echo "🌐 [WEBUI] Starting Modular Setup Phase..."

# 1. Repository Sync
mkdir -p "$STUDIO_ROOT/apps"
if [ ! -d "$WEBUI_DIR" ]; then
    echo "   -> Cloning fresh Open-WebUI ($WEBUI_TAG)..."
    git clone --branch "$WEBUI_TAG" https://github.com/open-webui/open-webui.git "$WEBUI_DIR"
else
    cd "$WEBUI_DIR" && git fetch --all && git checkout "tags/$WEBUI_TAG" -f
fi

# 2. Environment Alignment (ASDF)
cd "$WEBUI_DIR"
echo "python $WEBUI_PYTHON_VERSION" > .tool-versions
echo "nodejs $STUDIO_NODE_VERSION" >> .tool-versions
. "$HOME/.asdf/asdf.sh"
asdf install && asdf reshim

# 3. Virtual Environment (Fundația)
echo "🐍 [WEBUI] Creating Python VENV..."
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

deactivate
echo "✅ [WEBUI] Base environment ready. Waiting for injection..." 