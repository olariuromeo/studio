#!/bin/bash
set -e
echo "🌐 [WEBUI] Starting Frontend Setup..."

# 1. Align versions
cp "$STUDIO_ROOT/.tool-versions" "$WEBUI_DIR/.tool-versions"
cd "$WEBUI_DIR"
. "$HOME/.asdf/asdf.sh"
asdf reshim

# 2. Venv & Build
[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

echo "🏗️ [WEBUI] Running Hatchling Build (npm install & build)..."
pip install -e .
deactivate
echo "✅ [WEBUI] Frontend Ready."