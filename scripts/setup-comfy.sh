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

# --------------------------------------------------------
# 3. Step A: Install Torch (STRICT 12.x SEARCH)
# --------------------------------------------------------
# Prepare the target tag from .env (e.g., 12.5 -> cu125)
TARGET_TAG="cu$(echo $CUDA_VERSION | tr -d '.')"
FINAL_INDEX=""

echo "🔍 Searching for the closest compatible PyTorch 12.x index..."

# Define allowed versions in descending order. 
# We strictly avoid falling back to CUDA 11.x to maintain RTX 30-series performance.
POSSIBLE_VERSIONS=("$TARGET_TAG" "cu126" "cu124" "cu121" "cu120")

for TAG in "${POSSIBLE_VERSIONS[@]}"; do
    echo "📡 Testing remote index: https://download.pytorch.org/whl/$TAG/"
    
    # Perform a fast HTTP HEAD request to verify index existence
    if curl --output /dev/null --silent --head --fail "https://download.pytorch.org/whl/$TAG/"; then
        FINAL_INDEX="$TAG"
        echo "🎯 [MATCH] Found available index: $FINAL_INDEX"
        break
    fi
done

# Critical check: Abort if no 12.x version is found on the PyTorch servers.
if [ -z "$FINAL_INDEX" ]; then
    echo "❌ [CRITICAL ERROR] No PyTorch CUDA 12.x index found."
    echo "Installation aborted to prevent incompatible legacy fallback."
    exit 1
fi

echo "📥 Installing Torch Stack from validated index: $FINAL_INDEX..."

# Forced installation without cache to ensure binary alignment with hardware.
pip install torch torchvision torchaudio \
    --index-url "https://download.pytorch.org/whl/$FINAL_INDEX" \
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

# --------------------------------------------------------
# 5. Step C: Coozila! Studio Fixes (Final Injection)
# --------------------------------------------------------
# This step fixes ModuleNotFoundErrors (cv2, diffusers, pydub, ftfy, etc.)
# by installing our centralized studio-root requirements.
if [ -f "$STUDIO_ROOT/requirements.txt" ]; then
    echo "📥 [COMFY] Injecting Studio-Specific Fixes from Root..."
    pip install -r "$STUDIO_ROOT/requirements.txt"
fi

deactivate
echo "✅ [COMFY] Backend Engine Ready (Locked on Hardware Index: $FINAL_INDEX)."