# ----------------------------------------------------------------------------------#
# Location: coozila/studio/video/encoder/api.py
# Description: REST API for Video Mastering. Exposes the engine to the network.
# ----------------------------------------------------------------------------------#

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import logging
from coozila.studio.video.encoder.engine import VideoMasteringEngine

router = APIRouter(prefix="/encoder", tags=["Video Mastering"])
logger = logging.getLogger(__name__)

class EncodingRequest(BaseModel):
    input_path: str
    audio_path: str
    output_path: str
    fps: int = 24

@router.post("/process")
async def process_encoding(data: EncodingRequest):
    """
    Endpoint for final video mastering.
    Accessible via: /api/v1/coozila/studio/video/encoder/process
    """
    logger.info(f"Encoding request received for: {data.output_path}")
    result = await VideoMasteringEngine.render_final_video(
        data.input_path, data.audio_path, data.output_path, data.fps
    )
    
    if result["status"] == "error":
        raise HTTPException(status_code=500, detail=result["message"])
        
    return result