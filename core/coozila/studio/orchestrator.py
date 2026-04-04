# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: backend/open_webui/coozila/video/studio/orchestrator.py
# Description: The Final Unified Orchestrator. Manages professional STUDIO_SCHEMA 
#              lifecycle, AI Vision style extraction, rhythmic audio 
#              synchronization, and dual-mode rendering (Preview vs. Final).

import json
import os
import asyncio
import copy

# --- IMPORTURI ABSOLUTE (FIXED FOR OPEN-WEBUI) ---
from studio.style_analyzer import analyze_custom_style
from open_webui.studio.memory_manager import save_project_state, load_project_state
from open_webui.studio.style_engine import StyleEngine
from open_webui.studio.payload_factory import CoozilaPayloadFactory
from open_webui.studio.comfy_client import send_to_comfyui_and_wait
from open_webui.studio.media_processor import merge_videos_and_audio_ffmpeg
from open_webui.studio.audio_sync import AudioSyncEngine

class VideoStudioManager:
    """
    Managerul Central al Studioului Coozila. 
    Coordonează fluxul complet de producție video.
    """
    def __init__(self, session_id, user_id):
        self.session_id = session_id
        self.user_id = user_id
        
        # Cale dinamică pentru a găsi folderul de template-uri indiferent de mediul de execuție
        base_dir = os.path.dirname(os.path.abspath(__file__))
        self.template_path = os.path.join(base_dir, "templates")
        
        self.schema = self._init_project_schema()

    # --- 📂 MANAGEMENT TEMPLATE (JSON CLONING) ---

    def _load_template(self, filename):
        """Încarcă un fișier JSON din librăria de resurse studio."""
        path = os.path.join(self.template_path, filename)
        if not os.path.exists(path):
            # Fallback: creăm un folder de templates dacă lipsește pentru a evita crash-ul
            os.makedirs(self.template_path, exist_ok=True)
            raise FileNotFoundError(f"⚠️ Resursa Studio lipsește: {path}")
            
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)

    def _init_project_schema(self):
        """Încarcă sesiunea existentă sau clonează Master Schema din template."""
        existing = load_project_state(self.session_id)
        if existing:
            return existing
        
        try:
            master_template = self._load_template("master_schema.json")
            new_schema = copy.deepcopy(master_template)
            new_schema["name"] = f"project_{self.session_id}"
            return new_schema
        except Exception:
            # Schemă de urgență în caz că template-ul lipsește la prima rulare
            return {"name": f"project_{self.session_id}", "metadata": {}, "tracks": {"children": [{"children": []}]}}

    # --- 🎨 LOGICĂ DE STIL (VISION & LIBRARY) ---

    def apply_style_from_library(self, style_id):
        """Aplică un preset vizual din styles.json."""
        styles_lib = self._load_template("styles.json")
        if style_id in styles_lib:
            selected = styles_lib[style_id]
            self.schema["metadata"]["active_style_id"] = style_id
            self.schema["metadata"]["custom_style_reference"] = selected["tags"]
            self.schema["metadata"]["global_negative_prompt"] = selected["negative_tags"]
            save_project_state(self.session_id, self.schema)
            return True
        return False

    async def handle_reference_upload(self, image_path):
        """Analizează imaginea via AI Vision și creează un stil custom dinamic."""
        new_tags = analyze_custom_style(image_path)
        engine = StyleEngine()
        style_config = engine.construct_style_package(custom_user_input=new_tags)
        
        self.schema["metadata"]["custom_style_reference"] = style_config["positive_tags"]
        self.schema["metadata"]["global_negative_prompt"] = style_config["negative_tags"]
        save_project_state(self.session_id, self.schema)
        return style_config

    # --- 🎬 LOGICĂ DE TIMELINE (REGIA & AUDIO SYNC) ---

    async def auto_sync_timeline_to_audio(self, audio_path, template_id):
        """Analizează audio-ul (BPM) și generează shot-uri sincronizate pe ritm."""
        analysis = AudioSyncEngine.analyze_track(audio_path)
        self.schema["project_metadata"]["audio_analysis"] = analysis
        
        presets_lib = self._load_template("shot_presets.json")
        regia_steps = presets_lib.get(template_id, [])
        if not regia_steps:
            return

        cut_points = AudioSyncEngine.get_cut_points(analysis, len(regia_steps))
        self.schema["tracks"]["children"][0]["children"] = [] 
        last_point = 0
        
        for idx, step in enumerate(regia_steps):
            current_cut = cut_points[idx]
            duration_sec = current_cut - last_point
            
            new_clip = {
                "STUDIO_SCHEMA": "Clip.2",
                "name": f"Shot_{idx+1}: {step['camera']}",
                "metadata": { 
                    "generate_type": "normal", 
                    "vibe": step.get('vibe'), 
                    "transform": step.get('transformation'),
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
        print(f"-> 🎵 Timeline sincronizat la {analysis.get('bpm', 'N/A')} BPM.")

    # --- 🚀 LOGICĂ DE PRODUCȚIE (RENDER PREVIEW & FINAL) ---

    async def request_preview(self, audio_path):
        """Generează o versiune rapidă folosind LoRA Distill."""
        return await self.run_render_pipeline(audio_path, is_preview=True)

    async def finalize_production(self, audio_path):
        """Generează versiunea finală, High-Fidelity."""
        return await self.run_render_pipeline(audio_path, is_preview=False)

    async def run_render_pipeline(self, audio_path, is_preview=False):
        """Randează timeline-ul folosind noua Fabrică Coozila (Hybrid FLUX + Wan)."""
        video_track = self.schema["tracks"]["children"][0]["children"]
        rendered_files = []
        
        # 1. Inițializăm Fabrica
        factory = CoozilaPayloadFactory(is_preview=is_preview)

        for clip in video_track:
            # Parametrii necesari pentru Wan 2.2
            clip_params = {
                "media_url": clip["media_references"]["DEFAULT_MEDIA"]["target_url"],
                "frames": int(clip["source_range"]["duration"]["value"])
            }
            
            # 2. Construim Payload-ul folosind noua metodă din fabrică
            payload = factory.build_video_payload(
                clip_params=clip_params,
                audio_url=audio_path,
                style_config={
                    "positive": self.schema["metadata"].get("custom_style_reference", ""),
                    "negative": self.schema["metadata"].get("global_negative_prompt", "")
                }
            )
            
            # 3. Trimitere la ComfyUI
            video_file = await send_to_comfyui_and_wait(payload)
            if video_file:
                rendered_files.append(video_file)

        # 4. Finalizare cu FFmpeg
        prefix = "preview" if is_preview else "final"
        output_name = f"exports/{self.session_id}_{prefix}_master.mp4"
        return merge_videos_and_audio_ffmpeg(rendered_files, audio_path, output_name)

    def _split_into_safe_chunks(self, params):
        """Fragmentarea scenelor lungi în joburi de maxim 77 cadre."""
        max_f = 77
        if params.get("frames", 0) <= max_f:
            return [params]
        
        chunks = []
        remaining = params["frames"]
        while remaining > 0:
            current_chunk = copy.deepcopy(params)
            current_chunk["frames"] = min(remaining, max_f)
            chunks.append(current_chunk)
            remaining -= max_f
        return chunks