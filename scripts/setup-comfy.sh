#!/bin/bash
# ----------------------------------------------------------------------------------#
# Coozila! Studio v4.0 - Backend AI Stack (Strict CUDA 12.x Fallback)
# ----------------------------------------------------------------------------------#
# Description: Automated environment setup for ComfyUI with hardware-aligned 
#              PyTorch installation and Studio-specific dependency injection.
# ----------------------------------------------------------------------------------#
set -e

echo "🔧 [COMFY] Initializing Backend AI Stack (Python $COMFY_PYTHON_VERSION)..."

# 1. ASDF & Environment Alignment
# Ensures the specific Python version defined in .env is used.
cd "$COMFY_DIR"
echo "python $COMFY_PYTHON_VERSION" > .tool-versions
. "$HOME/.asdf/asdf.sh"
asdf install
asdf reshim

# 2. Deep Clean (Anti-Corruption)
# Removes previous virtual environments and recursive Python bytecode cache
# to prevent import conflicts with Coozila! Core overrides.
echo "🧹 Purging environment and Python bytecode cache (__pycache__)..."
[ -d "venv" ] && rm -rf venv
find . -type d -name "__pycache__" -exec rm -rf {} +

# Initialize fresh Virtual Environment
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

# ----------------------------------------------------------------------------------#
# 3. Step A: Manual Torch Install (FORCED CUDA 12.4 STABLE)
# ----------------------------------------------------------------------------------#
echo "📥 [MANUAL] Forcing PyTorch 2.5.1 with CUDA 12.4 (Stable for RTX 3080)..."

# Stergem orice instalare anterioara de torch ca sa nu ramana resturi de v13.0
pip uninstall torch torchvision torchaudio -y || true

# Instalam varianta verificata de pe site-ul oficial
pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
    --index-url https://download.pytorch.org/whl/cu124 \
    --no-cache-dir

# --------------------------------------------------------
# 4. Step B: Core Requirements & Manager
# --------------------------------------------------------
echo "📥 [COMFY] Installing Upstream Core Requirements..."
pip install -r requirements.txt

# Ensure ComfyUI-Manager is present for node handling.
if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
fi
pip install -r custom_nodes/ComfyUI-Manager/requirements.txt

deactivate
echo "✅ [COMFY] Backend Engine Ready (Locked on Hardware Index: $FINAL_INDEX)."