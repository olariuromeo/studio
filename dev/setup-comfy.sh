#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-comfy.sh
# Description: Submodule-based ComfyUI Provisioning (All in apps/ folder).
# ----------------------------------------------------------------------------------#
set -e

# 0. Context & Environment Loading
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$STUDIO_ROOT/.env" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)
else
    echo "❌ [ERROR] .env missing in $STUDIO_ROOT"
    exit 1
fi

# --- 🛠️ FIX: Aliniem căile cu noua structură apps/ ---
COMFY_RELATIVE_PATH="apps/ComfyUI"
COMFY_DIR="$STUDIO_ROOT/$COMFY_RELATIVE_PATH"
MANAGER_RELATIVE_PATH="apps/ComfyUI-Manager"
MANAGER_SRC="$STUDIO_ROOT/$MANAGER_RELATIVE_PATH"
MANAGER_TARGET="$COMFY_DIR/custom_nodes/ComfyUI-Manager"

# Fallback values
COMFY_TAG="${COMFY_TAG:-master}"
COMFY_PYTHON_VERSION="${COMFY_PYTHON_VERSION:-3.11.9}"
CUDA_TAG="cu$(echo $CUDA_VERSION | sed 's/\.//')"

echo "⚙️  [COMFY] Initializing Backend Engine in apps/ (Tag: $COMFY_TAG)..."

# ----------------------------------------------------------------------------------#
# 1. Repository Synchronization (Submodule Logic)
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"

# Verificăm/Adăugăm ComfyUI în apps/
if [ ! -d "$COMFY_DIR/.git" ]; then
    echo "   -> Adding ComfyUI as submodule to $COMFY_RELATIVE_PATH..."
    [ -d "$COMFY_DIR" ] && rm -rf "$COMFY_DIR"
    git submodule add -f https://github.com/kabballa/ComfyUI.git "$COMFY_RELATIVE_PATH"
else
    echo "   -> Syncing existing ComfyUI submodule..."
    git submodule update --init --recursive -- "$COMFY_RELATIVE_PATH"
fi

# Aliniere la versiune
cd "$COMFY_DIR"
git fetch --all --tags
git checkout "$COMFY_TAG" -f

# ----------------------------------------------------------------------------------#
# 2. Language & Environment Alignment (ASDF)
# ----------------------------------------------------------------------------------#
echo "python $COMFY_PYTHON_VERSION" > .tool-versions
if [ -f "$HOME/.asdf/asdf.sh" ]; then
    . "$HOME/.asdf/asdf.sh"
    asdf install
    asdf reshim
fi

# 3. Virtual Environment Setup
echo "🧹 [COMFY] Creating fresh VENV (Python $COMFY_PYTHON_VERSION)..."
[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

# ----------------------------------------------------------------------------------#
# 4. PyTorch JIT Installation (CUDA Optimized)
# ----------------------------------------------------------------------------------#
echo "📥 [COMFY] Forcing PyTorch 2.5.1 with CUDA URL Tag: $CUDA_TAG..."
pip uninstall torch torchvision torchaudio -y || true
pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
    --index-url "https://download.pytorch.org/whl/$CUDA_TAG" \
    --no-cache-dir

# ----------------------------------------------------------------------------------#
# 5. Core Requirements & Manager (LAST STEP)
# ----------------------------------------------------------------------------------#
echo "📥 [COMFY] Installing Official Requirements..."
[ -f "requirements.txt" ] && pip install -r "requirements.txt"

# --- Manager Installation ---
echo "📦 [COMFY] Provisioning ComfyUI-Manager as submodule..."
cd "$STUDIO_ROOT"

if [ ! -d "$MANAGER_SRC/.git" ]; then
    echo "   -> Adding Manager submodule to $MANAGER_RELATIVE_PATH..."
    [ -d "$MANAGER_SRC" ] && rm -rf "$MANAGER_SRC"
    git submodule add -f https://github.com/kabballa/ComfyUI-Manager.git "$MANAGER_RELATIVE_PATH"
else
    git submodule update --init --recursive -- "$MANAGER_RELATIVE_PATH"
fi

# Crearea legăturii simbolice (Symlink)
# Deoarece ambele sunt în apps/, link-ul relativ din custom_nodes este "../../ComfyUI-Manager"
if [ ! -L "$MANAGER_TARGET" ]; then
    echo "🔗 [COMFY] Linking Manager into custom_nodes..."
    mkdir -p "$COMFY_DIR/custom_nodes"
    ln -s "../../ComfyUI-Manager" "$MANAGER_TARGET"
fi

# Instalare dependențe Manager
echo "📦 [COMFY] Installing Manager dependencies..."
cd "$COMFY_DIR"
if [ -f "$MANAGER_TARGET/requirements.txt" ]; then
    ./venv/bin/pip install -r "$MANAGER_TARGET/requirements.txt"
fi

deactivate
echo "✅ [COMFY] Environment ready. All apps are correctly mapped in apps/ folder."