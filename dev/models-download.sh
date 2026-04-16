#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                  #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.           #
#   Coozila! Team    lab@coozila.com                                             #
#                                                                                  #
# ----------------------------------------------------------------------------------#
# Document: dev/models-download.sh
# Description: Global Asset Sync Engine (HF → ComfyUI Standard Layout)
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

COMFY_MODELS="$STUDIO_ROOT/$COMFY_DIR/models"

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
# 3. TARGET ROUTER (CRITICAL FOR COMFYUI)
# ----------------------------------------------------------------------------------#

resolve_target_dir() {
    local target="$1"

    case "$target" in
        "vae") echo "$COMFY_MODELS/vae" ;;
        "clip") echo "$COMFY_MODELS/clip" ;;
        "text_encoders") echo "$COMFY_MODELS/text_encoders" ;;
        "audio_encoders") echo "$COMFY_MODELS/audio_encoders" ;;
        "diffusion_models") echo "$COMFY_MODELS/diffusion_models" ;;
        "checkpoints") echo "$COMFY_MODELS/checkpoints" ;;
        "loras") echo "$COMFY_MODELS/loras" ;;
        *)
            echo "$COMFY_MODELS/$target"
            ;;
    esac
}

# ----------------------------------------------------------------------------------#
# 4. SINGLE ASSET SYNC ENGINE (DECLARATIVE DEST PATH SUPPORT)
# ----------------------------------------------------------------------------------#

sync_asset() {
    local repo="$1"
    local path="$2"
    local dest_path="$3"

    local base_models="$COMFY_MODELS"

    echo "------------------------------------------------------------"
    echo "⬇️ DOWNLOAD ASSET"
    echo "Repo   : $repo"
    echo "Path   : $path"
    echo "Dest   : $dest_path"
    echo "------------------------------------------------------------"

    # ----------------------------------------------------------------------------------
    # 4.1 VALIDATION
    # ----------------------------------------------------------------------------------
    if [ -z "$repo" ] || [ -z "$dest_path" ]; then
        echo "❌ INVALID INPUT"
        exit 1
    fi

    # ----------------------------------------------------------------------------------
    # 4.2 FILE MODE
    # ----------------------------------------------------------------------------------
    if [ -n "$path" ]; then

        # 4.2.1 Extract file name from repository path
        local file_name
        file_name="$(basename "$path")"

        # 4.2.2 Resolve final destination path
        local final_target="$base_models/$dest_path"
        local final_dir
        final_dir="$(dirname "$final_target")"

        mkdir -p "$final_dir"

        # 4.2.3 Detect existing file anywhere in target directory tree
        local existing
        existing=$(find "$final_dir" -type f -name "$file_name" | head -n 1)

        # 4.2.4 Skip download if already exists
        if [ -n "$existing" ]; then
            echo "✔️ SKIP (exists): $existing"

            # 4.2.6 Normalize location if needed
            if [ "$existing" != "$final_target" ]; then
                mv -f "$existing" "$final_target" 2>/dev/null || true
                echo "📦 NORMALIZED: $final_target"
            fi

            return 0
        fi

        # 4.2.5 Download file from HuggingFace
        "$HF_BIN" download "$repo" "$path" --local-dir "$final_dir"

        # resolve actual downloaded file (HF nested structure safe)
        local found
        found=$(find "$final_dir" -type f -name "$file_name" | head -n 1)

        if [ -z "$found" ]; then
            echo "❌ FAILED DOWNLOAD: $repo / $path"
            exit 1
        fi

        # 4.2.6 Move to canonical final location
        mv -f "$found" "$final_target" 2>/dev/null || true

        echo "✔️ FILE READY: $final_target"
        return 0
    fi

    # ----------------------------------------------------------------------------------
    # 4.3 FOLDER MODE (REPO → DEST PATH)
    # ----------------------------------------------------------------------------------

    local repo_name
    repo_name="$(basename "$repo")"

    local cache_dir="$STUDIO_ROOT/data/models/$repo_name"

    # 4.3.1 Download repo
    if [ -d "$cache_dir" ]; then
        echo "✔️ SKIP CACHE: $repo_name"
    else
        "$HF_BIN" download "$repo" --local-dir "$cache_dir"
        echo "✔️ DOWNLOADED REPO: $cache_dir"
    fi

    local final_target="$base_models/$dest_path"

    # ----------------------------------------------------------------------------------
    # 4.4 ROOT MERGE MODE (IMPORTANT FOR HeartMuLaGen)
    # ex: HeartMuLa/.
    # ----------------------------------------------------------------------------------
    if [[ "$dest_path" == */. ]]; then
        local root_dir
        root_dir="$(dirname "$final_target")"

        mkdir -p "$root_dir"

        for f in "$cache_dir"/*; do
            local name
            name="$(basename "$f")"

            rm -rf "$root_dir/$name"
            ln -sfn "$f" "$root_dir/$name"
        done

        echo "🔗 MERGED ROOT: $root_dir"
        return 0
    fi

    # ----------------------------------------------------------------------------------
    # 4.5 NORMAL FOLDER LINK (WITH RENAME)
    # ----------------------------------------------------------------------------------

    mkdir -p "$(dirname "$final_target")"

    rm -rf "$final_target"
    ln -sfn "$cache_dir" "$final_target"

    echo "🔗 LINKED: $final_target"
}

# ----------------------------------------------------------------------------------#
# 5. RUNNER
# ----------------------------------------------------------------------------------#

run_assets() {

    if [ -z "${ASSETS+x}" ]; then
        echo "❌ ASSETS not defined"
        exit 1
    fi

    if [ "${#ASSETS[@]}" -eq 0 ]; then
        echo "❌ ASSETS empty"
        exit 1
    fi

    ensure_hf

    echo "============================================================"
    echo "🚀 COOZILA GLOBAL ASSET ENGINE START"
    echo "============================================================"

    for item in "${ASSETS[@]}"; do
        IFS="|" read -r repo path dest_path <<< "$item"

        if [ -z "$repo" ] || [ -z "$dest_path" ]; then
            echo "⚠️ INVALID ASSET ENTRY: $item"
            continue
        fi

        sync_asset "$repo" "$path" "$dest_path"
    done

    echo "============================================================"
    echo "✅ ALL ASSETS COMPLETED"
    echo "============================================================"
}

# ----------------------------------------------------------------------------------#
# 6. EXPORT
# ----------------------------------------------------------------------------------#