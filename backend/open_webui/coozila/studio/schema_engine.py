# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/schema_engine.py
# Description: The "Living Schema" manager. It populates the base JSON template 
#              with dynamic shots, audio cues, and style metadata.

import json
import os
import copy
import logging

logger = logging.getLogger(__name__)

def create_new_project(user_id: str, project_name: str) -> dict:
    """
    Initializes a new project by cloning the base master schema.
    Sets user identity and project naming.
    """
    # Dynamic path resolution for the master template
    base_path = os.path.dirname(__file__)
    template_path = os.path.join(base_path, "templates", "master_schema.json")
    
    try:
        if not os.path.exists(template_path):
            logger.warning(f"⚠️ [SCHEMA ENGINE] Master template not found at {template_path}. Using fallback.")
            return {
                "name": project_name,
                "user_id": user_id,
                "metadata": {},
                "tracks": {"children": [{"name": "Video Track", "children": []}]}
            }

        with open(template_path, 'r', encoding='utf-8') as f:
            schema = json.load(f)
        
        schema["name"] = project_name
        schema["user_id"] = user_id
        logger.info(f"📁 [SCHEMA ENGINE] New project initialized: {project_name} for user {user_id}")
        return schema

    except Exception as e:
        logger.error(f"❌ [SCHEMA ERROR] Initialization failed: {str(e)}")
        return {}

def inject_shot(schema: dict, shot_data: dict) -> dict:
    """
    Injects a new clip/shot into the primary video track's children list.
    Safely navigates the nested JSON structure.
    """
    try:
        # Standard Studio Path: Tracks -> Children[0] (Video) -> Children (Clips)
        if "tracks" in schema and "children" in schema["tracks"]:
            video_track = schema["tracks"]["children"][0]
            if "children" not in video_track:
                video_track["children"] = []
            
            # Deep copy to prevent reference issues
            video_track["children"].append(copy.deepcopy(shot_data))
            
            shot_name = shot_data.get("name", "Unknown Shot")
            logger.debug(f"🎞️ [SCHEMA ENGINE] Injected shot: {shot_name}")
            return schema
    except Exception as e:
        logger.error(f"❌ [SCHEMA ERROR] Failed to inject shot: {str(e)}")
    
    return schema

def get_total_frames(schema: dict) -> int:
    """Calculates the total frame count of the project for rendering progress."""
    total = 0
    try:
        clips = schema["tracks"]["children"][0]["children"]
        for clip in clips:
            total += clip.get("source_range", {}).get("duration", {}).get("value", 0)
    except Exception:
        pass
    return int(total)