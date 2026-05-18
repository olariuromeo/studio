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
# 3. SELF-CLEANING VENV (Modular Update Logic)
# ----------------------------------------------------------------------------------#
# We perform the cleanup here to allow standalone updates without wiping the entire studio.
echo "🧹 [CLEANUP] Wiping existing ComfyUI VENV for a fresh start..."

[ -d "venv" ] && rm -rf venv

PYTHON_BIN="python${COMFY_PYTHON_VERSION}"
if ! command -v $PYTHON_BIN &> /dev/null; then
    PYTHON_BIN="python"
fi

echo "📦 Creating new virtual environment..."
$PYTHON_BIN -m venv venv
source venv/bin/activate

pip install -U pip packaging wheel ninja "setuptools<82"

# ----------------------------------------------------------------------------------#
# 4. GPU & CUDA Validation + Environment Fix (SSH SAFE)
# ----------------------------------------------------------------------------------#

echo "🔧 Checking NVIDIA driver..."

if ! command -v nvidia-smi &> /dev/null; then
    echo "❌ NVIDIA driver missing"
    exit 1
fi

nvidia-smi

echo "🔧 CUDA environment bootstrap..."

# 4.1 Detect CUDA (single source of truth)
if [ -x /usr/local/cuda/bin/nvcc ]; then
    export CUDA_HOME=/usr/local/cuda
else
    echo "❌ CUDA toolkit not found at /usr/local/cuda"
    exit 1
fi

export PATH="$CUDA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:$LD_LIBRARY_PATH"

echo "✔️ CUDA_HOME=$CUDA_HOME"

# 4.2 Validate nvcc
if ! command -v nvcc &> /dev/null; then
    echo "❌ nvcc not accessible after PATH fix"
    exit 1
fi

nvcc --version
echo "✔️ nvcc path: $(which nvcc)"

# ----------------------------------------------------------------------------------#
# 4.3 PyTorch (SINGLE SOURCE OF TRUTH INSTALL)
# ----------------------------------------------------------------------------------#

echo "Installing PyTorch..."

if [ -z "${CUDA_TAG:-}" ]; then
    echo "❌ CUDA_TAG missing"
    exit 1
fi

echo "CUDA_TAG: $CUDA_TAG"

set +e

pip install \
    torch==2.8.0+cu126 \
    torchvision==0.23.0+cu126 \
    torchaudio==2.8.0+cu126 \
    triton==3.4.0 \
    --index-url "https://download.pytorch.org/whl/cu126" \
    --no-cache-dir \
    --pre

STATUS=$?
set -e

if [ $STATUS -eq 0 ]; then
    echo "✅ PyTorch CUDA stack install OK"
else
    echo "❌ PyTorch install failed"
    exit 1
fi

# ----------------------------------------------------------------------------------#
# 4.4 PYTORCH + CUDA FULL TEST (AICI ESTE LOCUL CORECT)
# ----------------------------------------------------------------------------------#

echo "🧪 PyTorch CUDA deep validation..."

python - <<EOF
import torch

