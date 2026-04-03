#!/bin/bash
# ----------------------------------------------------------------------------------#
# Coozila! Studio v4.0 - Wan 2.2 Shared VENV Injection (Optimized)
# ----------------------------------------------------------------------------------#
set -e

VENV_PATH="$STUDIO_ROOT/apps/ComfyUI/venv"
echo "🚀 [WAN 2.2] shared environment detected. Injecting specialized layers..."

# 1. Activation
if [ -d "$VENV_PATH" ]; then
    source "$VENV_PATH/bin/activate"
else
    echo "❌ [ERROR] Studio VENV not found. Run setup-comfy.sh first."
    exit 1
fi

# 2. Build Tools (First priority to avoid 'wheel' errors)
echo "🔨 Preparing build environment (Wheel & Ninja)..."
pip install wheel setuptools ninja

# 3. Hardware Acceleration (Ampere/RTX 3080 Specific)
# This is what ComfyUI setup doesn't do by default.
echo "⚡ Installing Flash-Attention (Compiling for RTX 3080)..."
pip install flash-attn --no-build-isolation

echo "⚡ Installing ONNX Runtime & Optimized Numpy..."
pip install onnxruntime-gpu "numpy>=1.23.5,<2"

# 4. Wan-Specific Runtimes (Missing from ComfyUI Core)
echo "📦 Installing Wan processing engine..."
pip install decord modelscope peft loguru sentencepiece pyarrow pyworld librosa \
    easydict dashscope openai-whisper HyperPyYAML inflect wetext \
    conformer hydra-core lightning rich gdown wget

# 5. SAM 2 (Strict Git Commit for Video Segmentation)
pip install "numpy<2" wheel setuptools ninja

# 2. Instalează SAM-2 INTERZICÂNDU-I să descarce alt Torch
pip install git+https://github.com/facebookresearch/sam2.git@0e78a118995e66bb27d78518c4bd9a3e95b4e266 --no-build-isolation

deactivate
echo "✅ [SUCCESS] Wan-Engine layers injected into Studio VENV."