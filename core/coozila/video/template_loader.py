# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/video/template_loader.py
# Description: Cinematic shot preset loader for the Video Generation Engine.

import json
import os
import logging

logger = logging.getLogger(__name__)

def load_cinematic_templates():
    """
    Loads the cinematic shot templates database from a JSON file.
    These templates define camera movements, lighting, and Wan2.2 parameters.
    """
    # Standard path within the coozila namespace
    # Note: Using absolute path logic relative to the module is safer for production
    base_path = os.path.dirname(__file__)
    path = os.path.join(base_path, "templates", "shot_presets.json")
    
    if not os.path.exists(path):
        logger.warning(f"⚠️ [TEMPLATE LOADER] Preset file not found at: {path}")
        return {}
        
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
            logger.info(f"🎬 [TEMPLATE LOADER] Successfully loaded {len(data)} cinematic presets.")
            return data
    except Exception as e:
        logger.error(f"❌ [TEMPLATE LOADER] Failed to parse presets: {str(e)}")
        return {}

# Quick reference for the Orchestrator or Payload Composer
SHOT_TEMPLATES = load_cinematic_templates()
