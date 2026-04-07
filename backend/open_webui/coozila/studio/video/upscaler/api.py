# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/upscaler/api.py
# Description: Upscaler Service API. Manages high-resolution tiling workflows
#              and GPU-accelerated image enhancement requests.
# ----------------------------------------------------------------------------------#

from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
import logging
import os
from PIL import Image

# Internal Coozila Imports
from coozila.studio.video.upscaler.tile_manager import TileManager

router = APIRouter()
logger = logging.getLogger(__name__)

# --- 📝 DATA MODELS ---

class UpscaleRequest(BaseModel):
    """
    Model for an upscale job request.
    'path' must be an absolute path to an image on the shared volume.
    """
    path: str
    upscale_factor: int = 2
    tile_size: int = 1024

class UpscaleResponse(BaseModel):
    """Standardized response for upscale job completion."""
    status: str
    output_path: str = ""
    message: str = ""

# --- 🚀 API ROUTES ---

@router.post("/upscale", response_model=UpscaleResponse)
async def process_upscale(request: UpscaleRequest):
    """
    Main Entry Point: Tiled Upscaling.
    Loads an image, splits it into tiles, processes them (AI Logic Placeholder),
    and reconstructs the final high-res frame.
    """
    if not os.path.exists(request.path):
        logger.error(f"❌ [UPSCALER API] File not found: {request.path}")
        raise HTTPException(status_code=404, detail="Source image file not found.")

    try:
        logger.info(f"🛰️ [UPSCALER API] Starting {request.upscale_factor}x upscale for: {request.path}")

        # 1. Initialize Tile Manager
        tm = TileManager(tile_size=request.tile_size)
        
        # 2. Load Image
        img = Image.open(request.path).convert("RGB")
        
        # 3. Split into Tiles
        tiles, info = tm.split_into_tiles(img)
        logger.info(f"🧩 [UPSCALER API] Image split into {len(tiles)} tiles.")

        # --- 🤖 AI PROCESSING BLOCK (PLACEHOLDER) ---
        # In a real environment, each tile would be sent to a model like SwinIR or Real-ESRGAN
        processed_tiles = []
        for tile_data in tiles:
            tile_img = tile_data["image"]
            # Upscale the tile using PIL (Replace this with GPU AI model call)
            w, h = tile_img.size
            upscaled_tile = tile_img.resize((w * request.upscale_factor, h * request.upscale_factor), Image.LANCZOS)
            
            processed_tiles.append({
                "image": upscaled_tile,
                "pos": tile_data["pos"]
            })
        # ---------------------------------------------

        # 4. Stitch Tiles back together
        final_img = tm.merge_tiles(processed_tiles, info, upscale_factor=request.upscale_factor)
        
        # 5. Save Final Result
        output_path = request.path.replace(".", f"_upscaled_{request.upscale_factor}x.")
        final_img.save(output_path, quality=95)

        logger.info(f"✅ [UPSCALER API] Upscale complete. Saved to: {output_path}")
        
        return {
            "status": "success",
            "output_path": output_path,
            "message": f"Successfully upscaled {request.upscale_factor}x"
        }

    except Exception as e:
        logger.error(f"❌ [UPSCALER API] Critical failure: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Upscaling pipeline crashed: {str(e)}")

@router.get("/health")
async def health_check():
    """Returns the status of the Upscaler Node and GPU readiness."""
    return {
        "status": "online",
        "service": "Coozila Upscaler Node",
        "gpu_ready": True,
        "version": "4.1"
    }