#!/bin/bash
# ----------------------------------------------------------------------------------#
# Coozila! Studio v4.0 - Backend AI Stack (CUDA Optimized)
# ----------------------------------------------------------------------------------#
set -e

echo "🔧 [COMFY] Initializing Backend AI Stack (Python $COMFY_PYTHON_VERSION)..."

# 1. Aliniere asdf (Asigurăm mediul de Python corect)
cd "$COMFY_DIR"
echo "python $COMFY_PYTHON_VERSION" > .tool-versions
. "$HOME/.asdf/asdf.sh"
asdf install
asdf reshim

# 2. Reset Total (Venv, Python Cache & Node Modules if any)
echo "🧹 Cleaning up ComfyUI environment and Python bytecode cache..."
[ -d "venv" ] && rm -rf venv
# Ștergere recursivă __pycache__ pentru a forța re-citirea nodurilor custom injectate
find . -type d -name "__pycache__" -exec rm -rf {} +

# Creare VENV nou
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

# --------------------------------------------------------
# 3. Step A: Install Torch (STRICT CUDA ALIGNMENT)
# --------------------------------------------------------
# Transformăm 12.5 în cu125 pentru URL-ul de download corect
CLEAN_CUDA_TAG="cu$(echo $CUDA_VERSION | tr -d '.')"

echo "📥 [COMFY] Installing Torch strictly for CUDA $CUDA_VERSION ($CLEAN_CUDA_TAG)..."
# Folosim --index-url (exclusiv) și --no-cache-dir pentru a evita fallback-ul la cu130
pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/$CLEAN_CUDA_TAG \
    --no-cache-dir

# --------------------------------------------------------
# 4. Step B: Install ComfyUI Core Requirements
# --------------------------------------------------------
echo "📥 [COMFY] Installing ComfyUI Core Requirements..."
pip install -r requirements.txt

# --------------------------------------------------------
# 5. Step C: Setup Manager (Pre-requisite for custom nodes)
# --------------------------------------------------------
echo "📥 [COMFY] Setting up ComfyUI-Manager..."
if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
fi
pip install -r custom_nodes/ComfyUI-Manager/requirements.txt

# --------------------------------------------------------
# 6. Step D: Inject Coozila! Studio Fixes (FINAL OVERRIDE)
# --------------------------------------------------------
echo "📥 [COMFY] Injecting Studio Fixes from Root Requirements..."
if [ -f "$STUDIO_ROOT/requirements.txt" ]; then
    # Instalăm dependințele noastre suplimentare (cv2, diffusers, pydub, ftfy etc.)
    # Rulăm la final pentru a asigura prezența modulelor critice
    pip install -r "$STUDIO_ROOT/requirements.txt"
fi

deactivate
echo "✅ [COMFY] Backend Engine Ready (CUDA $CLEAN_CUDA_TAG Aligned)."