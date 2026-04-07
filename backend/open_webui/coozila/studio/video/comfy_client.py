# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/video/comfy_client.py
# Description: ComfyUI API Client. Handles prompt submission, queue monitoring, 
#              and file retrieval for Wan2.2 video generation.

import json
import uuid
import logging
import httpx
import asyncio

logger = logging.getLogger(__name__)

# Server Configuration (Default to local, can be moved to a config file)
COMFYUI_URL = "127.0.0.1:8188"
CLIENT_ID = str(uuid.uuid4())

async def send_to_comfyui_and_wait(payload: dict, server_address: str = COMFYUI_URL):
    """
    Submits a workflow to ComfyUI and waits for the execution to complete.
    Returns the path to the generated video file.
    """
    prompt_id = None
    
    async with httpx.AsyncClient(timeout=60.0) as client:
        try:
            # 1. Submit Prompt to Queue
            submit_url = f"http://{server_address}/prompt"
            logger.info(f"📡 [COMFY CLIENT] Submitting job to {server_address}...")
            
            response = await client.post(
                submit_url, 
                json={"prompt": payload, "client_id": CLIENT_ID}
            )
            response.raise_for_status()
            prompt_id = response.json().get("prompt_id")
            
            if not prompt_id:
                raise Exception("Failed to retrieve Prompt ID from ComfyUI.")

            logger.info(f"⏳ [COMFY CLIENT] Job queued: {prompt_id}. Waiting for completion...")

            # 2. Polling for Completion (Wait Loop)
            # In production, this can be upgraded to WebSocket for efficiency
            while True:
                history_url = f"http://{server_address}/history/{prompt_id}"
                history_resp = await client.get(history_url)
                
                if history_resp.status_code == 200:
                    history_data = history_resp.json()
                    if prompt_id in history_data:
                        logger.info(f"✅ [COMFY CLIENT] Job {prompt_id} finished.")
                        
                        # 3. Extract the output filename
                        # ComfyUI usually returns nested outputs: [outputs][node_id][gifs/videos][0][filename]
                        outputs = history_data[prompt_id].get("outputs", {})
                        for node_id in outputs:
                            node_output = outputs[node_id]
                            if "videos" in node_output or "gifs" in node_output:
                                media_list = node_output.get("videos") or node_output.get("gifs")
                                filename = media_list[0].get("filename")
                                
                                # Return the relative path to the output
                                return f"apps/ComfyUI/output/{filename}"

                await asyncio.sleep(2) # Wait 2 seconds before checking again

        except Exception as e:
            logger.error(f"❌ [COMFY CLIENT] Error: {str(e)}")
            return None

async def check_comfy_status(server_address: str = COMFYUI_URL):
    """Checks if the ComfyUI server is online and returns queue remaining count."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            r = await client.get(f"http://{server_address}/queue")
            return r.json()
    except Exception:
        return None