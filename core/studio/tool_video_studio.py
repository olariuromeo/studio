# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: open-webui/data/tools/coozila_video_studio.py (or via WebUI Tool Editor)
# Description: Official Open WebUI Tool implementing Valves, Reserved Args, and 
#              Event Emitters to orchestrate the Coozila ComfyUI video pipeline.

import os
import json
import asyncio
from pydantic import BaseModel, Field
from typing import Callable, Awaitable, Any

# Importăm modulele noastre din backend-ul Coozila pe care le-am scris anterior
from coozila.video.studio.payload_builder import build_dynamic_json_payload, load_base_template
from coozila.video.studio.comfy_client import send_to_comfyui_and_wait
from coozila.video.studio.media_processor import merge_videos_and_audio_ffmpeg, extract_last_frame
from coozila.video.studio.memory_manager import save_session_to_memory

class Tools:
    class Valves(BaseModel):
        # Acestea vor apărea în interfața grafică de setări a adminului în Open WebUI
        comfyui_url: str = Field(
            default="127.0.0.1:8188", 
            description="IP and Port for the ComfyUI API backend."
        )
        base_template_path: str = Field(
            default="/path/to/comfy_template.json", 
            description="Absolute path to the base Wan2.2 ComfyUI JSON template."
        )
        output_dir: str = Field(
            default="/path/to/outputs", 
            description="Where to save the final merged MP4 files."
        )

    def __init__(self):
        self.valves = self.Valves()

    async def generate_music_video(
        self, 
        scenes: list[str], 
        audio_file_path: str, 
        start_image_path: str,
        __user__: dict, 
        __event_emitter__: Callable[[dict], Awaitable[None]] = None
    ) -> str:
        """
        Generates a seamless music video using ComfyUI by chaining multiple scenes.
        
        :param scenes: List of text prompts for each scene (e.g., ["Scene 1 prompt", "Scene 2 prompt"])
        :param audio_file_path: Absolute path to the .wav or .mp3 file.
        :param start_image_path: Absolute path to the starting image.
        """
        user_id = __user__["id"]
        session_id = f"session_{user_id}_{int(asyncio.get_event_loop().time())}"
        
        generated_chunks = []
        current_image_path = start_image_path

        # 1. EMIT STATUS: START
        if __event_emitter__:
            await __event_emitter__({
                "type": "status",
                "data": {"description": f"Starting Coozila Studio: 0/{len(scenes)} scenes processed", "done": False}
            })

        try:
            # Încărcăm șablonul masiv de bază pe care l-ai exportat
            base_template = load_base_template(self.valves.base_template_path)

            # 2. PROCESĂM FIECARE SCENĂ (Bucla)
            for index, scene_prompt in enumerate(scenes):
                if __event_emitter__:
                    await __event_emitter__({
                        "type": "status",
                        "data": {"description": f"Rendering Scene {index + 1}/{len(scenes)} in ComfyUI...", "done": False}
                    })

                # Generăm JSON-ul modificat pentru bucata curentă
                # Trimitem lista de scene ca să se randeze fix ce ai cerut în template
                dynamic_payload = build_dynamic_json_payload(
                    base_template, 
                    scenes, 
                    current_image_path, 
                    audio_file_path
                )

                # Așteptăm ca API-ul ComfyUI să termine videoclipul (folosind URL-ul din Valves)
                new_video_chunk = send_to_comfyui_and_wait(dynamic_payload, server_address=self.valves.comfyui_url)

                if not new_video_chunk:
                    raise Exception(f"ComfyUI failed at scene {index + 1}.")

                generated_chunks.append(new_video_chunk)

                # Extragem ultimul cadru pentru a-l folosi la scena următoare (continuitate vizuală)
                current_image_path = extract_last_frame(new_video_chunk, output_image=f"temp_frame_{index}.png")

            # 3. UNIM VIDEOCLIPURILE ȘI ADĂUGĂM MUZICA
            if __event_emitter__:
                await __event_emitter__({
                    "type": "status",
                    "data": {"description": "Merging scenes and applying audio track...", "done": False}
                })

            final_video_path = os.path.join(self.valves.output_dir, f"coozila_final_{session_id}.mp4")
            merge_videos_and_audio_ffmpeg(generated_chunks, audio_file_path, output_filename=final_video_path)

            # 4. SALVĂM ÎN QDRANT MEMORY
            save_session_to_memory(session_id, user_id, scenes, audio_file_path, final_video_path)

            # 5. EMIT STATUS: DONE & RICH UI DISPLAY
            if __event_emitter__:
                await __event_emitter__({
                    "type": "status",
                    "data": {"description": "Video generation complete!", "done": True}
                })
                
                # Aici folosim Rich UI pentru a afișa un HTML custom în chat cu videoclipul
                html_ui = f"""
                <div class="coozila-video-result" style="border: 1px solid #444; padding: 10px; border-radius: 8px;">
                    <h3>🎬 Studio Render Complete</h3>
                    <video width="100%" controls>
                        <source src="/files/{os.path.basename(final_video_path)}" type="video/mp4">
                        Your browser does not support the video tag.
                    </video>
                    <p><strong>Total Scenes:</strong> {len(scenes)}</p>
                    <p><em>Saved to Qdrant Memory ID: {session_id}</em></p>
                </div>
                """
                await __event_emitter__({
                    "type": "message",
                    "data": {"content": html_ui}
                })

            return f"Video successfully generated and saved at: {final_video_path}"

        except Exception as e:
            if __event_emitter__:
                await __event_emitter__({
                    "type": "status",
                    "data": {"description": f"Error: {str(e)}", "done": True}
                })
            return f"Process failed: {str(e)}"