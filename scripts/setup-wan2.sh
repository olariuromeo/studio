#!/bin/bash
# ----------------------------------------------------------------------------------#
# Coozila! Studio v4.0 - Wan 2.2 Integration (Safe-Run from install.sh)
# ----------------------------------------------------------------------------------#

# 1. Recalculăm căile în caz că variabilele globale nu au fost exportate
if [ -z "$COMFY_DIR" ]; then
    # Presupunem structura standard dacă variabila lipsește
    COMFY_DIR="$(pwd)/apps/ComfyUI"
fi

MODELS_DIR="$COMFY_DIR/models"
WRAPPER_DIR="$COMFY_DIR/custom_nodes/ComfyUI-WanVideoWrapper"
VENV_PATH="$COMFY_DIR/venv"

echo "🚀 [WAN 2.2] Initializing from: $COMFY_DIR"

# 2. Clonare Wrapper
if [ ! -d "$WRAPPER_DIR" ]; then
    echo "📦 Cloning WanVideoWrapper..."
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git "$WRAPPER_DIR"
fi

# 3. Activare VENV și Requirements
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    cd "$WRAPPER_DIR"
    echo "📥 Installing Wrapper requirements..."
    pip install -r requirements.txt --no-cache-dir
else
    echo "❌ [ERROR] VENV not found at $VENV_PATH. Check setup-comfy.sh"
    exit 1
fi

# 4. Descărcare Modele (Folosim căi absolute pentru siguranță)
echo "📥 [MODELS] Checking weights for RTX 3080..."

# Main Model
if [ ! -f "$MODELS_DIR/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors" ]; then
    echo "   -> Downloading Transformer..."
    wget -q --show-progress "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/wan2.2_s2v_14B_fp8_scaled.safetensors" -O "$MODELS_DIR/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors"
fi

# VAE
if [ ! -f "$MODELS_DIR/vae/wan_2.1_vae.safetensors" ]; then
    echo "   -> Downloading VAE..."
    wget -q --show-progress "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wan_2.1_vae.safetensors" -O "$MODELS_DIR/vae/wan_2.1_vae.safetensors"
fi

# Text Encoders
if [ ! -f "$MODELS_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" ]; then
    echo "   -> Downloading T5..."
    wget -q --show-progress "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors" -O "$MODELS_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
fi

# Audio Encoder
if [ ! -f "$MODELS_DIR/text_encoders/wav2vec2_large_english_fp16.safetensors" ]; then
    echo "   -> Downloading Audio Encoder..."
    wget -q --show-progress "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wav2vec2_large_english_fp16.safetensors" -O "$MODELS_DIR/text_encoders/wav2vec2_large_english_fp16.safetensors"
fi

# LoRA
if [ ! -f "$MODELS_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" ]; then
    echo "   -> Downloading Turbo LoRA..."
    wget -q --show-progress "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" -O "$MODELS_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
fi

deactivate
echo "✅ [SUCCESS] Wan 2.2 Stack is complete."