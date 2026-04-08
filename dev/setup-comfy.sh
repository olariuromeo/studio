#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/setup-comfy.sh
# Description: Container-native Provisioning for ComfyUI Engine (ComfyUI v1.0+)
# ----------------------------------------------------------------------------------#
set -euo pipefail

# 0. Context & Environment Loading
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

trap 'echo "❌ Error at line $LINENO"; exit 1' ERR

# ----------------------------------------------------------------------------------#
# 0. Environment Setup (DEV)
# ----------------------------------------------------------------------------------#
ENV_DEV="$STUDIO_ROOT/.env.dev"
ENV_EXAMPLE="$STUDIO_ROOT/.env.example"

if [ ! -f "$ENV_DEV" ]; then
    if [ -f "$ENV_EXAMPLE" ]; then
        echo "🧪 .env.dev not found → creating from .env.example"
        cp "$ENV_EXAMPLE" "$ENV_DEV"
        echo "⚠️ Please review and update .env.dev before continuing"
        exit 1
    else
        echo "❌ Missing both .env.dev and .env.example"
        exit 1
    fi
fi

echo "✔️ Using .env.dev"

# Load env safely
set -a
source "$ENV_DEV"
set +a

# Defaults
COMFY_TAG="${COMFY_TAG:-master}"
CUDA_VERSION="${CUDA_VERSION:-12.1}"
CUDA_TAG="cu$(echo $CUDA_VERSION | sed 's/\.//')"

echo "⚙️ [COMFY] Init at $COMFY_DIR (Tag: $COMFY_TAG)"

# Validate required ENV
: "${COMFY_REPO:?Missing COMFY_REPO}"
: "${COMFY_DIR:?Missing COMFY_DIR}"
: "${MANAGER_REPO:?Missing MANAGER_REPO}"
: "${MANAGER_DIR:?Missing MANAGER_DIR}"
: "${COMFY_PYTHON_VERSION:?Missing COMFY_PYTHON_VERSION}"

cd "$STUDIO_ROOT"

# ----------------------------------------------------------------------------------#
# 1. Submodule Setup
# ----------------------------------------------------------------------------------#
if ! grep -q "path = $COMFY_DIR" .gitmodules 2>/dev/null; then
    echo "→ Registering ComfyUI submodule..."
    git submodule add -f "$COMFY_REPO" "$COMFY_DIR"
fi

git submodule update --init --recursive -- "$COMFY_DIR"

cd "$STUDIO_ROOT/$COMFY_DIR"
git fetch --all --tags
git checkout "$COMFY_TAG" -f || git checkout master

# ----------------------------------------------------------------------------------#
# 2. ASDF Python
# ----------------------------------------------------------------------------------#
echo "python $COMFY_PYTHON_VERSION" > .tool-versions

if [ -f "$HOME/.asdf/asdf.sh" ]; then
    . "$HOME/.asdf/asdf.sh"
    asdf install
    asdf reshim
fi

# ----------------------------------------------------------------------------------#
# 3. VENV
# ----------------------------------------------------------------------------------#
echo "🧹 Creating venv..."

[ -d "venv" ] && rm -rf venv

PYTHON_BIN="python${COMFY_PYTHON_VERSION}"
if ! command -v $PYTHON_BIN &> /dev/null; then
    PYTHON_BIN="python"
fi

$PYTHON_BIN -m venv venv
source venv/bin/activate

pip install --upgrade pip

# ----------------------------------------------------------------------------------#
# 4. GPU Detection + PyTorch Install (DEV ONLY .env.dev)
# ----------------------------------------------------------------------------------#
echo "🔍 Detecting GPU..."

USE_CUDA=false

if command -v nvidia-smi &> /dev/null; then
    echo "✔️ NVIDIA GPU detected"
    nvidia-smi || true
    USE_CUDA=true
else
    echo "⚠️ No NVIDIA GPU detected → CPU mode"
fi

echo "📥 Installing PyTorch..."

# --- STRICT DEV ENV LOAD ---
CUDA_VERSION="${CUDA_VERSION:-12.1}"

map_cuda_to_torch() {
    case "$1" in
        11.*) echo "cu118" ;;
        12.0|12.1) echo "cu121" ;;
        12.2|12.3|12.4) echo "cu124" ;;
        12.5|12.6|13.*) echo "cu124" ;;  # forward fallback
        *) echo "cu121" ;;
    esac
}

