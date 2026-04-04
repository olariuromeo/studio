# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/api.py
# Description: Studio API Bridge. Orchestrates Audio, Video, and Remote Scaling.

from fastapi import APIRouter, Request, HTTPException
from pydantic import BaseModel
import logging

# --- 🛰️ COOZILA ECOSYSTEM IMPORTS ---
# Importing the Manager from the Root Namespace
from coozila.studio.orchestrator import VideoStudioManager

# Importing Clients for Distributed Nodes (Microservices)
from coozila.upscaler.client import trigger_upscale
from coozila.interpolation.client import trigger_interpolation
from coozila.encoder.client import trigger_final_mastering

router = APIRouter()
logger = logging.getLogger(__name__)

# --- 📝 DATA MODELS (Request Validation) ---

class StudioAction(BaseModel):
    session_id: str
    action: str
    payload: dict = {}

class RenderRequest(BaseModel):
    path: str
    is_preview: bool = True
    use_remote_upscale: bool = False

# --- 🚀 API ROUTES ---

@router.post("/action")
async def handle_studio_action(data: StudioAction, request: Request):
    """
    Main endpoint for Studio Canvas actions.
    Manages communication between the Frontend and the Orchestrator.
    """
    # Verify authenticated user within Open WebUI context
    user = getattr(request.state, "user", None)
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized - Invalid Session")

    # Initialize Manager from the Coozila Namespace
    manager = VideoStudioManager(data.session_id, user.id)
    logger.info(f"🎬 [STUDIO API] Action: {data.action} | Session: {data.session_id}")

    # 1. Project Schema Management (OTIO Context)
    if data.action == "get_schema":
        return {"status": "success", "schema": manager.schema}
    
    # 2. Audio Synchronization (Pulse & Analysis)
    elif data.action == "sync_audio":
        audio_path = data.payload.get("audio_path")
        await manager.auto_sync_timeline_to_audio(audio_path)
        return {"status": "success", "schema": manager.schema}

    # 3. Style Application / Casting
    elif data.action == "apply_style":
        style_id = data.payload.get("style_id")
        success = manager.apply_style_from_library(style_id)
        return {"status": "success" if success else "error", "schema": manager.schema}

    return {"status": "error", "message": f"Action '{data.action}' not recognized."}

@router.post("/render")
async def start_render(data: RenderRequest):
    """
    Handles the rendering pipeline. 
    Can run locally or delegate tasks to remote nodes (Upscaler/RIFE).
    """
    logger.info(f"🎥 [RENDER ENGINE] Starting process for: {data.path}")
    
    try:
        # If High-Res Upscale is requested (Phase C)
        if data.use_remote_upscale:
            logger.info("📡 [REMOTE] Delegating to Tiled Upscaler Node...")
            status = await trigger_upscale(data.path)
            return {"status": "delegated", "node": "upscaler", "response": status}

        # Standard Preview Execution (Phase A)
        # Here we could call local logic or an interpolation client
        return {"status": "success", "message": "Render started successfully."}
        
    except Exception as e:
        logger.error(f"❌ [RENDER ERROR] {str(e)}")
        raise HTTPException(status_code=500, detail=f"Render pipeline failed: {str(e)}")

# Confirmation message for the Open-WebUI logs
print("🚀 [COOZILA] Studio API (Root Namespace): LOADED & READY")