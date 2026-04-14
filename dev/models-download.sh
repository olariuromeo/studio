#!/bin/bash
# ----------------------------------------------------------------------------------#
# Global Asset Sync Engine (Venv-Isolated HF Downloader + Symlinks)
# ----------------------------------------------------------------------------------#

set -euo pipefail

# ----------------------------------------------------------------------------------#
# 1. CONTEXT
# ----------------------------------------------------------------------------------#
STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${COMFY_DIR:?Missing COMFY_DIR in environment}"

COMFY_VENV="$STUDIO_ROOT/$COMFY_DIR/venv"
PIP="$COMFY_VENV/bin/pip"
PY="$COMFY_VENV/bin/python"
HF_BIN="$COMFY_VENV/bin/hf"

# ----------------------------------------------------------------------------------#
# 2. ENSURE HUGGINGFACE CLI (VENV ONLY)
# ----------------------------------------------------------------------------------#
ensure_hf() {
    echo "🧠 Checking HuggingFace CLI in VENV..."

    if [ -x "$HF_BIN" ]; then
        echo "✔️ HF CLI already available"
        return 0
    fi

    echo "⬇️ Installing huggingface_hub inside venv..."

    "$PIP" install --upgrade pip --no-cache-dir
    "$PIP" install huggingface_hub --no-cache-dir

    if [ ! -x "$HF_BIN" ]; then
        echo "⚠️ HF CLI not found as binary, using python fallback"
        HF_BIN="$PY -m huggingface_hub"
    fi

    echo "✔️ HF ready"
}

# ----------------------------------------------------------------------------------#
# 3. CORE SYNC FUNCTION
# ----------------------------------------------------------------------------------#
sync_asset() {
    local repo="$1"
    local path="$2"
    local target="$3"

    local storage="$STUDIO_ROOT/data/models/$target"
    local file_name
    file_name="$(basename "$path")"

    mkdir -p "$storage"

    echo "------------------------------------------------------------"
    echo "⬇️ DOWNLOAD START"
    echo "Repo   : $repo"
    echo "Path   : $path"
    echo "Target : $target"
    echo "File   : $file_name"
    echo "------------------------------------------------------------"

    # SKIP IF EXISTS
    if [ -f "$storage/$file_name" ]; then
        echo "✔️ SKIP (already exists): $file_name"
        return 0
    fi

    # DOWNLOAD
    "$HF_BIN" download "$repo" "$path" --local-dir "$storage"

    # VERIFY
    local file
    file=$(find "$storage" -type f -name "$file_name" | head -n 1)

    if [ -z "$file" ]; then
        echo "❌ DOWNLOAD FAILED: $repo / $path"
        exit 1
    fi

    echo "✔️ DOWNLOADED: $file"

    # LINK INTO COMFYUI
    local link_dir="$STUDIO_ROOT/$COMFY_DIR/models/$target"
    mkdir -p "$link_dir"

    ln -sfn "$file" "$link_dir/$file_name"

    echo "🔗 LINK CREATED: $link_dir/$file_name"
}

# ----------------------------------------------------------------------------------#
# 4. RUNNER (GLOBAL ENTRYPOINT)
# ----------------------------------------------------------------------------------#
run_assets() {

    if [ ${#ASSETS[@]} -eq 0 ]; then
        echo "❌ ASSETS is empty or not defined"
        exit 1
    fi

    ensure_hf

    echo "============================================================"
    echo "🚀 GLOBAL ASSET ENGINE START (VENV MODE)"
    echo "============================================================"

    for item in "${ASSETS[@]}"; do
        IFS="|" read -r repo path target <<< "$item"
        sync_asset "$repo" "$path" "$target"
    done

    echo "============================================================"
    echo "✅ ALL ASSETS READY"
    echo "============================================================"
}