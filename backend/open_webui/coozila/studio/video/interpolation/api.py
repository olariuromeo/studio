# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/video/interpolation/api.py
# Description: Sub-module API for Frame Interpolation.
# ----------------------------------------------------------------------------------#

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import logging
from coozila.studio.video.interpolation.engine import local_interpolation_process

# Prefix matches the folder name for consistency
router = APIRouter(prefix="/interpolation", tags=["Video Processing"])
logger = logging.getLogger(__name__)

class InterpolationRequest(BaseModel):
    input_path: str
    target_fps: int = 60

@router.post("/process")
async def process_interpolation(data: InterpolationRequest):
    """
    Handles interpolation requests. 
    Accessible via: /api/v1/coozila/studio/video/interpolation/process
    """
    logger.info(f"Interpolation request: {data.input_path}")
    try:
        output_path = await local_interpolation_process(data.input_path, data.target_fps)
        return {"status": "success", "output": output_path}
    except Exception as e:
        logger.error(f"Interpolation error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))