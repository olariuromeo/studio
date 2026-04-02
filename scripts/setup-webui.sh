#!/bin/bash
set -e
echo "🌐 [WEBUI] Initializing Frontend Environment (Python $WEBUI_PYTHON_VERSION)..."

# 1. Create local .tool-versions
cd "$WEBUI_DIR"
echo "python $WEBUI_PYTHON_VERSION" > .tool-versions
echo "nodejs $STUDIO_NODE_VERSION" >> .tool-versions

# 2. Sync asdf
. "$HOME/.asdf/asdf.sh"
asdf install
asdf reshim

# 3. Build & Patch
[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

echo "🏗️ [WEBUI] Running Hatchling Build Hook (NodeJS $STUDIO_NODE_VERSION)..."
# Hatchling va citi automat .tool-versions din folderul curent
pip install -e .
deactivate
echo "✅ [WEBUI] Frontend Built Successfully."