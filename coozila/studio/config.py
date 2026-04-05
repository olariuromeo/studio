# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/config.py
# Description: Unified Configuration, Service Registry & Resolution Standards.
# ----------------------------------------------------------------------------------#

import os
import logging
from pathlib import Path

# --- 📂 1. DIRECTORY STRUCTURE (Persistence) ---
BASE_DATA_DIR = Path(os.getenv("COOZILA_DATA_DIR", "data/coozila"))
OUTPUT_DIR    = BASE_DATA_DIR / "outputs"
ASSETS_DIR    = BASE_DATA_DIR / "assets"
SESSION_DIR   = BASE_DATA_DIR / "sessions"
EXPORT_DIR    = BASE_DATA_DIR / "exports"

for folder in [OUTPUT_DIR, ASSETS_DIR, SESSION_DIR, EXPORT_DIR]:
    folder.mkdir(parents=True, exist_ok=True)


# --- 🎬 2. VIDEO ENGINE RESOLUTIONS (64-bit Aligned) ---
# All dimensions are strictly divisible by 64 for GPU/Tensor Core efficiency.

# --- BLOCK A: LANDSCAPE (16:9 / Cinematic) ---
RES_LANDSCAPE = {
    "PREVIEW":    {"w": 896,  "h": 512},  # Wan 2.2 Native Sweet Spot
    "HD_READY":   {"w": 1280, "h": 704},  # QC Draft (720p AI Aligned)
    "FULL_HD":    {"w": 1920, "h": 1088}, # Broadcast Master (1080p AI Aligned)
    "QHD_2K":     {"w": 2560, "h": 1472}, # High-End Review
    "MASTER_4K":  {"w": 4096, "h": 2304}, # Cinematic DCI 4K
    "ULTRA_8K":   {"w": 8192, "h": 4608}  # Archive/Deep-Detail 8K
}

# --- BLOCK B: PORTRAIT (9:16 / Mobile & Social) ---
RES_PORTRAIT = {
    "PREVIEW":    {"w": 512,  "h": 896},  # Wan 2.2 Vertical Native
    "HD_READY":   {"w": 704,  "h": 1280}, # TikTok/Reels Draft
    "FULL_HD":    {"w": 1088, "h": 1920}, # Social Media Master
    "MASTER_4K":  {"w": 2304, "h": 4096}  # Vertical 4K Production
}

# --- BLOCK C: SQUARE (1:1 / Instagram & UI) ---
RES_SQUARE = {
    "PREVIEW":    {"w": 512,  "h": 512},  # Fast Iteration
    "STANDARD":   {"w": 1024, "h": 1024}, # High-Res Square
    "MASTER_4K":  {"w": 4096, "h": 4096}  # Tiled Square Mastering
}

# Default Engine Initialization Standards
DEFAULT_WIDTH  = RES_LANDSCAPE["PREVIEW"]["w"] # 896
DEFAULT_HEIGHT = RES_LANDSCAPE["PREVIEW"]["h"] # 512
DEFAULT_FPS    = int(os.getenv("COOZILA_DEFAULT_FPS", 24))


# --- 🛰️ 3. SERVICE REGISTRY (Node Endpoints) ---
NODE_REGISTRY = {
    "AUDIO_NODE":    os.getenv("COOZILA_AUDIO_URL", "http://localhost:8190"),
    "VIDEO_NODE":    os.getenv("COOZILA_VIDEO_URL", "http://localhost:8188"),
    "UPSCALER_NODE": os.getenv("COOZILA_UPSCALER_URL", "http://localhost:8189"),
}

def get_node_url(node_name: str) -> str:
    return NODE_REGISTRY.get(node_name, "http://localhost:8000")


# --- 🔐 4. SECURITY & SHARED SECRETS ---
INTERNAL_TOKEN = os.getenv("COOZILA_INTERNAL_TOKEN", "tank_security_alpha_2026")
QDRANT_URL     = os.getenv("COOZILA_QDRANT_URL", "http://localhost:6333")


# --- 🛠️ 5. SYSTEM & LOGGING ---
MAX_CHUNK_FRAMES = int(os.getenv("COOZILA_MAX_CHUNK_FRAMES", 81)) 
DEBUG_MODE = os.getenv("COOZILA_DEBUG", "True").lower() == "true"
LOG_LEVEL  = "DEBUG" if DEBUG_MODE else "INFO"

def setup_logging():
    logging.basicConfig(
        level=LOG_LEVEL,
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s"
    )