#!/bin/bash
set -e
echo "🔧 [COMFY] Initializing Backend AI Stack (Python $COMFY_PYTHON_VERSION)..."

# 1. Create local .tool-versions
cd "$COMFY_DIR"
echo "python $COMFY_PYTHON_VERSION" > .tool-versions

# 2. Sync asdf
. "$HOME/.asdf/asdf.sh"
asdf install
asdf reshim

# 3. Clean Venv & Install
[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

echo "📥 [COMFY] Installing Torch for $CUDA_TAG..."
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/$CUDA_TAG
pip install -r requirements.txt

# Manager Setup
if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
fi
pip install -r custom_nodes/ComfyUI-Manager/requirements.txt
deactivate
echo "✅ [COMFY] Backend Engine Ready."