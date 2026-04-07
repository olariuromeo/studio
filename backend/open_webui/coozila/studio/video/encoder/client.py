# ----------------------------------------------------------------------------------#
# Location: coozila/studio/video/encoder/client.py
# Description: Hybrid Client for Video Mastering. Handles Local vs Remote routing.
# ----------------------------------------------------------------------------------#

import httpx
import logging
from coozila.studio.config import NODE_REGISTRY, INTERNAL_TOKEN

logger = logging.getLogger(__name__)

async def trigger_final_mastering(input_path: str, audio_path: str, output_path: str, fps: int = 24):
    """
    Orchestrates the mastering process. 
    Checks NODE_REGISTRY to decide whether to offload to a remote container/server.
    """
    remote_url = NODE_REGISTRY.get("ENCODER_NODE")

    # --- 🛰️ REMOTE / CONTAINER LOGIC ---
    if remote_url and remote_url != "local" and str(remote_url).startswith("http"):
        endpoint = f"{remote_url}/api/v1/coozila/studio/video/encoder/process"
        headers = {
            "Authorization": f"Bearer {INTERNAL_TOKEN}",
            "Content-Type": "application/json"
        }
        payload = {
            "input_path": input_path,
            "audio_path": audio_path,
            "output_path": output_path,
            "fps": fps
        }

        try:
            # Encoding can take time; using a very long timeout (10 minutes)
            async with httpx.AsyncClient(timeout=600.0) as client:
                logger.info(f"Dispatching encoding task to remote node: {remote_url}")
                response = await client.post(endpoint, json=payload, headers=headers)
                if response.status_code == 200:
                    return response.json()
        except Exception as e:
            logger.error(f"Remote encoder failed or unreachable: {str(e)}. Falling back...")

    # --- 🏠 LOCAL FALLBACK ---
    from coozila.studio.video.encoder.engine import VideoMasteringEngine
    logger.info("Executing local mastering process.")
    return await VideoMasteringEngine.render_final_video(input_path, audio_path, output_path, fps)