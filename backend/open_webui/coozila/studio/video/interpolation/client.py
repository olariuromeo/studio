# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/interpolation/client.py
# Description: Smart Hybrid Router for Frame Interpolation. 
#              Prioritizes Remote Nodes to offload local VRAM.
# ----------------------------------------------------------------------------------#

import httpx
import logging
from coozila.studio.config import NODE_REGISTRY, INTERNAL_TOKEN

logger = logging.getLogger(__name__)

async def trigger_interpolation(input_path: str, target_fps: int = 60):
    """
    Decides where to process interpolation based on Node availability.
    Prioritizes offloading to save local GPU VRAM for core generation tasks.
    """
    remote_node_url = NODE_REGISTRY.get("INTERPOLATION_NODE")

    # --- REMOTE-FIRST LOGIC (VRAM Offloading) ---
    if remote_node_url and str(remote_node_url).startswith("http") and remote_node_url != "local":
        
        endpoint = f"{remote_node_url}/api/v1/coozila/studio/interpolation/process"
        
        headers = {
            "Authorization": f"Bearer {INTERNAL_TOKEN}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "input_path": input_path, 
            "target_fps": target_fps,
            "priority": "high"
        }

        try:
            async with httpx.AsyncClient(timeout=600.0) as client:
                logger.info(f"Dispatching interpolation to: {endpoint}")
                response = await client.post(endpoint, json=payload, headers=headers)
                
                if response.status_code == 200:
                    logger.info("Interpolation task accepted by external node.")
                    return response.json()
                else:
                    logger.warning(f"Remote node error ({response.status_code}). Falling back to local...")
        except Exception as e:
            logger.error(f"Connection to node failed: {str(e)}. Attempting local recovery...")

    # --- LOCAL-FALLBACK LOGIC ---
    logger.info("Processing interpolation on local GPU engine (RTX 3080)...")
    
    try:
        from coozila.studio.video.interpolation.engine import local_interpolation_process
        result = await local_interpolation_process(input_path, target_fps)
        return {
            "status": "success", 
            "mode": "local", 
            "path": result,
            "orchestration": "fallback_to_local"
        }
    except ImportError:
        logger.error("Local interpolation engine not found (missing engine.py).")
        return {"status": "error", "message": "No local or remote interpolation engine available."}
    except Exception as e:
        logger.error(f"Local interpolation failed: {str(e)}")
        return {"status": "error", "message": str(e)}