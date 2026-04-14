#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: studio/dev.sh
# Description: Resilient Master Orchestrator for Coozila! Studio v4.1.
# Logic: Nuclear Cleanup -> App Setup -> Studio/OTIO Injection -> Auto-Launch.
# ----------------------------------------------------------------------------------#

set +e

# ----------------------------------------------------------------------------------#
# 0. GLOBAL CONTEXT
# ----------------------------------------------------------------------------------#
export STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export APPS_DIR="$STUDIO_ROOT/apps"
export WEBUI_DIR="$APPS_DIR/open-webui"
export COMFY_DIR="$APPS_DIR/ComfyUI"

FAILED_MODULES=()

# ----------------------------------------------------------------------------------#
# 1. EXECUTION WRAPPER
# ----------------------------------------------------------------------------------#
run_step() {
    local script_path=$1
    local step_name=$2

    echo -e "\n🚀 [EXECUTING] $step_name..."

    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        "$script_path"

        if [ $? -eq 0 ]; then
            echo -e "✅ $step_name: SUCCESS"
        else
            echo -e "❌ $step_name: FAILED"
            FAILED_MODULES+=("$step_name")
        fi
    else
        echo -e "❌ Script missing: $script_path"
        FAILED_MODULES+=("$step_name (File Not Found)")
    fi
}

# ----------------------------------------------------------------------------------#
# 2. ENVIRONMENT LOADING (FIXED SAFE EXPORT)
# ----------------------------------------------------------------------------------#
echo "⚙️  Loading Coozila! Environment Variables..."

if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    set -a
    source <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$STUDIO_ROOT/.env.dev")
    set +a
else
    echo "❌ [ERROR] .env.dev missing. Required for Container Mapping."
    exit 1
fi

export CUDA_TAG="cu${CUDA_VERSION//./}"

# ----------------------------------------------------------------------------------#
# 3. ASDF INIT
# ----------------------------------------------------------------------------------#
. "$HOME/.asdf/asdf.sh" 2>/dev/null || true
asdf plugin add python || true
asdf plugin add nodejs || true

# ----------------------------------------------------------------------------------#
# 4. SCORCHED EARTH CLEANUP
# ----------------------------------------------------------------------------------#
echo "☢️  [GLOBAL] Starting Nuclear Cleanup..."

deactivate 2>/dev/null || true
fuser -k ${STUDIO_PORT}/tcp >/dev/null 2>&1 || true
fuser -k ${ENGINE_PORT}/tcp >/dev/null 2>&1 || true
fuser -k 5173/tcp >/dev/null 2>&1 || true

pkill -f "open-webui" >/dev/null 2>&1 || true
pkill -f "node" >/dev/null 2>&1 || true

echo "   -> Wiping VENVs and Node.js artifacts..."
rm -rf "$COMFY_DIR/venv" "$WEBUI_DIR/venv" "$WEBUI_DIR/backend/venv"
rm -rf "$WEBUI_DIR/.svelte-kit" "$WEBUI_DIR/node_modules" "$WEBUI_DIR/build"
rm -f "$WEBUI_DIR/package-lock.json"

echo "   -> Destroying __pycache__ and Pip artifacts..."
rm -rf ~/.cache/pip /tmp/pip-*
find "$STUDIO_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$STUDIO_ROOT" -type f -name "*.py[co]" -delete 2>/dev/null || true

echo "✅ Environment is sterile. Starting fresh deployment..."

# ----------------------------------------------------------------------------------#
# 5. PHASE 1: INSTALLATION PIPELINE
# ----------------------------------------------------------------------------------#
run_step "./dev/setup-webui.sh" "WebUI Base Layer"
run_step "./dev/setup-studio.sh" "Studio Integration"
run_step "./dev/setup-comfy.sh" "Backend Engine (ComfyUI)"

# ----------------------------------------------------------------------------------#
# 6. PHASE 2: FRONTEND ENGINE
# ----------------------------------------------------------------------------------#
echo ""
echo "=========================================================================="
echo "✨ FRONTEND ENGINE (Vite)"
echo "=========================================================================="

if [ -d "$WEBUI_DIR" ]; then
    cd "$WEBUI_DIR"

    echo "📦 Installing dependencies..."
    npm install

    echo "🏗️ Building..."
    npm run build || { echo "❌ BUILD FAILED"; exit 1; }

    echo "🚀 Starting dev server..."
    npm run dev &
    FRONT_PID=$!

    cd "$STUDIO_ROOT"
fi

# ----------------------------------------------------------------------------------#
# 7. PHASE 3: HANDOFF
# ----------------------------------------------------------------------------------#
echo ""
echo "=========================================================================="
echo "✨ FRONTEND READY — START BACKEND IN NEW TERMINAL"
echo "=========================================================================="

echo "  cd ${WEBUI_DIR}/backend"
echo "  source ../venv/bin/activate"
echo "  pip install -r requirements.txt -U"
echo "  sh dev.sh"

# ----------------------------------------------------------------------------------#
# 8. CLEAN EXIT HANDLER
# ----------------------------------------------------------------------------------#
trap "kill $FRONT_PID 2>/dev/null; echo '🛑 Stopping Frontend...'; exit" SIGINT SIGTERM
wait $FRONT_PID