if [ "$USE_CUDA" = true ]; then
    CUDA_TAG="$(map_cuda_to_torch "$CUDA_VERSION")"

    echo "🧠 CUDA from .env.dev: $CUDA_VERSION"
    echo "⚙️ PyTorch CUDA build: $CUDA_TAG"

    pip install torch torchvision torchaudio \
        --index-url "https://download.pytorch.org/whl/$CUDA_TAG"
else
    echo "⚙️ Installing CPU PyTorch"
    pip install torch torchvision torchaudio
fi

# ----------------------------------------------------------------------------------#
# 5. Validate Torch
# ----------------------------------------------------------------------------------#
echo "🧪 Validating PyTorch..."

python - <<EOF
import torch
print("Torch version:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())
EOF

# ----------------------------------------------------------------------------------#
# 6. Requirements
# ----------------------------------------------------------------------------------#
echo "📦 Installing requirements..."

if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
fi

# ----------------------------------------------------------------------------------#
# 7. Manager Submodule
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"

if ! grep -q "path = $MANAGER_DIR" .gitmodules 2>/dev/null; then
    echo "→ Registering Manager..."
    git submodule add -f "$MANAGER_REPO" "$MANAGER_DIR"
fi

git submodule update --init --recursive -- "$MANAGER_DIR"

# ----------------------------------------------------------------------------------#
# 8. Symlink Manager (SAFE)
# ----------------------------------------------------------------------------------#
MANAGER_TARGET="$STUDIO_ROOT/$COMFY_DIR/custom_nodes/ComfyUI-Manager"

mkdir -p "$STUDIO_ROOT/$COMFY_DIR/custom_nodes"

if [ ! -L "$MANAGER_TARGET" ]; then
    echo "🔗 Linking Manager..."
    ln -s "$STUDIO_ROOT/$MANAGER_DIR" "$MANAGER_TARGET"
fi

# ----------------------------------------------------------------------------------#
# 9. Manager Requirements
# ----------------------------------------------------------------------------------#
if [ -f "$MANAGER_TARGET/requirements.txt" ]; then
    pip install -r "$MANAGER_TARGET/requirements.txt"
fi

deactivate

# ----------------------------------------------------------------------------------#
# 10. Finalize
# ----------------------------------------------------------------------------------#
cd "$STUDIO_ROOT"
git add "$COMFY_DIR" "$MANAGER_DIR"

echo "✅ COMFY setup complete!"

# ----------------------------------------------------------------------------------#
# 11. START COMFYUI (NON-BLOCKING)
# ----------------------------------------------------------------------------------#
echo "🚀 Starting ComfyUI (RTX 3080 Optimized)..."

cd "$STUDIO_ROOT/$COMFY_DIR"
source venv/bin/activate

# Load variables from environment or set safe defaults
COMFY_PORT="${COMFY_PORT:-8188}"
# THE KEY: If VRAM_MODE is lowvram, add the corresponding flag
VRAM_FLAG="--${VRAM_MODE:-lowvram}" 
# Add the rest of COMFY_ARGS defined for Wan 2.2
EXTRA_ARGS="${COMFY_ARGS:- --fp8_e4m3fn-text-enc --fast-lowvram}"

# Kill process if the port is occupied (safe)
if command -v fuser &> /dev/null; then
    fuser -k "$COMFY_PORT/tcp" >/dev/null 2>&1 || true
fi

# Start with dynamic arguments
echo "⚙️ Executing: python main.py --listen 0.0.0.0 --port $COMFY_PORT $VRAM_FLAG $EXTRA_ARGS"

nohup python main.py --listen 0.0.0.0 --port "$COMFY_PORT" \
    $VRAM_FLAG $EXTRA_ARGS \
    > "$STUDIO_ROOT/$COMFY_DIR/comfy.log" 2>&1 &

COMFY_PID=$!
disown

echo "$COMFY_PID" > "$STUDIO_ROOT/$COMFY_DIR/.comfy.pid"

echo "✔️ ComfyUI running with $VRAM_FLAG"
echo "🌐 http://127.0.0.1:$COMFY_PORT"