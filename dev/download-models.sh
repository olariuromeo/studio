#!/bin/bash
# ----------------------------------------------------------------------------------#
# Document: dev/download-models.sh
# Description: Physical File Provisioning - NO SYMLINKS, NO POINTERS
# ----------------------------------------------------------------------------------#

set -e

# 1. PATHS
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUDIO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODELS_DIR="$STUDIO_ROOT/apps/ComfyUI/models"
DOT_ENV="$STUDIO_ROOT/.env.dev"
TEMP_DIR="$STUDIO_ROOT/.tmp_models"

export PATH="$HOME/.local/bin:$PATH"
HF_BINARY=$(command -v hf || echo "$HOME/.local/bin/hf")

echo -e "\n🚀 \033[1;34mCoozila! Studio - Physical Sync Engine\033[0m"

# 2. AUTH
if [ -f "$DOT_ENV" ]; then
    HF_TOKEN=$(grep '^HF_TOKEN=' "$DOT_ENV" | cut -d'=' -f2- | tr -d '"' | tr -d "'" || true)
    if [ -n "$HF_TOKEN" ]; then
        "$HF_BINARY" auth login --token "$HF_TOKEN" > /dev/null 2>&1
    fi
fi

# 3. PURE PHYSICAL SYNC FUNCTION
sync_model() {
    local repo="$1"
    local remote_path="$2"
    local local_target_dir="$3"
    local min_bytes="$4"
    local filename=$(basename "$remote_path")
    local final_dest="$local_target_dir/$filename"

    # VERIFICARE EXISTENȚĂ ȘI MĂRIME (Fizic pe disc)
    if [ -f "$final_dest" ]; then
        local actual_size=$(stat -c%s "$final_dest")
        if [ "$actual_size" -ge "$min_bytes" ]; then
            echo -e "✅ \033[32m[PHYSICAL]\033[0m $filename is correct."
            return 0
        else
            echo -e "🧹 \033[33m[REPLACING]\033[0m $filename is incomplete/broken."
            rm -f "$final_dest"
        fi
    fi

    echo -e "📥 \033[34m[DOWNLOADING]\033[0m $filename..."
    mkdir -p "$TEMP_DIR"

    # DESCĂRCARE: Folosim flag-ul care forțează fișierul real, nu link-ul
    # --no-relative-path și mutarea manuală garantează locația
    "$HF_BINARY" download "$repo" "$remote_path" --local-dir "$TEMP_DIR"

    # IDENTIFICARE FIȘIER REAL
    local downloaded_file=$(find "$TEMP_DIR" -name "$filename" -type f | head -n 1)
    
    if [ -f "$downloaded_file" ]; then
        # MUTARE FIZICĂ (Nu link): mv șterge din temp și scrie fizic în destinație
        mv -f "$downloaded_file" "$final_dest"
        # Setăm permisiuni de citire/scriere pentru userul curent
        chmod 664 "$final_dest"
        echo -e "✔️  \033[32mDeployed physically to:\033[0m $final_dest"
    else
        echo -e "❌ [ERROR] Could not find downloaded file for $filename"
        exit 1
    fi

    # Curățăm TEMP complet
    rm -rf "$TEMP_DIR"/*
}

# --- 4. EXECUTION (Byte-Exact Verification) ---

sync_model "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$MODELS_DIR/text_encoders" 6000000000
sync_model "wose/comfyui-models" "wan_2.1_vae.safetensors" "$MODELS_DIR/vae" 200000000
sync_model "comfyanonymous/flux_text_encoders" "clip_l.safetensors" "$MODELS_DIR/clip" 200000000
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/audio_encoders/wav2vec2_large_english_fp16.safetensors" "$MODELS_DIR/audio_encoders" 600000000
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors" "$MODELS_DIR/diffusion_models" 15000000000
sync_model "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" "$MODELS_DIR/loras" 100000000

rm -rf "$TEMP_DIR"
echo -e "\n🏆 \033[1;32mAll files are now physically in their folders.\033[0m\n"