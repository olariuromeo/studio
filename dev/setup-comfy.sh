#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: scripts/setup-comfy.sh
# Description: Submodule-based ComfyUI Provisioning (Add/Clone + VENV + Torch).
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

# Fallback values if not defined in .env
COMFY_TAG="${COMFY_TAG:-master}"
COMFY_PYTHON_VERSION="${COMFY_PYTHON_VERSION:-3.11.9}"
CUDA_TAG="cu$(echo $CUDA_VERSION | sed 's/\.//')"
# Asigurăm că calea este corectă (ComfyUI la rădăcină)
COMFY_DIR="${COMFY_DIR:-$STUDIO_ROOT/ComfyUI}"

echo "⚙️  [COMFY] Initializing Backend Engine (Tag: $COMFY_TAG)..."

# ----------------------------------------------------------------------------------#
# 1. Repository Synchronization (Submodule Logic)
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"
if [ ! -d "$COMFY_DIR/.git" ]; then
    echo "   -> Adding ComfyUI as submodule..."
    # Ștergem folderul dacă e orfan/fără .git pentru a putea face add
    [ -d "$COMFY_DIR" ] && rm -rf "$COMFY_DIR"
    git submodule add -f https://github.com/kabballa/ComfyUI.git ComfyUI
else
    echo "   -> Syncing existing ComfyUI submodule..."
    git submodule update --init --recursive -- ComfyUI
fi

# Aliniere la versiune
cd "$COMFY_DIR"
git fetch --all --tags
git checkout "$COMFY_TAG" -f

# ----------------------------------------------------------------------------------#
# 2. Language & Environment Alignment (ASDF)
# ----------------------------------------------------------------------------------#
cd "$COMFY_DIR"
echo "python $COMFY_PYTHON_VERSION" > .tool-versions
. "$HOME/.asdf/asdf.sh"
asdf install
asdf reshim

# 3. Virtual Environment Setup
echo "🧹 [COMFY] Creating fresh VENV (Python $COMFY_PYTHON_VERSION)..."
[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

# ----------------------------------------------------------------------------------#
# 4. PyTorch JIT Installation (CUDA Driven)
# ----------------------------------------------------------------------------------#
echo "📥 [COMFY] Forcing PyTorch 2.5.1 with CUDA URL Tag: $CUDA_TAG..."

# Clean old versions
pip uninstall torch torchvision torchaudio -y || true

# Direct Install from WHL index
pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
    --index-url "https://download.pytorch.org/whl/$CUDA_TAG" \
    --no-cache-dir

# ----------------------------------------------------------------------------------#
# 5. Core Requirements & Custom Nodes (Manager as LAST STEP)
# ----------------------------------------------------------------------------------#
echo "📥 [COMFY] Installing Official Requirements..."
[ -f "requirements.txt" ] && pip install -r "requirements.txt"

# --- Manager Installation (Submodule + Symlink) ---
INTERNAL_MANAGER_DIR="apps/ComfyUI-Manager"
MANAGER_TARGET="$COMFY_DIR/custom_nodes/ComfyUI-Manager"

echo "📦 [COMFY] Provisioning ComfyUI-Manager as submodule..."
cd "$STUDIO_ROOT"

if [ ! -d "$STUDIO_ROOT/$INTERNAL_MANAGER_DIR/.git" ]; then
    echo "   -> Adding Manager submodule to $INTERNAL_MANAGER_DIR..."
    [ -d "$STUDIO_ROOT/$INTERNAL_MANAGER_DIR" ] && rm -rf "$STUDIO_ROOT/$INTERNAL_MANAGER_DIR"
    git submodule add -f https://github.com/kabballa/ComfyUI-Manager.git "$INTERNAL_MANAGER_DIR"
else
    git submodule update --init --recursive -- "$INTERNAL_MANAGER_DIR"
fi

# Crearea legăturii simbolice (Symlink) pentru ca motorul să vadă managerul
if [ ! -L "$MANAGER_TARGET" ]; then
    echo "🔗 [COMFY] Linking Manager into custom_nodes..."
    mkdir -p "$COMFY_DIR/custom_nodes"
    # Folosim path relativ pentru portabilitate (din ComfyUI/custom_nodes/ în apps/)
    ln -s "../../$INTERNAL_MANAGER_DIR" "$MANAGER_TARGET"
fi

# Instalare dependențe Manager
echo "📦 [COMFY] Installing Manager dependencies..."
cd "$COMFY_DIR"
if [ -f "$MANAGER_TARGET/requirements.txt" ]; then
    ./venv/bin/pip install -r "$MANAGER_TARGET/requirements.txt"
fi

deactivate
echo "✅ [COMFY] Environment ready. Backend is fully provisioned as submodules."