print("Torch:", torch.__version__)
print("CUDA:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())

if torch.cuda.is_available():
    x = torch.randn(1).cuda()
    print("CUDA tensor test OK:", x)
else:
    print("⚠️ CUDA not available")
EOF


# ----------------------------------------------------------------------------------#
# 6. CORE REQUIREMENTS
# ----------------------------------------------------------------------------------#

echo "📦 Installing base requirements..."

if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi

# 6.1 ComfyUI-Manager dependencies (RUN ONLY)

echo "📦 Installing ComfyUI-Manager dependencies..."

if [ -f manager_requirements.txt ]; then
    pip install -r manager_requirements.txt
fi

# ----------------------------------------------------------------------------------#
# 7. FLASH-ATTN (SOURCE BUILD ONLY - CLEAN INSTALL FLOW)
# ----------------------------------------------------------------------------------#

echo "📦 Installing framework extensions (flash-attn build from source)..."

python - <<EOF
import torch
try:
    import flash_attn
    print("FlashAttention OK")
except ImportError:
    print("FlashAttention NOT INSTALLED")

print("Torch:", torch.__version__)
print("CUDA:", torch.version.cuda)
EOF

# FORCE SOURCE BUILD (critical fix)
export TORCH_CUDA_ARCH_LIST="8.6"

CPU_HALF=$(($(nproc) / 2))
if [ "$CPU_HALF" -lt 1 ]; then
    CPU_HALF=1
fi

export MAX_JOBS=$CPU_HALF

pip install flash-attn \
    --no-build-isolation \
    --no-cache-dir \
    --no-binary flash-attn

echo "🧪 Validating flash-attn..."

python - <<EOF
import torch
import flash_attn

print("FlashAttention OK")
print("Torch:", torch.__version__)
print("CUDA:", torch.version.cuda)
EOF

# ----------------------------------------------------------------------------------#
# 8. Manager Submodule Setup
# ----------------------------------------------------------------------------------#

cd "$STUDIO_ROOT"

echo "🔧 Setting up ComfyUI Manager..."

# 8.1 Ensure submodule exists
if [ ! -d "$MANAGER_DIR/.git" ]; then
    echo "→ Adding Manager submodule..."
    git submodule add -f "$MANAGER_REPO" "$MANAGER_DIR" || true
fi

# 8.2 Init / update submodule
git submodule update --init --recursive -- "$MANAGER_DIR"

cd "$STUDIO_ROOT/$MANAGER_DIR"

git fetch --all --tags || true

# 8.3 Resolve ref (default main)
MANAGER_REF="${MANAGER_REF:-main}"

echo "📌 Manager ref: $MANAGER_REF"

# 8.4 Discover available refs
git branch -r | sed 's/origin\///g' > /tmp/branches.txt || true
git tag > /tmp/tags.txt || true

# 8.5 Resolve checkout (tag → branch → main fallback)

if git show-ref --verify --quiet "refs/tags/$MANAGER_REF"; then
    echo "🔒 Using tag: $MANAGER_REF"
    git checkout "tags/$MANAGER_REF" -f

elif git show-ref --verify --quiet "refs/heads/$MANAGER_REF"; then
    echo "🌿 Using branch: $MANAGER_REF"
    git checkout "$MANAGER_REF" -f

elif git show-ref --verify --quiet "refs/remotes/origin/$MANAGER_REF"; then
    echo "🌿 Using remote branch: $MANAGER_REF"
    git checkout "$MANAGER_REF" -f

else
    echo "⚠️ Invalid ref → fallback main"
    git checkout main -f
fi

# 8.6 Symlink
MANAGER_TARGET="$STUDIO_ROOT/$COMFY_DIR/custom_nodes/ComfyUI-Manager"

if [ ! -L "$MANAGER_TARGET" ]; then
    echo "🔗 Linking Manager..."
    ln -s "$STUDIO_ROOT/$MANAGER_DIR" "$MANAGER_TARGET"
fi

echo "✅ Manager ready"

# 8.7 Manager Requirements
if [ -f "$MANAGER_TARGET/requirements.txt" ]; then
    pip install -r "$MANAGER_TARGET/requirements.txt"
fi


# ----------------------------------------------------------------------------------#
# 9. MODULE ENGINE REGISTRY (EXECUTION LAYER)
# ----------------------------------------------------------------------------------#

echo "🔌 Running module engines..."

run_step() {
    local script=$1
    local name=$2

    echo "▶ $name"

    if [ ! -f "$script" ]; then
        echo "⚠️ missing: $script"
        return 1
    fi

    chmod +x "$script"

    (
        export PYTHONNOUSERSITE=1
        bash "$script"
    )

    local status=$?

    if [ $status -ne 0 ]; then
        echo "❌ ENGINE FAILED: $name"
        return $status
    fi
}

run_step "$STUDIO_ROOT/dev/setup-wan2.sh" "Wan Engine"
# run_step "$STUDIO_ROOT/dev/setup-heartmula.sh" "HeartMuLA Engine"

# ----------------------------------------------------------------------------------#
# 10. SYSTEM VALIDATION
# ----------------------------------------------------------------------------------#

echo "🧪 System validation..."

python - <<EOF
import torch

print("Torch:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())

if torch.cuda.is_available():
    print("GPU:", torch.cuda.get_device_name(0))
EOF

# Custom
pip install color-matcher timm omegaconf dill ultralytics piexif pymatting webcolors pywavelets mediapipe trimesh segment_anything

# ----------------------------------------------------------------------------------#
# 11. Finalize
# ----------------------------------------------------------------------------------#

echo "✅ COMFY setup complete!"

# ----------------------------------------------------------------------------------#
# 12. START COMFYUI
# ----------------------------------------------------------------------------------#
echo "🚀 Starting ComfyUI (RTX 3080 Optimized)..."

# Define absolute paths to avoid any confusion
COMFY_PATH="$STUDIO_ROOT/$COMFY_DIR"
PYTHON_VENV="$COMFY_PATH/venv/bin/python"
LOG_FILE="$STUDIO_ROOT/comfy.log"

# 1. Validation: Check if main.py exists
if [ ! -f "$COMFY_PATH/main.py" ]; then
    echo "❌ ERROR: ComfyUI main.py not found at $COMFY_PATH"
    exit 1
fi

# 2. Port Cleanup
if command -v fuser &> /dev/null; then
    fuser -k "$ENGINE_PORT/tcp" >/dev/null 2>&1 || true
fi

# 3. Execution
cd "$COMFY_PATH"
echo "⚙️ Executing: $PYTHON_VENV main.py --listen 0.0.0.0 --port $ENGINE_PORT $VRAM_MODE $COMFY_ARGS"

# Launch in background. The process inherits the VENV context.
nohup "$PYTHON_VENV" main.py --listen 0.0.0.0 --port "$ENGINE_PORT" \
    $VRAM_MODE $COMFY_ARGS \
    > "$LOG_FILE" 2>&1 &

# 4. Process Tracking
COMFY_PID=$!
disown
echo "$COMFY_PID" > "$STUDIO_ROOT/.comfy.pid"

# 5. Finalize & Environment Cleanup
sleep 2
if ps -p $COMFY_PID > /dev/null; then
    echo "✔️ ComfyUI started successfully (PID: $COMFY_PID)"
    echo "🌐 URL: http://127.0.0.1:$ENGINE_PORT"
    echo "📝 Logs: tail -f $LOG_FILE"
else
    echo "❌ ERROR: ComfyUI failed to start."
fi

# EXIT VENV: Returning the shell to its original state
deactivate