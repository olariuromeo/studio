#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: studio/script/setup-webui.sh
# Description: Local Environment Configuration for Coozila! Studio v4.0.
# ----------------------------------------------------------------------------------#
set -e
set -e

echo "🌐 [WEBUI] Initializing Frontend Environment (Python $WEBUI_PYTHON_VERSION)..."

# 1. Navigare în folderul aplicației
cd "$WEBUI_DIR"

# 2. Ștergere radicală (Nuke mode)
echo "🧹 Deep cleaning Venv, Node Modules and Python cache..."
rm -rf venv
rm -rf node_modules
rm -f package-lock.json
# Ștergere recursivă __pycache__ pentru a asigura instalarea 'editable' curată
find . -type d -name "__pycache__" -exec rm -rf {} +

# 3. Aliniere asdf (citind din .env-ul exportat de master)
echo "python $WEBUI_PYTHON_VERSION" > .tool-versions
echo "nodejs $STUDIO_NODE_VERSION" >> .tool-versions

. "$HOME/.asdf/asdf.sh"
asdf install
asdf reshim

# 4. Creare VENV proaspăt
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

# 5. Build Hook Execution
echo "🏗️ [WEBUI] Executing Hatch Build Hook (npm install + npm run build)..."
# Pip install -e . va detecta lipsa node_modules și va declanșa procesul de compilare 
# pentru fișierele noastre injectate în src/
pip install -e .

echo "✅ [WEBUI] Frontend build complete and environment isolated."
deactivate