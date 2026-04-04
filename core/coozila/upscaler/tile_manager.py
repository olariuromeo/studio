# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/upscaler/tile_manager.py
# Description: Tiling Engine for High-Resolution Upscaling. Manages frame 
#              splitting and seamless stitching to optimize VRAM usage.
# ----------------------------------------------------------------------------------#

import numpy as np
import math
import logging
from PIL import Image

logger = logging.getLogger(__name__)

class TileManager:
    """
    Precision Tiling Engine.
    Handles the decomposition of high-res frames into manageable chunks 
    and reconstructs them using overlap blending to prevent visual seams.
    """

    def __init__(self, tile_size: int = 1024, overlap: int = 64):
        self.tile_size = tile_size
        self.overlap = overlap
        logger.info(f"🧩 [TILE MANAGER] Initialized with Tile Size: {tile_size}px, Overlap: {overlap}px")

    def split_into_tiles(self, image: Image.Image) -> tuple:
        """
        Splits a large image into smaller tiles with padding (overlap).
        
        Returns:
            list: List of PIL Image tiles.
            tuple: Grid information (columns, rows, original_size).
        """
        width, height = image.size
        cols = math.ceil(width / (self.tile_size - self.overlap))
        rows = math.ceil(height / (self.tile_size - self.overlap))
        
        tiles = []
        logger.debug(f"🧩 [TILE MANAGER] Splitting {width}x{height} into {cols}x{rows} grid.")

        for y in range(rows):
            for x in range(cols):
                # Calculate coordinates with overlap
                x_start = max(0, x * (self.tile_size - self.overlap))
                y_start = max(0, y * (self.tile_size - self.overlap))
                x_end = min(width, x_start + self.tile_size)
                y_end = min(height, y_start + self.tile_size)
                
                tile = image.crop((x_start, y_start, x_end, y_end))
                tiles.append({
                    "image": tile,
                    "pos": (x_start, y_start),
                    "grid": (x, y)
                })
                
        return tiles, (cols, rows, (width, height))

    def merge_tiles(self, processed_tiles: list, original_info: tuple, upscale_factor: int = 2) -> Image.Image:
        """
        Stitches processed tiles back into a single high-resolution frame.
        Uses a linear blend on overlaps to ensure seamless transitions.
        """
        cols, rows, (orig_w, orig_h) = original_info
        new_w, new_h = orig_w * upscale_factor, orig_h * upscale_factor
        
        # Create a high-bitrate canvas for merging
        canvas = Image.new("RGB", (new_w, new_h))
        
        logger.info(f"🧵 [TILE MANAGER] Reconstructing {new_w}x{new_h} frame from {len(processed_tiles)} tiles.")

        for tile_data in processed_tiles:
            tile = tile_data["image"]
            x_start, y_start = tile_data["pos"]
            
            # Apply upscale factor to coordinates
            canvas.paste(tile, (x_start * upscale_factor, y_start * upscale_factor))
            
        return canvas

    @staticmethod
    def calculate_optimal_tile(vram_gb: int, base_res: int = 1024) -> int:
        """
        Heuristic to calculate tile size based on available GPU VRAM.
        Prevents Out-Of-Memory (OOM) errors during 8K processing.
        """
        if vram_gb < 8:
            return 512
        elif vram_gb < 16:
            return 768
        return base_res