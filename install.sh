#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: studio/install.sh
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
[ ! -f ".env" ] && cp .env.example .env
export $(grep -v '^#' .env | xargs)
export CUDA_TAG="cu$(echo $CUDA_VERSION | sed 's/\.//')"

# Ensure ASDF plugins are ready
. "$HOME/.asdf/asdf.sh" 2>/dev/null || true
asdf plugin add python || true
asdf plugin add nodejs || true

# ----------------------------------------------------------------------------------#
# 1.5. SCORCHED EARTH CLEANUP (Critical for Clean Builds)
# ----------------------------------------------------------------------------------#
echo -e "${YELLOW}☢️  [GLOBAL] Starting Nuclear Cleanup (Scorched Earth Mode)...${NC}"

# Kill any blocking processes
deactivate 2>/dev/null || true
fuser -k ${STUDIO_PORT}/tcp >/dev/null 2>&1 || true
fuser -k ${ENGINE_PORT}/tcp >/dev/null 2>&1 || true
pkill -f "open-webui" >/dev/null 2>&1 || true

# Purge Environments and Frontend Artifacts
echo "   -> Wiping VENVs and Node.js artifacts..."
rm -rf "$COMFY_DIR/venv" "$WEBUI_DIR/venv" "$WEBUI_DIR/backend/venv"
rm -rf "$WEBUI_DIR/.svelte-kit" "$WEBUI_DIR/node_modules"
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
run_step "./scripts/setup-webui.sh" "WebUI Base Layer"

# 2. Inject Studio Overlays (Canvas, Core, Compose Patches)
run_step "./scripts/setup-studio.sh" "Studio Integration"

# 3. Install OTIO Engine (Timeline Backbone)
run_step "./scripts/setup-otio.sh" "OTIO Engine"

# 4. Setup ComfyUI Independent Engine
run_step "./scripts/setup-comfy.sh" "Backend Engine (ComfyUI)"

# 5. Setup Wan 2.2 Acceleration Layer
run_step "./scripts/setup-wan2.sh" "Wan 2.2 Acceleration"

# ----------------------------------------------------------------------------------#
# PHASE 2: THE FINAL SEAL (BUILD)
# ----------------------------------------------------------------------------------#
# Now that EVERY component is in place, we compile the WebUI.
echo -e "\n${BLUE}🏗️  [BUILD] Executing Final WebUI Production Build...${NC}"
if [ -d "$WEBUI_DIR/venv" ]; then
    cd "$WEBUI_DIR"
    source venv/bin/activate
    # Hatch build: Compiles Svelte with all injected overlays.
    pip install -e . --no-cache-dir
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ FINAL BUILD FAILED!${NC}"
        FAILED_MODULES+=("WebUI Production Build")
    fi
    deactivate
    cd "$STUDIO_ROOT"
fi

# ----------------------------------------------------------------------------------#
# PHASE 4: REPORT & LAUNCH
# ----------------------------------------------------------------------------------#
echo -e "\n${BLUE}==========================================================================${NC}"
if [ ${#FAILED_MODULES[@]} -eq 0 ]; then
    echo -e "${GREEN}✨ COOZILA! STUDIO v4.1: INSTALLATION SUCCESSFUL!${NC}"
    echo -e "${BLUE}--------------------------------------------------------------------------${NC}"
    echo -e " 🌐 Frontend (WebUI) : ${GREEN}http://localhost:$STUDIO_PORT${NC}"
    echo -e " 🎬 Backend (ComfyUI): ${GREEN}http://localhost:$ENGINE_PORT${NC}"
    echo -e "${BLUE}--------------------------------------------------------------------------${NC}"
else
    echo -e "${RED}⚠️  INSTALLATION WARNING: Some modules failed:${NC}"
    for module in "${FAILED_MODULES[@]}"; do echo -e "  - ${RED}$module${NC}"; done
fi
echo -e "${BLUE}==========================================================================${NC}\n"

# Launch logic
if [ -d "$WEBUI_DIR/venv" ] && [ -d "$COMFY_DIR/venv" ]; then
    echo -e "${BLUE}🚀 Starting services now...${NC}"
    
    # 1. Start WebUI (Background)
    cd "$WEBUI_DIR"
    source venv/bin/activate
    PORT=$STUDIO_PORT open-webui serve > "$STUDIO_ROOT/open-webui.log" 2>&1 &
    deactivate

    # 2. Start ComfyUI (Foreground) - Acesta este "Congu"
    cd "$COMFY_DIR"
    source venv/bin/activate
    
    # Folosim variabila $ENGINE_PORT din .env
    exec python main.py \
        --listen 0.0.0.0 \
        --port $ENGINE_PORT \
        --enable-manager \
        --$VRAM_MODE \
        --async-offload \
        --preview-method auto
fi