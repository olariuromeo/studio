# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: coozila/video/studio/config.py
# Description: Global configuration settings including API endpoints, local paths, 
#              and default model parameters (FPS, Batch Sizes, etc.).

import os

COMFY_URL = "http://127.0.0.1:8188"
QDRANT_URL = "http://localhost:6333"
OUTPUT_DIR = os.path.join(os.getcwd(), "outputs")
ASSETS_DIR = os.path.join(os.getcwd(), "VideoClips")
DEFAULT_FPS = 24
MAX_CHUNK_FRAMES = 77