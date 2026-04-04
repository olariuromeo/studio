# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/session.py
# Description: Persistence layer for STUDIO_SCHEMA. Manages JSON-based sessions 
#              and provides granular update methods for style and media assets.

import json
import os
import logging

logger = logging.getLogger(__name__)

# Base path for session storage (Relative to Open-WebUI root)
SESSION_BASE_PATH = "data/coozila/sessions"

def save_project_state(session_id: str, schema_data: dict) -> bool:
    """
    Saves the STUDIO_SCHEMA object to a dedicated JSON file for the session.
    """
    path = os.path.join(SESSION_BASE_PATH, f"{session_id}.json")
    try:
        # Ensure the directory exists
        os.makedirs(os.path.dirname(path), exist_ok=True)
        
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(schema_data, f, indent=4, ensure_ascii=False)
            
        logger.info(f"💾 [SESSION] State saved for session: {session_id}")
        return True
    except Exception as e:
        logger.error(f"❌ [SESSION] Failed to save state for {session_id}: {str(e)}")
        return False

def load_project_state(session_id: str) -> dict or None:
    """
    Loads the saved schema. Returns None if it doesn't exist, 
    allowing the Orchestrator to decide whether to load a base template.
    """
    path = os.path.join(SESSION_BASE_PATH, f"{session_id}.json")
    if os.path.exists(path):
        try:
            with open(path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"❌ [SESSION] Error reading session {session_id}: {str(e)}")
            return None
    return None

def update_schema_style(session_id: str, custom_tags: str = None, style_id: str = None) -> bool:
    """
    Updates ONLY the style configuration of the schema.
    Commonly used after AI Vision analysis or manual style selection.
    """
    schema = load_project_state(session_id)
    if not schema:
        return False
    
    # Ensure metadata structure exists
    if "metadata" not in schema:
        schema["metadata"] = {}
        
    if style_id:
        schema["metadata"]["active_style_id"] = style_id
    if custom_tags:
        schema["metadata"]["custom_style_reference"] = custom_tags
        
    return save_project_state(session_id, schema)

def update_clip_media(session_id: str, clip_index: int, target_url: str) -> bool:
    """
    Updates the media URL (image/video) for a specific clip in the timeline.
    Critical for the Storyboard and Shot Generation phases.
    """
    schema = load_project_state(session_id)
    if not schema:
        return False
    
    try:
        # Navigate structure: Tracks -> Video Track -> Clip
        clips = schema["tracks"]["children"][0]["children"]
        if 0 <= clip_index < len(clips):
            clips[clip_index]["media_references"]["DEFAULT_MEDIA"]["target_url"] = target_url
            return save_project_state(session_id, schema)
    except (KeyError, IndexError) as e:
        logger.error(f"❌ [SESSION] Could not update clip {clip_index} in {session_id}: {str(e)}")
    
    return False