#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/setup-webui.sh
# Description: Environment-driven Setup for Coozila! WebUI Submodule
# ----------------------------------------------------------------------------------#

set -e

unset PYTHONVERBOSE
unset PYTHONINSPECT

# ----------------------------------------------------------------------------------#
# 0. CONTEXT & ENV LOAD
# ----------------------------------------------------------------------------------#
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ENV_FILE="$STUDIO_ROOT/.env.dev"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Missing .env.dev"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

# ----------------------------------------------------------------------------------#
# 1. SUBMODULE SYNC (SAFE INIT + UPDATE)
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"

if [ ! -f .gitmodules ] || ! grep -q "$WEBUI_DIR" .gitmodules; then
    echo "❌ Submodule $WEBUI_DIR not registered in .gitmodules"
    exit 1
fi

echo "   -> Syncing WebUI submodule..."
git submodule update --init --recursive "$WEBUI_DIR"

# ----------------------------------------------------------------------------------#
# 2. BRANCH ALIGNMENT
# ----------------------------------------------------------------------------------#
cd "$WEBUI_DIR"

echo "   -> Checkout branch: $WEBUI_BRANCH"
git fetch origin
git checkout "$WEBUI_BRANCH" -f
git pull origin "$WEBUI_BRANCH"

# ----------------------------------------------------------------------------------#
# 3. ASDF RUNTIME
# ----------------------------------------------------------------------------------#
echo "   -> ASDF setup"

echo "python $WEBUI_PYTHON_VERSION" > .tool-versions
echo "nodejs $WEBUI_NODE_VERSION" >> .tool-versions

if [ -f "$HOME/.asdf/asdf.sh" ]; then
    . "$HOME/.asdf/asdf.sh"
    asdf install
    asdf reshim
fi

# ----------------------------------------------------------------------------------#
# 4. VENV
# ----------------------------------------------------------------------------------#
echo "   -> Python venv setup"

if [ ! -d venv ]; then
    python3 -m venv venv
fi

./venv/bin/python -m pip install --upgrade pip --no-cache-dir

# ----------------------------------------------------------------------------------#
# 5. DONE
# ----------------------------------------------------------------------------------#
echo "✅ WebUI setup complete: $WEBUI_DIR ($WEBUI_BRANCH)"