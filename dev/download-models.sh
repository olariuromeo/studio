#!/bin/bash
# ----------------------------------------------------------------------------------#
#   Coozila! Studio - UNIVERSAL DOWNLOADER (Auto-Path & Zero-Byte Guard)           #
# ----------------------------------------------------------------------------------#

# 1. DETECTARE AUTOMATĂ CĂI (Află unde e rula scriptul)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUDIO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMFY_DIR="$STUDIO_ROOT/apps/ComfyUI"
MODELS_DIR="$COMFY_DIR/models"
DOT_ENV="$STUDIO_ROOT/.env"

echo "📂 Director Proiect detectat: $STUDIO_ROOT"
echo "📂 Director Modele detectat: $MODELS_DIR"

# 2. Încărcare Token din .env (dacă există)
if [ -f "$DOT_ENV" ]; then
    HF_TOKEN=$(grep '^HF_TOKEN=' "$DOT_ENV" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    echo "🔑 Token HF încărcat din .env"
fi

# 3. AUTO-INSTALL ARIA2 (Dacă lipsește și avem permisiuni)
if ! command -v aria2c &> /dev/null; then
    echo "📦 Aria2c lipsește. Încercăm instalarea automată..."
    sudo apt-get update -qq && sudo apt-get install -y aria2 -qq || echo "⚠️ Nu s-a putut instala aria2, folosim wget."
fi

# 4. FUNCȚIA DE DOWNLOAD (Verifică 0 biți -> Șterge -> Descarcă Turbo)
smart_sync() {
    local url=$1
    local dest=$2
    local filename=$(basename "$dest")

    mkdir -p "$(dirname "$dest")"

    # [LOGICA TA] Ștergem dacă are 0 biți
    if [ -f "$dest" ] && [ ! -s "$dest" ]; then
        echo "🧹 [CLEANUP] $filename are 0 biți. Se șterge..."
        rm -f "$dest"
    fi

    if [ -s "$dest" ]; then
        echo "✅ [SKIP] $filename este deja valid."
    else
        echo "📥 [FETCH] $filename..."
        if command -v aria2c &> /dev/null; then
            # 16 fire de execuție ca să nu înghețe la 2%
            aria2c -x 16 -s 16 -k 1M --continue=true \
                ${HF_TOKEN:+--header="Authorization: Bearer $HF_TOKEN"} \
                "$url" -d "$(dirname "$dest")" -o "$filename"
        else
            wget -c --show-progress \
                ${HF_TOKEN:+--header="Authorization: Bearer $HF_TOKEN"} \
                "$url" -O "$dest"
        fi
    fi
}

# --- 5. LISTA DE FIȘIERE (Wan 2.1 / 2.2) ---

# URL-ul de bază de la Comfy-Org
BASE_REPACK="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files"

# Text Encoder (cel care făcea probleme)
smart_sync "$BASE_REPACK/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
           "$MODELS_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# VAE
smart_sync "$BASE_REPACK/vae/wan_2.1_vae.safetensors" \
           "$MODELS_DIR/vae/wan_2.1_vae.safetensors"

# CLIP
smart_sync "$BASE_REPACK/clip/clip_l.safetensors" \
           "$MODELS_DIR/clip/clip_l.safetensors"

# Modelul principal (Diffusion) - 15GB dintr-o bucată
smart_sync "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/wan2.2_s2v_14B_fp8_scaled.safetensors" \
           "$MODELS_DIR/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors"

echo "✨ [COMPLETE] Toate fișierele sunt la locul lor!"