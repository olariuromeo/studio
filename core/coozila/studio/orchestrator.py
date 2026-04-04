# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/orchestrator.py
# Description: The Unified Production Orchestrator. Manages OTIO lifecycle, 
#              style injection, and cross-node communication (Audio/Video).
# ----------------------------------------------------------------------------------#

import os
import logging
import httpx
import asyncio

# --- COOZILA UNIFIED CONFIG & UTILS ---
from coozila.studio.config import (
    OUTPUT_DIR, SESSION_DIR, DEFAULT_FPS, 
    NODE_REGISTRY, INTERNAL_TOKEN, setup_logging
)
from coozila.studio.session import save_project_state, load_project_state
from coozila.video.template_loader import SHOT_TEMPLATES

logger = logging.getLogger(__name__)

class VideoStudioManager:
    """
    Central Studio Manager (The Brain). 
    Coordinates requests between the Audio Node and Video Generation Nodes.
    """
    def __init__(self, session_id: str, user_id: str):
        self.session_id = session_id
        self.user_id = user_id
        self.schema = self._init_project_schema()

    def _init_project_schema(self):
        """Loads existing session or returns a clean Master Schema."""
        existing = load_project_state(self.session_id)
        if existing:
            return existing
        
        return {
            "name": f"project_{self.session_id}",
            "user_id": self.user_id,
            "metadata": {
                "active_style_id": "cinematic_default",
                "custom_style_reference": "",
                "global_negative_prompt": "low quality, blurry, static"
            },
            "tracks": {"children": [{"name": "Video Track", "children": []}]}
        }

    # --- 🎵 DISTRIBUTED RHYTHM LOGIC ---

    async def auto_sync_timeline_to_audio(self, audio_path: str, template_id: str = "default"):
        """
        Calls the Remote Audio Node to analyze rhythm and populates the timeline.
        """
        audio_node_url = f"{NODE_REGISTRY['AUDIO_NODE']}/api/v1/coozila/audio/analyze"
        
        headers = {"Authorization": f"Bearer {INTERNAL_TOKEN}"}
        payload = {"file_path": audio_path}

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                logger.info(f"📡 [ORCHESTRATOR] Requesting audio analysis from Node...")
                response = await client.post(audio_node_url, json=payload, headers=headers)
                response.raise_for_status()
                analysis = response.json()

            # Apply rhythmic cuts based on the selected template
            regia_steps = SHOT_TEMPLATES.get(template_id, [])
            num_shots = len(regia_steps)
            
            # Request cut points from Audio Node
            sync_url = f"{NODE_REGISTRY['AUDIO_NODE']}/api/v1/coozila/audio/sync-points"
            sync_payload = {"analysis_data": analysis, "num_shots": num_shots}
            
            sync_resp = await client.post(sync_url, json=sync_payload, headers=headers)
            cut_points = sync_resp.json().get("cut_points", [])

            # Populate Schema with synchronized shots
            self.schema["tracks"]["children"][0]["children"] = []
            last_point = 0
            
            for idx, step in enumerate(regia_steps):
                current_cut = cut_points[idx]
                duration_sec = current_cut - last_point
                
                shot_clip = {
                    "STUDIO_SCHEMA": "Clip.2",
                    "name": f"Shot {idx+1}: {step.get('camera')}",
                    "metadata": {
                        "vibe": step.get("vibe"),
                        "motion": step.get("motion_intensity")
                    },
                    "source_range": {
                        "duration": {"rate": DEFAULT_FPS, "value": duration_sec * DEFAULT_FPS}
                    },
                    "media_references": {
                        "DEFAULT_MEDIA": {"target_url": f"shots/shot_{idx+1}.mp4"}
                    }
                }
                self.schema["tracks"]["children"][0]["children"].append(shot_clip)
                last_point = current_cut

            save_project_state(self.session_id, self.schema)
            logger.info("✅ [ORCHESTRATOR] Timeline synchronized successfully.")
            return True

        except Exception as e:
            logger.error(f"❌ [ORCHESTRATOR] Remote Audio Sync failed: {str(e)}")
            return False

    # --- 🚀 RENDER MASTERING ---

    async def trigger_render(self, is_preview: bool = True):
        """
        Orchestrates the generation of clips across the Video/ComfyUI nodes.
        """
        # Here we would iterate clips and send them to NODE_REGISTRY["VIDEO_NODE"]
        # Then use the video/processor.py to merge them.
        logger.info(f"🎬 [ORCHESTRATOR] Starting render for session {self.session_id}")
        # (Logic for payload construction and FFmpeg call continues here...)