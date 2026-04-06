# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/orchestrator.py
# Description: The Unified Production Orchestrator. Manages Dynamic Schemas,
#              Relay Prompting, and cross-node communication (Audio/Video).
# ----------------------------------------------------------------------------------#

import os
import json
import logging
import httpx
import asyncio

# --- COOZILA UNIFIED CONFIG & UTILS ---
from coozila.studio.config import NODE_REGISTRY, INTERNAL_TOKEN
from coozila.studio.session import save_project_state, load_project_state

logger = logging.getLogger(__name__)

class VideoStudioManager:
    """
    Central Studio Manager (The Brain). 
    Builds the Wan 2.2 application dynamically strictly using the JSON Templates.
    """
    def __init__(self, session_id: str, user_id: str):
        self.session_id = session_id
        self.user_id = user_id
        self.schema = self._init_project_schema()

    def _init_project_schema(self):
        """
        Loads the Default JSON Schema EXACTLY as defined.
        If a session already exists, it loads the saved state.
        """
        # 1. Check if we already have an active session saved
        existing = load_project_state(self.session_id)
        if existing:
            return existing
        
        # 2. Load the Default JSON Template strictly from file
        schema_path = os.path.join(os.path.dirname(__file__), 'schemas', 'default_wan_v2.json')
        try:
            with open(schema_path, 'r') as f:
                base_schema = json.load(f)
        except Exception as e:
            logger.error(f"❌ [ORCHESTRATOR] Failed to load default schema: {e}")
            raise FileNotFoundError("Default JSON schema missing. Cannot initialize Wan engine.")

        # 3. Add session identifiers (NO OVERRIDES to resolution/engine_config)
        base_schema["session_id"] = self.session_id
        base_schema["user_id"] = self.user_id

        # Save the freshly assigned template to disk
        save_project_state(self.session_id, base_schema)
        return base_schema

    # --- 🧠 DYNAMIC PROMPTING (RELAY) ---

    async def generate_relay_prompt(self, user_input: str, context: str = "") -> str:
        """
        Relay Prompt Logic: Takes raw user input and expands it into a highly 
        technical prompt optimized for Wan 2.2.
        """
        logger.info(f"🧠 [ORCHESTRATOR] Generating Relay Prompt for input: {user_input}")
        
        # In a real scenario, this would call an internal LLM node.
        # For now, we assemble it programmatically.
        technical_prompt = f"{user_input}, cinematic wide shot, highly detailed, 8k resolution, professional color grading, masterpiece. {context}"
        
        # Update the active schema strictly based on what is configured
        self.schema["initial_state"]["prompt"] = technical_prompt.strip()
        save_project_state(self.session_id, self.schema)
        
        return self.schema["initial_state"]["prompt"]

    # --- 🎵 DISTRIBUTED RHYTHM & DYNAMIC TIMELINE LOGIC ---

    async def auto_sync_timeline_to_audio(self, audio_path: str):
        """
        Calls the Remote Audio Node to analyze rhythm and populates the schema dynamically.
        This turns the 'default' schema into a user-specific dynamic schema.
        """
        audio_node_url = f"{NODE_REGISTRY.get('AUDIO_NODE')}/api/v1/coozila/audio/analyze"
        headers = {"Authorization": f"Bearer {INTERNAL_TOKEN}"}
        payload = {"file_path": audio_path}

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                logger.info(f"📡 [ORCHESTRATOR] Requesting audio analysis from Node...")
                response = await client.post(audio_node_url, json=payload, headers=headers)
                response.raise_for_status()
                analysis = response.json()

            # Request cut points from Audio Node based on beats
            sync_url = f"{NODE_REGISTRY.get('AUDIO_NODE')}/api/v1/coozila/audio/sync-points"
            sync_resp = await client.post(sync_url, json={"analysis_data": analysis}, headers=headers)
            cut_points = sync_resp.json().get("cut_points", [])

            # We need to ensure the timeline_structure exists (if it was added to the JSON)
            if "timeline_structure" not in self.schema:
                self.schema["timeline_structure"] = {"tracks": [{"id": "video_track_1", "clips": []}]}

            video_track = self.schema["timeline_structure"]["tracks"][0]
            video_track["clips"] = []
            
            # Read FPS directly from the schema (or fallback to 20 for Wan)
            current_fps = self.schema.get("initial_state", {}).get("fps", 20)
            
            last_point = 0
            for idx, cut_time in enumerate(cut_points):
                duration_sec = cut_time - last_point
                
                # We apply the Relay Prompt logic dynamically to each beat
                beat_prompt = await self.generate_relay_prompt(
                    user_input=self.schema["initial_state"]["prompt"],
                    context=f"Shot {idx+1}, evolving scene, dynamic motion."
                )

                clip_data = {
                    "clip_id": f"shot_{idx+1}",
                    "prompt": beat_prompt,
                    "duration_sec": round(duration_sec, 2),
                    "frames": int(duration_sec * current_fps),
                    "status": "pending"
                }
                video_track["clips"].append(clip_data)
                last_point = cut_time

            # Update the global audio file reference strictly inside the schema
            self.schema["initial_state"]["audio_file"] = os.path.basename(audio_path)

            save_project_state(self.session_id, self.schema)
            logger.info("✅ [ORCHESTRATOR] Dynamic timeline generated based on Audio.")
            return self.schema

        except Exception as e:
            logger.error(f"❌ [ORCHESTRATOR] Remote Audio Sync failed: {str(e)}")
            return None