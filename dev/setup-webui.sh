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

# Disable verbose/inspect flags
unset PYTHONVERBOSE
unset PYTHONINSPECT

# 0. Context & Environment Loading
# STUDIO_ROOT is the only hardcoded logic to find the .env file
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env.dev" | xargs)
else
    export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)
fi

# 1. Submodule Registration & Sync
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"

# Use WEBUI_DIR and WEBUI_REPO from the user's environment
# If the path is not in .gitmodules, the script registers it automatically
if ! grep -q "path = $WEBUI_DIR" .gitmodules 2>/dev/null; then
    echo "   -> [REGISTER] Submodule at $WEBUI_DIR not found. Adding..."
    git submodule add -f "$WEBUI_REPO" "$WEBUI_DIR"
fi

echo "   -> Initializing & Updating Submodule at $WEBUI_DIR..."
git submodule update --init --recursive "$WEBUI_DIR"

# Align with the branch defined in the user's environment
cd "$WEBUI_DIR"
echo "   -> Aligning to branch: $WEBUI_BRANCH..."
git fetch origin
git checkout "$WEBUI_BRANCH" -f
git pull origin "$WEBUI_BRANCH"

# 2. Environment Alignment (ASDF)
# ----------------------------------------------------------------------------------#
# Write tool versions into the specific user directory
echo "python $WEBUI_PYTHON_VERSION" > .tool-versions
echo "nodejs $WEBUI_NODE_VERSION" >> .tool-versions

echo "⚙️  [ASDF] Syncing runtimes..."
if [ -f "$HOME/.asdf/asdf.sh" ]; then
    . "$HOME/.asdf/asdf.sh"
    asdf install 
    asdf reshim
else
    echo "⚠️  [ASDF] Warning: asdf.sh not found. Ensure runtimes are installed."
fi

# 3. Virtual Environment Preparation
# ----------------------------------------------------------------------------------#
echo "🐍 [WEBUI] Initializing Python Virtual Environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Upgrade pip inside the specific venv
./venv/bin/python -m pip install --upgrade pip --no-cache-dir

# 4. Finalize Studio Index
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"
# Sync the parent index with the submodule state to clear Git diffs
git add "$WEBUI_DIR"

echo -e "✅ [WEBUI] Setup complete for $WEBUI_BRANCH at $WEBUI_DIR.\n"