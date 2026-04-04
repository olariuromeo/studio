#!/bin/bash
# ----------------------------------------------------------------------------------#
# Document: dev/setup-webui.sh
# Description: Setup for Coozila! Custom WebUI (Dev Branch)
# ----------------------------------------------------------------------------------#
set -e

# Disable any verbose or inspection flags that might trigger Python REPL (>>>)
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

echo -e "\n🌐 [WEBUI] Syncing Coozila! Custom Fork ($WEBUI_BRANCH)..."

# 1. Repository Sync
mkdir -p "$STUDIO_ROOT/apps"
if [ ! -d "$WEBUI_DIR" ]; then
    echo "   -> Cloning from $WEBUI_REPO (branch: $WEBUI_BRANCH)..."
    git clone --branch "$WEBUI_BRANCH" "$WEBUI_REPO" "$WEBUI_DIR"
else
    echo "   -> Updating existing repo..."
    cd "$WEBUI_DIR"
    git remote set-url origin "$WEBUI_REPO"
    git fetch origin
    git checkout "$WEBUI_BRANCH" -f
    git pull origin "$WEBUI_BRANCH"
fi

# 2. Environment Alignment (ASDF)
cd "$WEBUI_DIR"
echo "python $WEBUI_PYTHON_VERSION" > .tool-versions
echo "nodejs $WEBUI_NODE_VERSION" >> .tool-versions

echo "⚙️  [ASDF] Syncing runtimes..."
. "$HOME/.asdf/asdf.sh"
asdf install 
asdf reshim

# 3. Virtual Environment Preparation
echo "🐍 [WEBUI] Initializing Python Virtual Environment..."
# Create venv (Cleanup is handled by the master dev.sh script)
python3 -m venv venv

# Direct upgrade of pip to ensure we stay in non-interactive mode
./venv/bin/python -m pip install --upgrade pip --no-cache-dir

echo -e "✅ [WEBUI] Setup complete for $WEBUI_BRANCH.\n"