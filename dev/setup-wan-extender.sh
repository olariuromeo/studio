#!/bin/bash
# ----------------------------------------------------------------------------------#
# Coozila! Wan Video Extender Setup
# ----------------------------------------------------------------------------------#

set -euo pipefail

STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$STUDIO_ROOT/.env.dev"

# ----------------------------------------------------------------------------------#
# 1. LOAD ENV
# ----------------------------------------------------------------------------------#
set -a
source "$ENV_FILE"
set +a

echo "🚀 COOZILA WAN EXTENDER SETUP START"

# ----------------------------------------------------------------------------------#
# 2. INSTALL CUSTOM NODE
# ----------------------------------------------------------------------------------#
WAN_NODE_DIR="$STUDIO_ROOT/$COMFY_DIR/custom_nodes/wan-video-extender"

if [ ! -d "$WAN_NODE_DIR" ]; then
    git clone https://github.com/Granddyser/wan-video-extender.git "$WAN_NODE_DIR"
else
    echo "✔️ wan-video-extender already installed"
fi

# ----------------------------------------------------------------------------------#
# 3. INSTALL REQUIREMENTS
# ----------------------------------------------------------------------------------#
VENV_PIP="$STUDIO_ROOT/$COMFY_DIR/venv/bin/pip"

if [ -f "$WAN_NODE_DIR/requirements.txt" ]; then
    $VENV_PIP install -r "$WAN_NODE_DIR/requirements.txt" --no-cache-dir
fi

echo "✔️ dependencies installed"

# ----------------------------------------------------------------------------------#
# 4. LOAD ASSET ENGINE
# ----------------------------------------------------------------------------------#
source "$STUDIO_ROOT/dev/models-download.sh"

ASSETS=(
    # HeartMuLa Core Engine
    "HeartMuLa/HeartMuLaGen||HeartMuLa/HeartMuLaGen"

    # Base Model (RL variant)
    "HeartMuLa/HeartMuLa-RL-oss-3B-20260123||HeartMuLa/HeartMuLa-RL-oss-3B-20260123"

    # Codec (MUST MATCH BASE MODEL)
    "HeartMuLa/HeartCodec-oss-20260123||HeartMuLa/HeartCodec-oss-20260123"

    # Transcriptor
    "HeartMuLa/HeartTranscriptor-oss||HeartMuLa/HeartMuLa/HeartTranscriptor-oss"
)

run_assets

echo "✅ HEARTMULA READY"