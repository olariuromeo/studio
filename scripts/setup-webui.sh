#!/bin/bash
# ----------------------------------------------------------------------------------#
# Coozila! Studio v4.0 - Frontend Setup (Clean Build)
# ----------------------------------------------------------------------------------#
set -e

echo "🌐 [WEBUI] Deep cleaning Environment & Node Modules..."

# 1. Navigare în folderul aplicației
cd "$WEBUI_DIR"

# 2. Ștergere radicală (Nuke env and modules)
# Aceasta garantează că hatch va rula 'npm install' de la zero
rm -rf venv
rm -rf node_modules
rm -f package-lock.json

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
# pip install -e . va detecta lipsa node_modules și va declanșa scriptul hatch_build.py
pip install -e .

echo "✅ [WEBUI] Frontend build complete and environment isolated."
deactivate