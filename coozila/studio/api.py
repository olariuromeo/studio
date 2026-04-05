# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/api.py
# Description: Studio API Bridge. Orchestrates Audio, Video, and Remote Scaling.
#              Aggregates distributed sub-modules into a unified namespace.
# ----------------------------------------------------------------------------------#

from fastapi import APIRouter, Request, HTTPException
from pydantic import BaseModel
import logging

# --- COOZILA INTERNAL MODULES ---
from coozila.studio.config import INTERNAL_TOKEN
from coozila.studio.orchestrator import VideoStudioManager

# --- DISTRIBUTED CLIENTS (Hybrid Microservices) ---
from coozila.studio.video.upscaler.client import trigger_upscale
from coozila.studio.video.interpolation.client import trigger_interpolation
from coozila.studio.video.encoder.client import trigger_final_mastering
from coozila.studio.audio.analyzer.client import trigger_audio_analysis, get_sync_points

# --- SUB-ROUTERS IMPORT ---
from coozila.studio.video.interpolation.api import router as interpolation_router
from coozila.studio.video.upscaler.api import router as upscaler_router
from coozila.studio.video.encoder.api import router as encoder_router
from coozila.studio.audio.analyzer.api import router as audio_router

# Initialize the root Studio router
router = APIRouter(prefix="/api/v1/coozila/studio", tags=["Studio Core"])
logger = logging.getLogger(__name__)

# --- MOUNT HIERARCHICAL SUB-ROUTERS ---
# Video Domain: /api/v1/coozila/studio/video/...
router.include_router(interpolation_router, prefix="/video")
router.include_router(upscaler_router, prefix="/video")
router.include_router(encoder_router, prefix="/video")

# Audio Domain: /api/v1/coozila/studio/audio/...
router.include_router(audio_router, prefix="/audio")


# --- DATA MODELS ---

class StudioAction(BaseModel):
    session_id: str
    action: str
    payload: dict = {}

class RenderRequest(BaseModel):
    input_path: str
    audio_path: str
    output_path: str
    is_preview: bool = True
    use_remote_nodes: bool = True


# --- CORE STUDIO ROUTES ---

@router.post("/action")
async def handle_studio_action(data: StudioAction, request: Request):
    """
    Main endpoint for Studio Canvas actions.
    Coordinates session state via VideoStudioManager.
    """
    # Logic remains local to the Studio Orchestrator
    user_id = getattr(request.state, "user_id", "default_user")
    manager = VideoStudioManager(data.session_id, user_id)
    
    logger.info(f"Studio Action: {data.action} | Session: {data.session_id}")

    if data.action == "get_schema":
        return {"status": "success", "schema": manager.schema}
    
    elif data.action == "sync_audio":
        audio_path = data.payload.get("audio_path")
        # Uses the Audio Client to decide Local vs Remote
        analysis = await trigger_audio_analysis(audio_path)
        success = await manager.apply_audio_analysis(analysis)
        return {"status": "success" if success else "error", "schema": manager.schema}

    raise HTTPException(status_code=400, detail=f"Action '{data.action}' unknown.")


@router.post("/render")
async def start_render(data: RenderRequest):
    """
    Triggers the cinematic rendering pipeline using Hybrid Scaling.
    Delegates Interpolation, Upscaling, and Encoding based on NODE_REGISTRY.
    """
    logger.info(f"Initiating Render Pipeline for: {data.output_path}")
    
    try:
        # Phase 1: Interpolation (if not preview)
        if not data.is_preview:
            await trigger_interpolation(data.input_path)

        # Phase 2: High-Res Upscaling
        await trigger_upscale(data.input_path)

        # Phase 3: Final Mastering (Muxing Video + Audio)
        result = await trigger_final_mastering(
            input_path=data.input_path,
            audio_path=data.audio_path,
            output_path=data.output_path
        )
        
        return result

    except Exception as e:
        logger.error(f"Render Pipeline Failure: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# System initialization log
print("Coozila Studio API (Root Namespace): Video & Audio Hierarchies Mounted.")