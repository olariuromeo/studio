#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                  #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.           #
#   Coozila! Team    lab@coozila.com                                             #
#                                                                                  #
# ----------------------------------------------------------------------------------#
# Document: dev/models-download.sh
# Description: Global Asset Sync Engine (HF + ComfyUI Symlinks)
# ----------------------------------------------------------------------------------#

set -euo pipefail

# ----------------------------------------------------------------------------------#
# 1. CONTEXT INITIALIZATION
# ----------------------------------------------------------------------------------#

STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${COMFY_DIR:?Missing COMFY_DIR environment variable}"

COMFY_VENV="$STUDIO_ROOT/$COMFY_DIR/venv"
PIP="$COMFY_VENV/bin/pip"
PY="$COMFY_VENV/bin/python"
HF_BIN="$COMFY_VENV/bin/hf"

# ----------------------------------------------------------------------------------#
# 2. HUGGINGFACE CLI BOOTSTRAP
# ----------------------------------------------------------------------------------#

ensure_hf() {
    echo "🧠 Checking HuggingFace CLI inside VENV..."

    if [ -x "$HF_BIN" ]; then
        echo "✔️ HF CLI ready"
        return 0
    fi

    echo "⬇️ Installing huggingface_hub..."

    "$PIP" install --upgrade pip --no-cache-dir
    "$PIP" install huggingface_hub --no-cache-dir

    if [ ! -x "$HF_BIN" ]; then
        HF_BIN="$PY -m huggingface_hub"
    fi

    echo "✔️ HF bootstrap complete"
}

# ----------------------------------------------------------------------------------#
# 3. SINGLE ASSET SYNC ENGINE
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
    echo "⬇️ DOWNLOAD ASSET"
    echo "Repo   : $repo"
    echo "Path   : $path"
    echo "Target : $target"
    echo "File   : $file_name"
    echo "------------------------------------------------------------"

    # 3.1 SKIP IF EXISTS
    if [ -f "$storage/$file_name" ]; then
        echo "✔️ SKIP (exists): $file_name"
        return 0
    fi

    # 3.2 DOWNLOAD (FILE vs FOLDER MODE)

    if [ -z "$path" ]; then
        echo "📦 FOLDER MODE DETECTED"

        local folder_name
        folder_name="$(basename "$repo")"

        local final_dir="$storage/$folder_name"

        # skip dacă există deja
        if [ -d "$final_dir" ]; then
            echo "✔️ SKIP (folder exists): $folder_name"
        else
            "$HF_BIN" download "$repo" --local-dir "$final_dir"
            echo "✔️ DOWNLOADED FOLDER: $final_dir"
        fi

        # link în ComfyUI
        local link_dir="$STUDIO_ROOT/$COMFY_DIR/models/$target"
        mkdir -p "$link_dir"

        ln -sfn "$final_dir" "$link_dir/$folder_name"

        echo "🔗 LINKED: $target/$folder_name"

        return 0
    fi

    # FILE MODE
    "$HF_BIN" download "$repo" "$path" --local-dir "$storage"

    # 3.3 RESOLVE FILE (FLATTEN GUARANTEE)
    local file
    file=$(find "$storage" -type f -name "$file_name" | head -n 1)

    if [ -z "$file" ]; then
        echo "❌ FAILED: $repo / $path"
        exit 1
    fi

    # 3.4 FLATTEN STORAGE (COOZILA STANDARD)
    local final_file="$storage/$file_name"

    if [ "$file" != "$final_file" ]; then
        mv -f "$file" "$final_file"
    fi

    file="$final_file"

    echo "✔️ DOWNLOADED: $file"

    # 3.5 LINK INTO COMFYUI
    local link_dir="$STUDIO_ROOT/$COMFY_DIR/models/$target"
    mkdir -p "$link_dir"

    ln -sfn "$file" "$link_dir/$file_name"

    echo "🔗 LINKED: $target/$file_name"
}

# ----------------------------------------------------------------------------------#
# 4. RUNNER (GLOBAL ENTRYPOINT)
# ----------------------------------------------------------------------------------#

run_assets() {

    # 4.1 VALIDATION
    if [ -z "${ASSETS+x}" ]; then
        echo "❌ ASSETS not defined"
        exit 1
    fi

    if [ "${#ASSETS[@]}" -eq 0 ]; then
        echo "❌ ASSETS empty"
        exit 1
    fi

    # 4.2 INIT HF
    ensure_hf

    echo "============================================================"
    echo "🚀 COOZILA GLOBAL ASSET ENGINE START"
    echo "============================================================"

    # 4.3 EXECUTION LOOP
    for item in "${ASSETS[@]}"; do
        IFS="|" read -r repo path target <<< "$item"

        if [ -z "$repo" ] || [ -z "$target" ]; then
            echo "⚠️ INVALID ASSET ENTRY: $item"
            continue
        fi

        sync_asset "$repo" "$path" "$target"
    done

    echo "============================================================"
    echo "✅ ALL ASSETS COMPLETED"
    echo "============================================================"
}

# ----------------------------------------------------------------------------------#
# 5. EXPORT
# ----------------------------------------------------------------------------------#
# intended to be sourced by modules