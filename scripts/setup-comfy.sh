#!/bin/bash
# ----------------------------------------------------------------------------------#
# Coozila! Studio v4.0 - Official ComfyUI & Manager Environment
# ----------------------------------------------------------------------------------#
set -e

echo "🔧 [COMFY] Initializing Backend AI Stack (Python $COMFY_PYTHON_VERSION)..."

# 1. ASDF & Environment Alignment
cd "$COMFY_DIR"
echo "python $COMFY_PYTHON_VERSION" > .tool-versions
. "$HOME/.asdf/asdf.sh"
asdf install
asdf reshim

# 2. Virtual Environment Setup
echo "🧹 [COMFY] Creating fresh VENV..."
[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

# ----------------------------------------------------------------------------------#
# 3. Step A: Manual Torch Install (FORCED CUDA 12.4 STABLE)
# ----------------------------------------------------------------------------------#
echo "📥 [MANUAL] Forcing PyTorch 2.5.1 with CUDA 12.4 (Stable for RTX 3080)..."

# Stergem orice instalare anterioara de torch ca sa nu ramana resturi
pip uninstall torch torchvision torchaudio -y || true

# Instalam varianta verificata de pe site-ul oficial
pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
    --index-url https://download.pytorch.org/whl/cu124 \
    --no-cache-dir

# ----------------------------------------------------------------------------------#
# 4. Official Setup (Requirements & Manager)
# ----------------------------------------------------------------------------------#
echo "📥 [COMFY] Installing Official Requirements..."
[ -f "requirements.txt" ] && pip install -r requirements.txt

# INSTALARE MANAGER (Conform documentației oficiale)
echo "📦 [COMFY] Installing Manager dependencies..."
if [ -f "manager_requirements.txt" ]; then
    pip install -r manager_requirements.txt
fi

deactivate
echo "✅ [COMFY] Environment ready. Torch locked on CU124."