# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/audio/analyzer/client.py
# Description: Smart Hybrid Router for Audio Analysis. 
#              Decides between local execution or remote node offloading.
# ----------------------------------------------------------------------------------#

import httpx
import logging
from coozila.studio.config import NODE_REGISTRY, INTERNAL_TOKEN

logger = logging.getLogger(__name__)

async def trigger_audio_analysis(audio_path: str) -> dict:
    """
    Initiates audio analysis. Routes to a remote node if configured in NODE_REGISTRY,
    otherwise falls back to local engine execution.
    """
    remote_url = NODE_REGISTRY.get("AUDIO_NODE")

    # --- 🛰️ REMOTE EXECUTION LOGIC ---
    if remote_url and str(remote_url).startswith("http") and remote_url != "local":
        # Hierarchical Path: /api/v1/coozila/studio/audio/analyzer/analyze
        endpoint = f"{remote_url}/api/v1/coozila/studio/audio/analyzer/analyze"
        
        headers = {
            "Authorization": f"Bearer {INTERNAL_TOKEN}",
            "Content-Type": "application/json",
            "X-Coozila-Source": "Studio-Orchestrator"
        }
        
        payload = {"audio_path": audio_path}

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                logger.info(f"Offloading audio analysis to remote node: {remote_url}")
                response = await client.post(endpoint, json=payload, headers=headers)
                
                if response.status_code == 200:
                    return response.json()
                
                logger.warning(f"Remote node returned error {response.status_code}. Falling back to local...")
        except Exception as e:
            logger.error(f"Remote audio node unreachable at {remote_url}: {str(e)}. Attempting local fallback...")

    # --- 🏠 LOCAL FALLBACK EXECUTION ---
    # This part runs if no remote node is defined or if the remote call fails.
    try:
        from coozila.studio.audio.analyzer.engine import AudioSyncEngine
        logger.info("Executing audio analysis on local engine.")
        return AudioSyncEngine.analyze_track(audio_path)
    except ImportError:
        logger.error("Local AudioSyncEngine not found. Critical failure.")
        return {"status": "error", "message": "No analysis engine available (local or remote)."}

async def get_sync_points(analysis_data: dict, num_shots: int) -> dict:
    """
    Calculates rhythmic cut points. Matches the distributed logic of trigger_audio_analysis.
    Accepts raw analysis data and returns timestamps for video transitions.
    """
    remote_url = NODE_REGISTRY.get("AUDIO_NODE")

    # --- 🛰️ REMOTE EXECUTION LOGIC ---
    if remote_url and str(remote_url).startswith("http") and remote_url != "local":
        endpoint = f"{remote_url}/api/v1/coozila/studio/audio/analyzer/sync-points"
        
        headers = {
            "Authorization": f"Bearer {INTERNAL_TOKEN}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "analysis_data": analysis_data,
            "num_shots": num_shots
        }

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(endpoint, json=payload, headers=headers)
                if response.status_code == 200:
                    return response.json()
        except Exception:
            # Silent fallback to local for performance (sync-points calculation is fast)
            pass

    # --- 🏠 LOCAL FALLBACK EXECUTION ---
    from coozila.studio.audio.analyzer.engine import AudioSyncEngine
    cut_points = AudioSyncEngine.get_cut_points(analysis_data, num_shots)
    
    return {
        "status": "success",
        "cut_points": cut_points,
        "count": len(cut_points)
    }