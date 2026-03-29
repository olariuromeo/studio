# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: coozila/video/studio/orchestrator.py
# Description: The Final Unified Orchestrator. Manages professional STUDIO_SCHEMA 
#              lifecycle, AI Vision style extraction, rhythmic audio 
#              synchronization, and dual-mode rendering (Preview vs. Final).

import json
import os
import asyncio
import copy
from .style_analyzer import analyze_custom_style
from .memory_manager import save_project_state, load_project_state
from .style_engine import StyleEngine
from .payload_builder import build_precise_payload, map_schema_to_wan_params
from .comfy_client import send_to_comfyui_and_wait
from .media_processor import merge_videos_and_audio_ffmpeg
from .audio_sync import AudioSyncEngine

class VideoStudioManager:
    """
    Managerul Central al Studioului. 
    Coordonează fluxul de la analiza audio și stil vizual până la 
    randarea finală prin Wan 2.2.
    """
    def __init__(self, session_id, user_id):
        self.session_id = session_id
        self.user_id = user_id
        self.template_path = "coozila/video/studio/templates/"
        self.schema = self._init_project_schema()

    # --- 📂 MANAGEMENT TEMPLATE (JSON CLONING) ---

    def _load_template(self, filename):
        """Încarcă un fișier JSON din librăria de resurse."""
        path = os.path.join(self.template_path, filename)
        if not os.path.exists(path):
            raise FileNotFoundError(f"Template-ul lipsește: {path}")
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)

    def _init_project_schema(self):
        """Încarcă sesiunea existentă sau clonează Master Schema."""
        existing = load_project_state(self.session_id)
        if existing:
            return existing
        
        master_template = self._load_template("master_schema.json")
        new_schema = copy.deepcopy(master_template)
        new_schema["name"] = f"project_{self.session_id}"
        return new_schema

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
        """
        Analizează audio-ul (BPM) și generează shot-uri sincronizate pe ritm.
        """
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
        print(f"-> Timeline sincronizat la {analysis['bpm']} BPM folosind regia: {template_id}")

    # --- 🚀 LOGICĂ DE PRODUCȚIE (RENDER PREVIEW & FINAL) ---

    async def request_preview(self, audio_path):
        """Generează o versiune rapidă a întregului timeline folosind LoRA Distill."""
        print("-> Inițiere fază PREVIEW (Low-fidelity, fast render)...")
        return await self.run_render_pipeline(audio_path, is_preview=True)

    async def finalize_production(self, audio_path):
        """Generează versiunea finală, la calitate înaltă, fără LoRA de preview."""
        print("-> Inițiere fază FINAL RENDER (High-fidelity, full production)...")
        return await self.run_render_pipeline(audio_path, is_preview=False)

    async def run_render_pipeline(self, audio_path, is_preview=False):
        """
        Randează timeline-ul clip cu clip. 
        is_preview=True activează nodul 107 (LoRA Distill) și reduce pașii.
        """
        video_track = self.schema["tracks"]["children"][0]["children"]
        rendered_files = []

        for clip in video_track:
            # 1. Mapăm datele din clip în parametri tehnici
            clip_params = map_schema_to_wan_params(clip)
            
            # 2. Divizare în chunk-uri (max 77 cadre) pentru stabilitate
            chunks = self._split_into_safe_chunks(clip_params)
            
            for chunk in chunks:
                # 3. Construim payload-ul injectând flag-ul de preview
                payload = build_precise_payload(
                    base_template_json={}, # Va fi încărcat de payload_builder
                    clip_params=chunk, 
                    audio_url=audio_path, 
                    global_style_config=self.schema["metadata"],
                    is_preview=is_preview
                )
                
                # 4. Trimitere la ComfyUI și așteptare
                video_file = await send_to_comfyui_and_wait(payload)
                if video_file:
                    rendered_files.append(video_file)

        # 5. Combinare finală (FFmpeg)
        prefix = "preview" if is_preview else "final"
        output_name = f"exports/{self.session_id}_{prefix}_master.mp4"
        return merge_videos_and_audio_ffmpeg(rendered_files, audio_path, output_name)

    def _split_into_safe_chunks(self, params):
        """Asigură fragmentarea scenelor lungi în joburi de maxim 77 cadre."""
        max_f = 77
        if params["frames"] <= max_f:
            return [params]
        
        # Logica simplă de split (poate fi extinsă pentru continuitate latentă)
        chunks = []
        remaining = params["frames"]
        while remaining > 0:
            current_chunk = copy.deepcopy(params)
            current_chunk["frames"] = min(remaining, max_f)
            chunks.append(current_chunk)
            remaining -= max_f
        return chunks