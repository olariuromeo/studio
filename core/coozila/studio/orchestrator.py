# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/orchestrator.py
# Description: The Unified Production Orchestrator. Manages OTIO lifecycle, 
#              style injection, rhythmic sync, and dual-mode rendering.

import json
import os
import asyncio
import copy
import logging

# --- COOZILA NAMESPACE IMPORTS ---
from coozila.studio.session import save_project_state, load_project_state
from coozila.video.template_loader import SHOT_TEMPLATES
from coozila.video.styles import get_style
from coozila.video.processor import merge_videos_and_audio_ffmpeg
from coozila.audio.analyzer import AudioSyncEngine  # Assuming this exists in audio/
from coozila.video.comfy_client import send_to_comfyui_and_wait

logger = logging.getLogger(__name__)

class VideoStudioManager:
    """
    Central Studio Manager. 
    Coordinates the entire video production pipeline from audio pulse to final master.
    """
    def __init__(self, session_id: str, user_id: str):
        self.session_id = session_id
        self.user_id = user_id
        
        # Internal storage paths
        self.base_dir = os.path.dirname(os.path.abspath(__file__))
        # Templates are now managed by the specific loaders, but we keep a ref for local master schema
        self.schema = self._init_project_schema()

    def _init_project_schema(self):
        """Loads an existing session or clones the Master OTIO Schema."""
        existing = load_project_state(self.session_id)
        if existing:
            return existing
        
        # Default empty schema if no template is found
        return {
            "name": f"project_{self.session_id}",
            "metadata": {
                "active_style_id": "nolan_inspired",
                "custom_style_reference": "",
                "global_negative_prompt": ""
            },
            "tracks": {"children": [{"children": []}]}
        }

    # --- 🎨 STYLE & CREATIVE LOGIC ---

    def apply_style(self, style_id: str):
        """Applies a visual preset from the global style library."""
        style_config = get_style(style_id)
        if style_config:
            self.schema["metadata"]["active_style_id"] = style_id
            self.schema["metadata"]["custom_style_reference"] = style_config["tags"]
            self.schema["metadata"]["global_negative_prompt"] = style_config["negative_tags"]
            save_project_state(self.session_id, self.schema)
            logger.info(f"🎨 [ORCHESTRATOR] Applied style: {style_id}")
            return True
        return False

    # --- 🎬 TIMELINE & RHYTHM LOGIC ---

    async def auto_sync_timeline_to_audio(self, audio_path: str, template_id: str = "default"):
        """Analyzes audio BPM and generates synchronized shots based on rhythmic peaks."""
        # Use the specialized Audio Engine
        analysis = AudioSyncEngine.analyze_track(audio_path)
        self.schema["metadata"]["audio_analysis"] = analysis
        
        # Get cinematic directions from the video template loader
        regia_steps = SHOT_TEMPLATES.get(template_id, [])
        if not regia_steps:
            logger.warning(f"⚠️ [ORCHESTRATOR] Template '{template_id}' not found.")
            return

        cut_points = AudioSyncEngine.get_cut_points(analysis, len(regia_steps))
        self.schema["tracks"]["children"][0]["children"] = [] 
        last_point = 0
        
        for idx, step in enumerate(regia_steps):
            current_cut = cut_points[idx]
            duration_sec = current_cut - last_point
            
            new_clip = {
                "STUDIO_SCHEMA": "Clip.2",
                "name": f"Shot_{idx+1}: {step.get('camera', 'Static')}",
                "metadata": { 
                    "generate_type": "normal", 
                    "vibe": step.get('vibe'), 
                    "motion_intensity": step.get('motion_intensity', 5)
                },
                "source_range": {
                    "duration": { "rate": 24.0, "value": duration_sec * 24.0 },
                    "start_time": { "rate": 24.0, "value": 0.0 }
                },
                "media_references": {
                    "DEFAULT_MEDIA": { "target_url": f"VideoClips/shot_{idx+1}.mp4" }
                }
            }
            self.schema["tracks"]["children"][0]["children"].append(new_clip)
            last_point = current_cut

        save_project_state(self.session_id, self.schema)
        logger.info(f"🎵 [ORCHESTRATOR] Timeline synced to {analysis.get('bpm')} BPM.")

    # --- 🚀 PRODUCTION PIPELINE (RENDER) ---

    async def run_render_pipeline(self, audio_path: str, is_preview: bool = True):
        """Executes the render flow: Payload Construction -> ComfyUI Node -> FFmpeg Mastering."""
        video_track = self.schema["tracks"]["children"][0]["children"]
        rendered_chunks = []
        
        logger.info(f"🚀 [RENDER] Starting {'PREVIEW' if is_preview else 'FINAL'} production.")

        for clip in video_track:
            # Construct parameters for the generation nodes
            frames = int(clip["source_range"]["duration"]["value"])
            
            # Note: Payload building logic should be handled by a specific video/payload_composer.py
            # For now, we assume a simplified call to the ComfyUI client
            payload = {
                "prompt": self.schema["metadata"].get("custom_style_reference"),
                "negative": self.schema["metadata"].get("global_negative_prompt"),
                "length": frames,
                "is_preview": is_preview
            }
            
            chunk_file = await send_to_comfyui_and_wait(payload)
            if chunk_file:
                rendered_chunks.append(chunk_file)

        # 4. Final Assembly via FFmpeg Processor
        prefix = "preview" if is_preview else "master"
        output_path = f"exports/{self.session_id}_{prefix}.mp4"
        
        return merge_videos_and_audio_ffmpeg(rendered_chunks, audio_path, output_path)

    def _split_into_safe_chunks(self, frames: int, max_f: int = 77):
        """Splits long scenes into safe processing chunks to prevent VRAM overflow."""
        chunks = []
        while frames > 0:
            current = min(frames, max_f)
            chunks.append(current)
            frames -= current
        return chunks