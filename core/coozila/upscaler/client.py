# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/upscaler/client.py
# Description: Remote client for the 8K Tiled Upscaler Node.

import httpx
import logging

logger = logging.getLogger(__name__)

# Remote Node Configuration (Should ideally come from an Env Var or Config file)
UPSCALER_URL = "http://upscaler-node:8189/upscale"
COOZILA_API_KEY = "your_secure_internal_token_here"

async def trigger_upscale(path: str):
    """
    Triggers a remote 8K Tiled Upscale process on a specialized GPU node.
    Includes security headers and content-type definitions.
    """
    
    # Professional Headers for Microservice Communication
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {COOZILA_API_KEY}",
        "X-Coozila-Source": "Studio-Orchestrator",
        "User-Agent": "CoozilaStudio/4.1"
    }

    payload = {"path": path}

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            logger.info(f"📡 [REMOTE] Sending upscale request to {UPSCALER_URL}")
            
            response = await client.post(
                UPSCALER_URL, 
                json=payload, 
                headers=headers
            )
            
            # Raise an exception for 4XX/5XX responses
            response.raise_for_status()
            
            return response.json()

    except httpx.HTTPStatusError as e:
        logger.error(f"❌ [REMOTE ERROR] Upscaler node returned {e.response.status_code}")
        return {"status": "error", "message": str(e)}
    except httpx.RequestError as e:
        logger.error(f"❌ [NETWORK ERROR] Could not reach Upscaler node: {str(e)}")
        return {"status": "error", "message": "Upscaler node unreachable"}