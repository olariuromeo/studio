# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: coozila/video/studio/memory_manager.py
# Description: Persistence layer for STUDIO_SCHEMA. Manages JSON-based sessions 
#              and provides granular update methods for style and media assets.

import json
import os
import logging

logger = logging.getLogger("MemoryManager")

# Calea de bază pentru sesiuni
SESSION_BASE_PATH = "coozila/video/studio/sessions"

def save_project_state(session_id, schema_data):
    """
    Salvează obiectul STUDIO_SCHEMA într-un fișier JSON dedicat sesiunii.
    """
    path = os.path.join(SESSION_BASE_PATH, f"{session_id}.json")
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(schema_data, f, indent=4, ensure_ascii=False)
        logger.info(f"-> Project state saved successfully: {session_id}")
        return True
    except Exception as e:
        logger.error(f"-> Failed to save state for {session_id}: {e}")
        return False

def load_project_state(session_id):
    """
    Încarcă schema salvată. Dacă nu există, returnează None (Orchestratorul 
    va decide dacă încarcă template-ul de bază).
    """
    path = os.path.join(SESSION_BASE_PATH, f"{session_id}.json")
    if os.path.exists(path):
        try:
            with open(path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"-> Error reading session {session_id}: {e}")
            return None
    return None

def update_schema_style(session_id, custom_tags=None, style_id=None):
    """
    Actualizează DOAR partea de stil a schemei fără a rescrie tot manual.
    Utilizat de orchestrator.py după analiza AI Vision.
    """
    schema = load_project_state(session_id)
    if not schema:
        return False
    
    if style_id:
        schema["global_config"]["active_style_id"] = style_id
    if custom_tags:
        schema["global_config"]["custom_style_reference"] = custom_tags
        
    return save_project_state(session_id, schema)

def update_clip_media(session_id, clip_index, target_url):
    """
    Actualizează URL-ul media (imagine/video) pentru un clip specific din timeline.
    Esențial pentru faza de Storyboard/Shot Generation.
    """
    schema = load_project_state(session_id)
    if not schema:
        return False
    
    try:
        # Navigăm în structură: Tracks -> Video Track -> Clip
        clips = schema["tracks"]["children"][0]["children"]
        if 0 <= clip_index < len(clips):
            clips[clip_index]["media_references"]["DEFAULT_MEDIA"]["target_url"] = target_url
            return save_project_state(session_id, schema)
    except (KeyError, IndexError):
        logger.error(f"-> Could not find clip at index {clip_index} in session {session_id}")
    
    return False