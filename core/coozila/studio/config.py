# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/config.py
# Description: Unified Configuration & Service Registry. Centralizes directory 
#              paths, model constants, and distributed node endpoints.
# ----------------------------------------------------------------------------------#

import os
import logging
from pathlib import Path

# --- 📂 1. DIRECTORY STRUCTURE (Persistence) ---
# Centralized data root for Docker volumes and persistent storage
BASE_DATA_DIR = Path(os.getenv("COOZILA_DATA_DIR", "data/coozila"))
OUTPUT_DIR    = BASE_DATA_DIR / "outputs"
ASSETS_DIR    = BASE_DATA_DIR / "assets"
SESSION_DIR   = BASE_DATA_DIR / "sessions"
EXPORT_DIR    = BASE_DATA_DIR / "exports"

# Auto-initialize system folders on import
for folder in [OUTPUT_DIR, ASSETS_DIR, SESSION_DIR, EXPORT_DIR]:
    folder.mkdir(parents=True, exist_ok=True)


# --- 🛰️ 2. SERVICE REGISTRY (Node Endpoints) ---
# Map of all distributed Coozila microservices
NODE_REGISTRY = {
    "AUDIO_NODE":    os.getenv("COOZILA_AUDIO_URL", "http://localhost:8190"),
    "VIDEO_NODE":    os.getenv("COOZILA_VIDEO_URL", "http://localhost:8188"),
    "UPSCALER_NODE": os.getenv("COOZILA_UPSCALER_URL", "http://localhost:8189"),
}

def get_node_url(node_name: str) -> str:
    """Helper to retrieve a node's URL safely from the registry."""
    return NODE_REGISTRY.get(node_name, "http://localhost:8000")


# --- 🔐 3. SECURITY & SHARED SECRETS ---
INTERNAL_TOKEN = os.getenv("COOZILA_INTERNAL_TOKEN", "tank_security_alpha_2026")
QDRANT_URL     = os.getenv("COOZILA_QDRANT_URL", "http://localhost:6333")


# --- 🎬 4. VIDEO ENGINE CONSTANTS (Wan 2.2 Standards) ---
DEFAULT_FPS      = int(os.getenv("COOZILA_DEFAULT_FPS", 24))
MAX_CHUNK_FRAMES = int(os.getenv("COOZILA_MAX_CHUNK_FRAMES", 81)) 
DEFAULT_WIDTH    = 1280
DEFAULT_HEIGHT   = 720


# --- 🛠️ 5. SYSTEM & LOGGING ---
DEBUG_MODE = os.getenv("COOZILA_DEBUG", "True").lower() == "true"
LOG_LEVEL  = "DEBUG" if DEBUG_MODE else "INFO"

def setup_logging():
    """Standardized logging configuration for all Coozila modules."""
    logging.basicConfig(
        level=LOG_LEVEL,
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s"
    )