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

# Disable exit on error to allow final reporting
set +e 

# UI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 0. Global Context
export STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export APPS_DIR="$STUDIO_ROOT/apps"
export WEBUI_DIR="$APPS_DIR/open-webui"
export COMFY_DIR="$APPS_DIR/ComfyUI"

FAILED_MODULES=()

# Execution Wrapper
run_step() {
    local script_path=$1
    local step_name=$2
    echo -e "\n${BLUE}🚀 [EXECUTING] $step_name...${NC}"
    
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        "$script_path"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ $step_name: SUCCESS${NC}"
        else
            echo -e "${RED}❌ $step_name: FAILED${NC}"
            FAILED_MODULES+=("$step_name")
        fi
    else
        echo -e "${RED}❌ Script missing: $script_path${NC}"
        FAILED_MODULES+=("$step_name (File Not Found)")
    fi
}

# 1. Load Environment & Tooling
echo -e "${BLUE}⚙️  Loading Coozila! Environment Variables...${NC}"
# 1. Load Environment
if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env.dev" | xargs)
else
    echo "❌ [ERROR] .env.dev missing. Required for Container Mapping."
    exit 1
fi
export CUDA_TAG="cu$(echo $CUDA_VERSION | sed 's/\.//')"

# Ensure ASDF plugins are ready
. "$HOME/.asdf/asdf.sh" 2>/dev/null || true
asdf plugin add python || true
asdf plugin add nodejs || true

# ----------------------------------------------------------------------------------#
# 1.5. SCORCHED EARTH CLEANUP (Critical for Clean Builds)
# ----------------------------------------------------------------------------------#
echo -e "${YELLOW}☢️  [GLOBAL] Starting Nuclear Cleanup (Scorched Earth Mode)...${NC}"

# Kill any blocking processes (Frontend, Backend, Engines)
deactivate 2>/dev/null || true
fuser -k ${STUDIO_PORT}/tcp >/dev/null 2>&1 || true
fuser -k ${ENGINE_PORT}/tcp >/dev/null 2>&1 || true
fuser -k 5173/tcp >/dev/null 2>&1 || true # Omoară Vite dacă a rămas deschis
pkill -f "open-webui" >/dev/null 2>&1 || true
pkill -f "node" >/dev/null 2>&1 || true   # Omoară orice proces Node rătăcit

# Purge Environments and Frontend Artifacts
echo "   -> Wiping VENVs and Node.js artifacts..."
rm -rf "$COMFY_DIR/venv" "$WEBUI_DIR/venv" "$WEBUI_DIR/backend/venv"
rm -rf "$WEBUI_DIR/.svelte-kit" "$WEBUI_DIR/node_modules" "$WEBUI_DIR/build"
rm -f "$WEBUI_DIR/package-lock.json"

# Purge Python Caches
echo "   -> Destroying __pycache__ and Pip artifacts..."
rm -rf ~/.cache/pip /tmp/pip-*
find "$STUDIO_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$STUDIO_ROOT" -type f -name "*.py[co]" -delete 2>/dev/null || true

echo -e "${GREEN}✅ Environment is sterile. Starting fresh deployment...${NC}"

# ----------------------------------------------------------------------------------#
# PHASE 1: SEQUENTIAL INSTALLATION
# ----------------------------------------------------------------------------------#

# 1. Setup WebUI Core (Repos & VENV)
run_step "./dev/setup-webui.sh" "WebUI Base Layer"

# 2. Inject Studio Overlays (Canvas, Core, Compose Patches)
run_step "./dev/setup-studio.sh" "Studio Integration"

# 4. Setup ComfyUI Independent Engine
run_step "./dev/setup-comfy.sh" "Backend Engine (ComfyUI)"

# 3. Install Wan 2.2 Engine (Optimized Wrapper + Dependencies)
run_step "./dev/setup-wan2.sh" "Wan 2.2 Engine"

# 4. Setup HeartMuLA (Audio Engine with Hugging Face Sync)
run_step "./dev/setup-heartmula.sh" "HeartMuLA Integration"

# 5. Install OTIO Engine (Timeline Backbone)
#run_step "./dev/setup-otio.sh" "OTIO Engine"

# 6. Setup mcp-proxy server for distributed stack
#run_step "./dev/mcp-proxy.sh" "Terminal Stack"

# 7. Setup Terminal Stack (mcp-proxy, MinIO, Postgres)
#run_step "./dev/setup-terminal.sh" "Terminal Stack"

# ----------------------------------------------------------------------------------#
# PHASE 2: FRONTEND ENGINE (Vite / SvelteKit)
# ----------------------------------------------------------------------------------#
echo -e "\n${CYAN}# ------------------------------------------------------------------------- #${NC}"
echo -e "${CYAN}#  ENGINE: FRONTEND (Vite Server)                                           #${NC}"
echo -e "${CYAN}#  LOGS  : Real-time Output                                                 #${NC}"
echo -e "${CYAN}# ------------------------------------------------------------------------- #${NC}"

if [ -d "$WEBUI_DIR" ]; then
    cd "$WEBUI_DIR"
    
    # 1. Install - Ensure all node_modules (like pyodide) are present
    echo -e "${YELLOW}📦 [1/3] Installing Frontend Dependencies...${NC}"
    npm install
    
    # 2. Build - Catch errors early and prepare the build folder
    echo -e "${YELLOW}🏗️  [2/3] Compiling Production Build (Safety Check)...${NC}"
    npm run build
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ BUILD FAILED! Fix Svelte/Vite errors before continuing.${NC}"
        exit 1
    fi

    # 3. Dev - Start the HMR (Hot Module Replacement) server
    echo -e "${GREEN}🚀 [3/3] Starting Dev Server at http://localhost:5173...${NC}"
    
    # We run 'npm run dev' and keep it in the foreground of THIS terminal
    # This way you see the Vite logs immediately.
    npm run dev &
    FRONT_PID=$!
    
    cd "$STUDIO_ROOT"
fi

# ----------------------------------------------------------------------------------#
# PHASE 3: HANDOFF (Backend Instructions)
# ----------------------------------------------------------------------------------#
echo -e "\n${YELLOW}==========================================================================${NC}"
echo -e "${GREEN}✨ FRONTEND IS READY & WAITING FOR BACKEND${NC}"
echo -e "${YELLOW}==========================================================================${NC}"
echo -e "\n${WHITE}Now, open a ${GREEN}NEW TERMINAL${WHITE} and fire up the Engine:${NC}"
echo -e "${BLUE}──────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}  cd ${WEBUI_DIR}/backend${NC}"
echo -e "${CYAN}  source ../venv/bin/activate${NC}"
echo -e "${CYAN}  pip install -r requirements.txt -U${NC}"
echo -e "${CYAN}  sh dev.sh${NC}"
echo -e "${BLUE}──────────────────────────────────────────────────────────────────────────${NC}"

# Wait for the user to kill the process
trap "kill $FRONT_PID 2>/dev/null; echo -e '\n🛑 Stopping Frontend...'; exit" SIGINT SIGTERM
wait $FRONT_PID