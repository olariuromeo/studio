# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/api.py
# Description: Agnostic Studio API Bridge. Orchestrates Audio and Video services
#              via a unified, hierarchical namespace.
# ----------------------------------------------------------------------------------#

from fastapi import APIRouter, Request, HTTPException
from pydantic import BaseModel
import logging

# --- ORCHESTRATION & CONFIG ---
from coozila.studio.config import INTERNAL_TOKEN
from coozila.studio.orchestrator import VideoStudioManager

# --- HYBRID CLIENTS (Routing to Local/Remote Nodes) ---
from coozila.studio.video.upscaler.client import trigger_upscale
from coozila.studio.video.interpolation.client import trigger_interpolation
from coozila.studio.video.encoder.client import trigger_final_mastering
from coozila.studio.audio.analyzer.client import trigger_audio_analysis

# --- SUB-ROUTERS (Internal Modules) ---
from coozila.studio.video.interpolation.api import router as interpolation_router
from coozila.studio.video.upscaler.api import router as upscaler_router
from coozila.studio.video.encoder.api import router as encoder_router
from coozila.studio.audio.analyzer.api import router as audio_router

# 1. Initialize the Agnostic Root Router
# Namespace: /api/v1/studio
router = APIRouter(prefix="/api/v1/studio", tags=["Studio Core"])
logger = logging.getLogger(__name__)

# 2. Mount Domain-Specific Hierarchies
# Video Domain -> /api/v1/studio/video/...
router.include_router(interpolation_router, prefix="/video")
router.include_router(upscaler_router, prefix="/video")
router.include_router(encoder_router, prefix="/video")

# Audio Domain -> /api/v1/studio/audio/...
router.include_router(audio_router, prefix="/audio")


# --- DATA MODELS ---

class StudioAction(BaseModel):
    """Payload for interactive canvas actions."""
    session_id: str
    action: str
    payload: dict = {}

class RenderRequest(BaseModel):
    """Payload for triggering the final mastering pipeline."""
    input_path: str
    audio_path: str
    output_path: str
    is_preview: bool = True
    use_remote_nodes: bool = True


# --- CORE API ENDPOINTS ---

@router.post("/action")
async def handle_studio_action(data: StudioAction, request: Request):
    """
    Gateway for Studio UI interactions.
    Manages session state and triggers specialized analysis tasks.
    """
    # Extract user context (handled by auth middleware)
    user_id = getattr(request.state, "user_id", "anonymous_user")
    manager = VideoStudioManager(data.session_id, user_id)
    
    logger.info(f"Studio Action: {data.action} | Session: {data.session_id}")

    # A. Retrieve Current Project State
    if data.action == "get_schema":
        return {"status": "success", "schema": manager.schema}
    
    # B. Trigger Rhythmic Synchronization
    elif data.action == "sync_audio":
        audio_path = data.payload.get("audio_path")
        if not audio_path:
            raise HTTPException(status_code=400, detail="Missing audio_path in payload")
            
        # Analysis is routed via Hybrid Client (Local/Remote)
        analysis = await trigger_audio_analysis(audio_path)
        success = await manager.apply_audio_analysis(analysis)
        
        return {"status": "success" if success else "error", "schema": manager.schema}

    raise HTTPException(status_code=400, detail=f"Action '{data.action}' not recognized.")


@router.post("/render")
async def start_render(data: RenderRequest):
    """
    Orchestrates the multi-stage rendering pipeline.
    Leverages distributed nodes for heavy AI computation.
    """
    logger.info(f"Starting Render Pipeline: {data.output_path}")
    
    try:
        # Step 1: Temporal Interpolation (RIFE/Flow)
        if not data.is_preview:
            logger.info("Phase 1: Frame Interpolation")
            await trigger_interpolation(data.input_path)

        # Step 2: Spatial Upscaling (8K Tiled)
        logger.info("Phase 2: High-Resolution Upscaling")
        await trigger_upscale(data.input_path)

        # Step 3: Video/Audio Mastering (FFmpeg Muxing)
        logger.info("Phase 3: Final Mastering/Encoding")
        result = await trigger_final_mastering(
            input_path=data.input_path,
            audio_path=data.audio_path,
            output_path=data.output_path
        )
        
        return result

    except Exception as e:
        logger.error(f"Render Failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Pipeline error: {str(e)}")

# Initialization confirmation for system logs
print("Studio API Bridge: Namespace /api/v1/studio mounted successfully.")