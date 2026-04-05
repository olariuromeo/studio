#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/setup-comfy.sh
# Description: Environment-driven ComfyUI Provisioning (Submodule Based)
# ----------------------------------------------------------------------------------#
set -e

# ----------------------------------------------------------------------------------#
# 0. Context & Environment Loading
# ----------------------------------------------------------------------------------#
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env.dev" | xargs)
else
    export $(grep -v '^#' "$STUDIO_ROOT/.env" | xargs)
fi

# Fallback values for optional flags
COMFY_TAG="${COMFY_TAG:-master}"
CUDA_TAG="cu$(echo ${CUDA_VERSION:-12.1} | sed 's/\.//')"

echo "⚙️  [COMFY] Initializing Backend Engine at $COMFY_DIR (Tag: $COMFY_TAG)..."

# ----------------------------------------------------------------------------------#
# 1. Main Engine Registration & Sync
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"

# Auto-register submodule if missing from .gitmodules using ENV path and repo
if ! grep -q "path = $COMFY_DIR" .gitmodules 2>/dev/null; then
    echo "   -> [REGISTER] Submodule $COMFY_DIR not found. Adding..."
    git submodule add -f "$COMFY_REPO" "$COMFY_DIR"
fi

echo "   -> Syncing ComfyUI submodule..."
git submodule update --init --recursive -- "$COMFY_DIR"

# Align with version tag inside the submodule directory
cd "$STUDIO_ROOT/$COMFY_DIR"
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

# ----------------------------------------------------------------------------------#
# 3. Virtual Environment Setup
# ----------------------------------------------------------------------------------#
echo "🧹 [COMFY] Creating fresh VENV (Python $COMFY_PYTHON_VERSION)..."
[ -d "venv" ] && rm -rf venv
python -m venv venv
source venv/bin/activate
pip install --upgrade pip --no-cache-dir

# ----------------------------------------------------------------------------------#
# 4. PyTorch JIT Installation (CUDA Optimized)
# ----------------------------------------------------------------------------------#
echo "📥 [COMFY] Installing PyTorch with CUDA Tag: $CUDA_TAG..."

pip install torch torchvision torchaudio \
    --index-url "https://download.pytorch.org/whl/$CUDA_TAG" \
    --no-cache-dir

# ----------------------------------------------------------------------------------#
# 5. Core Requirements & Manager Submodule
# ----------------------------------------------------------------------------------#
echo "📥 [COMFY] Installing Official Requirements..."

if [ -f "requirements.txt" ]; then
    pip install -r "requirements.txt"
fi

# --- Manager Registration ---
cd "$STUDIO_ROOT"

if ! grep -q "path = $MANAGER_DIR" .gitmodules 2>/dev/null; then
    echo "   -> [REGISTER] Submodule $MANAGER_DIR not found. Adding..."
    git submodule add -f "$MANAGER_REPO" "$MANAGER_DIR"
fi

echo "   -> Syncing Manager submodule..."
git submodule update --init --recursive -- "$MANAGER_DIR"

# ----------------------------------------------------------------------------------#
# 6. Linking & Manager Dependencies
# ----------------------------------------------------------------------------------#
MANAGER_TARGET="$STUDIO_ROOT/$COMFY_DIR/custom_nodes/ComfyUI-Manager"

if [ ! -L "$MANAGER_TARGET" ]; then
    echo "🔗 [COMFY] Creating Symlink for Manager..."
    mkdir -p "$STUDIO_ROOT/$COMFY_DIR/custom_nodes"
    # Create relative link using the base name of the environment directory
    ln -s "../../$(basename "$MANAGER_DIR")" "$MANAGER_TARGET"
fi

echo "📦 [COMFY] Installing Manager dependencies..."
cd "$STUDIO_ROOT/$COMFY_DIR"

if [ -f "$MANAGER_TARGET/requirements.txt" ]; then
    pip install -r "$MANAGER_TARGET/requirements.txt"
fi

deactivate

# ----------------------------------------------------------------------------------#
# 7. Finalize Studio Index
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"
# Stages the submodule state to sync with parent repository index
git add "$COMFY_DIR" "$MANAGER_DIR"

echo -e "✅ [COMFY] Setup complete for $COMFY_DIR.\n"