# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/config.py
# Description: Unified Configuration & Node Mapping. Agnostic Service Discovery.
# ----------------------------------------------------------------------------------#

import os
import logging
from pathlib import Path

# --- 1. DIRECTORY STRUCTURE & PERSISTENCE ---
# All data paths originate from the DATA_URL environment variable.
DATA_URL      = os.getenv("DATA_URL")
BASE_DATA_DIR = Path(DATA_URL) if DATA_URL else Path("data/storage")

OUTPUT_DIR    = BASE_DATA_DIR / "outputs"
ASSETS_DIR    = BASE_DATA_DIR / "assets"
SESSION_DIR   = BASE_DATA_DIR / "sessions"
EXPORT_DIR    = BASE_DATA_DIR / "exports"

# Automatic directory initialization for local filesystem mounts
if DATA_URL and not DATA_URL.startswith(("http://", "https://")):
    for folder in [OUTPUT_DIR, ASSETS_DIR, SESSION_DIR, EXPORT_DIR]:
        folder.mkdir(parents=True, exist_ok=True)


# --- 2. VIDEO ENGINE RESOLUTIONS (64-bit Aligned) ---
# Strictly divisible by 64 for optimal GPU memory alignment.

RES_LANDSCAPE = {
    "PREVIEW":    {"w": 896,  "h": 512},  # Wan 2.2 Native
    "HD_READY":   {"w": 1280, "h": 704},  
    "FULL_HD":    {"w": 1920, "h": 1088}, 
    "QHD_2K":     {"w": 2560, "h": 1472}, 
    "MASTER_4K":  {"w": 4096, "h": 2304}, 
    "ULTRA_8K":   {"w": 8192, "h": 4608}  
}

RES_PORTRAIT = {
    "PREVIEW":    {"w": 512,  "h": 896},
    "HD_READY":   {"w": 704,  "h": 1280},
    "FULL_HD":    {"w": 1088, "h": 1920},
    "MASTER_4K":  {"w": 2304, "h": 4096}
}

RES_SQUARE = {
    "PREVIEW":    {"w": 512,  "h": 512},  
    "STANDARD":   {"w": 1024, "h": 1024}, 
    "MASTER_4K":  {"w": 4096, "h": 4096}  
}

DEFAULT_WIDTH  = RES_LANDSCAPE["PREVIEW"]["w"]
DEFAULT_HEIGHT = RES_LANDSCAPE["PREVIEW"]["h"]
DEFAULT_FPS    = int(os.getenv("DEFAULT_FPS", 24))


# --- 3. SERVICE REGISTRY & DISCOVERY ---
# Variables mapped directly to the .env file.
STUDIO_URL     = os.getenv("STUDIO_BASE_URL")
INTERNAL_TOKEN = os.getenv("INTERNAL_TOKEN")

NODE_REGISTRY = {
    "STUDIO":             STUDIO_URL,
    "AUDIO_NODE":         os.getenv("AUDIO_URL"),
    "VIDEO_NODE":         os.getenv("VIDEO_URL"),
    "UPSCALER_NODE":      os.getenv("UPSCALER_URL"),
    "INTERPOLATION_NODE": os.getenv("INTERPOLATION_URL")
}

def get_node_url(node_name: str) -> str:
    """Returns the URL for a specific service node from the environment registry."""
    return NODE_REGISTRY.get(node_name, STUDIO_URL)


# --- 4. DATABASE & VECTOR INFRASTRUCTURE ---
# Provider-agnostic naming for scalability (Qdrant, Milvus, Weaviate, etc.)
VECTOR_DB_URL = os.getenv("VECTOR_DB_URL")
RELATIONAL_DB_URL = os.getenv("RELATIONAL_DB_URL")


# --- 5. SYSTEM & LOGGING ---
MAX_CHUNK_FRAMES = int(os.getenv("MAX_CHUNK_FRAMES", 81)) 
DEBUG_MODE       = os.getenv("DEBUG", "False").lower() == "true"
LOG_LEVEL        = "DEBUG" if DEBUG_MODE else "INFO"

def setup_logging():
    """Applies standardized logging based on the environment LOG_LEVEL."""
    logging.basicConfig(
        level=LOG_LEVEL,
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s"
    )