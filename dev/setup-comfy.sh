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

pip install --upgrade pip

# ----------------------------------------------------------------------------------#
# 4. GPU Detection & Descending Version Discovery
# ----------------------------------------------------------------------------------#
if command -v nvidia-smi &> /dev/null; then
    echo "✔️ NVIDIA GPU detected"
else
    echo "❌ No NVIDIA GPU detected. Terminating (Strict Dev Mode)."
    exit 1
fi

# 1. PRIMARY TARGET (Admin Input from .env)
ADMIN_CUDA_TAG="cu$(echo ${CUDA_VERSION} | sed 's/\.//')"
echo "🧠 Primary target (Admin Input): $ADMIN_CUDA_TAG"

# 2. DISCOVERY LIST (Descending order for fallback)
# We start from 12.6 down to 12.1 to find the newest available stable build
STABLE_FALLBACKS=("$ADMIN_CUDA_TAG" "cu126" "cu125" "cu124" "cu121" "cu130")

INSTALLED=false

for TAG in "${STABLE_FALLBACKS[@]}"; do
    echo "🔍 Attempting installation for: $TAG..."
    
    # Using --quiet to keep logs clean during discovery, but showing errors if it's the last attempt
    if pip install torch torchvision torchaudio \
        --index-url "https://download.pytorch.org/whl/$TAG" \
        --extra-index-url "https://pypi.org/simple" --no-cache-dir; then
        echo "✅ Successfully installed PyTorch using $TAG"
        INSTALLED=true
        break
    else
        echo "⚠️  $TAG build not found on PyTorch servers. Trying next..."
    fi
done

if [ "$INSTALLED" = false ]; then
    echo "❌ Critical Error: Could not find a compatible PyTorch build for any targeted CUDA version."
    exit 1
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
# 7. ComfyUI-Manager (SIMPLE PIP INSTALL)
# ----------------------------------------------------------------------------------#

echo "📦 Installing ComfyUI-Manager via pip..."

pip install -r manager_requirements.txt

echo "✔️ ComfyUI-Manager installed successfully"

# ----------------------------------------------------------------------------------#
# 9.5. Integrate Sub-Engines (HeartMuLA, Wan2, etc.)
# ----------------------------------------------------------------------------------#
# ANSI Colors for professional logging
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${BLUE}🔌 Injecting Custom Node Engines...${NC}"

# Define local run_step to maintain execution flow and reporting
run_step() {
    local script_path=$1
    local step_name=$2
    
    echo -e "🚀 [EXECUTING] $step_name..."
    
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        # Execute the sub-provisioner
        if bash "$script_path"; then
            echo -e "${GREEN}✅ $step_name: SUCCESS${NC}"
        else
            echo -e "${RED}❌ $step_name: FAILED${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ $step_name: FAILED (File not found at $script_path)${NC}"
        return 1
    fi
}

# --- MODULE SELECTION ---
# Comment out with '#' the engines you do not wish to install/update
run_step "$STUDIO_ROOT/dev/setup-wan2.sh" "Wan 2.2 Engine"
run_step "$STUDIO_ROOT/dev/setup-heartmula.sh" "HeartMuLA Integration"

# 2. DOWNLOAD ENGINE
run_step "$STUDIO_ROOT/dev/models-download.sh" "Global Asset Download"
# Future modules can be added here:
# run_step "$STUDIO_ROOT/dev/setup-example.sh" "Example Engine"

# ----------------------------------------------------------------------------------#
# 10. Finalize
# ----------------------------------------------------------------------------------#

echo "✅ COMFY setup complete!"

# ----------------------------------------------------------------------------------#
# 11. START COMFYUI
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