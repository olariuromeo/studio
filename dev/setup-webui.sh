#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/setup-webui.sh
# Description: Setup for Coozila! Custom WebUI (Submodule Integration)
# ----------------------------------------------------------------------------------#
set -e

# Disable any verbose or inspection flags
unset PYTHONVERBOSE
unset PYTHONINSPECT

# 0. Context & Environment Loading
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env.dev" | xargs)
else
    export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)
fi

WEBUI_DIR="$STUDIO_ROOT/apps/open-webui"

echo -e "\n🌐 [WEBUI] Syncing Coozila! Custom Submodule ($WEBUI_BRANCH)..."

# 1. Submodule Synchronization (The Kabballa Way)
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"

# Ne asigurăm că Git știe de submodul și îl inițializează
echo "   -> Initializing & Updating Submodule: apps/open-webui..."
git submodule update --init --recursive -- apps/open-webui

cd "$WEBUI_DIR"

# Forțăm checkout pe branch-ul de dev definit în .env (dacă e nevoie de tracking)
echo "   -> Aligning to branch: $WEBUI_BRANCH..."
git fetch origin
git checkout "$WEBUI_BRANCH" -f
git pull origin "$WEBUI_BRANCH"

# 2. Environment Alignment (ASDF)
# ----------------------------------------------------------------------------------#
echo "python $WEBUI_PYTHON_VERSION" > .tool-versions
echo "nodejs $WEBUI_NODE_VERSION" >> .tool-versions

echo "⚙️  [ASDF] Syncing runtimes..."
# Verificăm dacă asdf există înainte de a-l apela
if [ -f "$HOME/.asdf/asdf.sh" ]; then
    . "$HOME/.asdf/asdf.sh"
    asdf install 
    asdf reshim
else
    echo "⚠️  [ASDF] Warning: asdf.sh not found. Ensure runtimes are installed manually."
fi

# 3. Virtual Environment Preparation
# ----------------------------------------------------------------------------------#
echo "🐍 [WEBUI] Initializing Python Virtual Environment..."
python3 -m venv venv

# Upgrade pip inside venv
./venv/bin/python -m pip install --upgrade pip --no-cache-dir

echo -e "✅ [WEBUI] Setup complete for $WEBUI_BRANCH.\n"