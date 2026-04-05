# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/upscaler/client.py
# Description: Remote client for the 8K Tiled Upscaler Node. 
#              Acts as a bridge between the Studio and a dedicated GPU Worker.
# ----------------------------------------------------------------------------------#

import httpx
import logging
import os

logger = logging.getLogger(__name__)

# --- CONFIGURATION ---
# These should ideally be set in your .env file
UPSCALER_URL = os.getenv("COOZILA_UPSCALER_URL", "http://upscaler-node:8189/upscale")
API_KEY = os.getenv("COOZILA_INTERNAL_TOKEN", "your_secure_internal_token_here")

async def trigger_upscale(path: str):
    """
    Sends a request to a remote GPU node to perform an 8K Tiled Upscale.
    
    This function is designed for a distributed architecture where the 
    Upscaler is a standalone microservice.
    
    Args:
        path (str): The absolute path to the video/image file on the shared storage.
        
    Returns:
        dict: The response from the upscaler node or an error object.
    """
    
    # Secure Headers for Inter-Service Communication
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}",
        "X-Coozila-Source": "Studio-Orchestrator",
        "User-Agent": "CoozilaStudio/4.1"
    }

    payload = {"path": path}

    logger.info(f"📡 [REMOTE CLIENT] Requesting 8K Upscale for: {path}")

    try:
        # We use a longer timeout (30s) for the initial handshake as 
        # upscaling nodes might be waking up or handling heavy queues.
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                UPSCALER_URL, 
                json=payload, 
                headers=headers
            )
            
            # Raise an exception if the remote node returns a 4xx or 5xx error
            response.raise_for_status()
            
            result = response.json()
            logger.info(f"✅ [REMOTE CLIENT] Upscale job accepted by node: {UPSCALER_URL}")
            return result

    except httpx.HTTPStatusError as e:
        logger.error(f"❌ [REMOTE ERROR] Upscaler node rejected request: {e.response.status_code}")
        return {"status": "error", "message": f"Node rejected request: {e.response.status_code}"}
        
    except httpx.RequestError as e:
        logger.error(f"❌ [NETWORK ERROR] Remote Upscaler node is unreachable at {UPSCALER_URL}")
        return {"status": "error", "message": "Upscaler service unreachable. Check network/VPN."}

async def get_upscaler_health():
    """
    Checks the status of the remote Upscaler node.
    """
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{UPSCALER_URL.replace('/upscale', '/health')}")
            return response.json()
    except Exception:
        return {"status": "offline"}