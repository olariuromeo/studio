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

DATA_MODELS="${DATA_MODELS:-$STUDIO_ROOT/$COMFY_DIR/models}"
COMFY_MODELS="${COMFY_MODELS:-$STUDIO_ROOT/$COMFY_DIR/models}"
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
    "$PIP" install huggingface_hub==0.24.6 --no-cache-dir

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

    # 4.1 VALIDATION
    if [ -z "$repo" ] || [ -z "$dest_path" ]; then
        echo "❌ INVALID INPUT"
        exit 1
    fi

    # 4.2 FILE MODE (FIXED LOGIC: file + symlink separation)
    if [ -n "${path:-}" ]; then

        local file_name
        file_name="$(basename "$path")"

        local final_target="$base_models/$dest_path"
        local final_dir
        final_dir="$(dirname "$final_target")"

        mkdir -p "$final_dir"

        # 4.2.1 Check REAL FILE (NO DELETE POLICY)
        local existing_file
        existing_file=$(find "$DATA_MODELS" -type f -name "$file_name" | head -n 1)

        # 4.2.1.1 SOURCE ALIAS (STRICT IDENTITY)
        src="$existing_file"

        local file_exists=0

        if [ -n "$src" ] && [ -f "$src" ]; then

            # HF safety: accept file ONLY if size > 0
            # IMPORTANT: no deletion allowed
            local size
            size=$(stat -c%s "$src" 2>/dev/null || echo 0)

            if [ "$size" -gt 0 ]; then
                file_exists=1
            else
                echo "⚠️ EMPTY FILE DETECTED → WILL RESUME DOWNLOAD"
                file_exists=0
            fi
        fi

        # 4.2.2 Download ONLY if missing/incomplete
        if [ "$file_exists" -eq 0 ]; then
            echo "⬇️ FILE MISSING OR INCOMPLETE → DOWNLOAD: $file_name"

            "$HF_BIN" download "$repo" \
                --include "$path" \
                --local-dir "$DATA_MODELS/split_files/$dest_path"

            existing_file=$(find "$DATA_MODELS" -type f -name "$file_name" | head -n 1)

            if [ -z "$existing_file" ] || [ ! -f "$existing_file" ]; then
                echo "❌ DOWNLOAD FAILED: $repo / $path"
                exit 1
            fi
        else
            echo "✔️ FILE COMPLETE → SKIP DOWNLOAD: $existing_file"
        fi

        # 4.2.3 SYMLINK (ONLY IF NEEDED)

        # 4.2.3.0 CONFIG GUARD (GLOBAL RULE)
        # If both roots are identical, symlink system is disabled entirely
        if [ "$DATA_MODELS" = "$COMFY_MODELS" ]; then
            echo "✔️ SAME STORAGE ROOT → SYMLINK SKIPPED"
            return 0
        fi

        # 4.2.3.1 DEFINE DESTINATION
        local dst="$base_models/$dest_path"

        # 4.2.3.2 RESOLVE PATHS
        real_src="$(readlink -f "$src" 2>/dev/null || true)"
        real_dst="$(readlink -f "$dst" 2>/dev/null || true)"

        # 4.2.3.3 VALIDATE SOURCE
        if [ -z "$real_src" ] || [ ! -f "$real_src" ]; then
            echo "❌ INVALID SOURCE FILE → SKIP SYMLINK"
            return 0
        fi

        # 4.2.3.4 AVOID SELF-LINK
        if [ -n "$real_dst" ] && [ "$real_src" = "$real_dst" ]; then
            echo "✔️ ALREADY CORRECT → SKIP SYMLINK: $dst"
            return 0
        fi

        # 4.2.3.5 ENSURE DIRECTORY
        mkdir -p "$(dirname "$dst")"

        # 4.2.3.6 CREATE SYMLINK
        ln -sfn "$real_src" "$dst"

        echo "🔗 SYMLINK CREATED: $dst"

    fi 
    # 4.3 FOLDER MODE (REPO → DEST PATH)
    local repo_name
    repo_name="$(basename "$repo")"

    local cache_dir="$DATA_MODELS/$repo_name"

    # 4.3.1 Download repo
    if [ -d "$cache_dir" ]; then
        echo "✔️ SKIP CACHE: $repo_name"
    else
        "$HF_BIN" download "$repo" --local-dir "$cache_dir"
        echo "✔️ DOWNLOADED REPO: $cache_dir"
    fi

    local final_target="$base_models/$dest_path"

    # 4.4 ROOT MERGE MODE (IMPORTANT FOR HeartMuLaGen) ex: HeartMuLa/.
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

    # 4.5 NORMAL FOLDER LINK (WITH RENAME)
    mkdir -p "$(dirname "$final_target")"

    rm -rf "$final_target"
    ln -sfn "$cache_dir" "$final_target"

    echo "🔗 LINKED: $final_target"
}

# ----------------------------------------------------------------------------------#
# 5. RUNNER (PATCHED - SAFE ARRAY COPY)
# ----------------------------------------------------------------------------------#

run_assets() {

    # 5.1 VALIDARE ASSETS
    if [ -z "${ASSETS+x}" ]; then
        echo "❌ ASSETS not defined"
        exit 1
    fi

    if [ "${#ASSETS[@]}" -eq 0 ]; then
        echo "❌ ASSETS empty"
        exit 1
    fi

    # 5.2 ENGINE INIT
    ensure_hf

    echo "============================================================"
    echo "🚀 COOZILA GLOBAL ASSET ENGINE START"
    echo "============================================================"

    # 5.3 LOCAL COPY (FIX: avoids global mutation / re-evaluation issues)
    local -a assets=()
    assets=("${ASSETS[@]}")

    # 5.4 LOOP EXECUTION SAFE PARSE + NORMALIZATION
    for item in "${assets[@]}"; do

        IFS="|" read -r repo path dest_path <<< "${item:-}"

        repo="${repo:-}"
        path="${path:-}"
        dest_path="${dest_path:-}"

        # 5.4.1 VALIDARE ITEM
        if [ -z "${repo}" ] || [ -z "${dest_path}" ]; then
            echo "⚠️ INVALID ASSET ENTRY: ${item:-}"
            continue
        fi

        # 5.4.2 SYNC
        sync_asset "$repo" "$path" "$dest_path"

    done

    echo "============================================================"
    echo "✅ ALL ASSETS COMPLETED"
    echo "============================================================"
}

# ----------------------------------------------------------------------------------#
# 6. EXPORT
# ----------------------------------------------------------------------------------#

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run_assets
fi