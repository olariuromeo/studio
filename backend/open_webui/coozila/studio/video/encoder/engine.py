# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/video/encoder/engine.py
# Description: Mastering Engine. Handles final video encoding and audio muxing.
# ----------------------------------------------------------------------------------#

import subprocess
import logging
import os
from coozila.studio.config import DEFAULT_FPS

logger = logging.getLogger(__name__)

class VideoMasteringEngine:
    """
    Final Stage of the Coozila Pipeline.
    Assembles frames and audio into a production-ready container.
    """

    @staticmethod
    async def render_final_video(input_path: str, audio_path: str, output_path: str, fps: int = DEFAULT_FPS):
        """
        Executes FFmpeg process to mux video and audio.
        Uses libx264 for maximum compatibility across all devices.
        """
        if not os.path.exists(input_path):
            return {"status": "error", "message": f"Input file/directory not found: {input_path}"}

        # FFmpeg Command: Standard Production Mastering
        command = [
            'ffmpeg', '-y',
            '-framerate', str(fps),
            '-i', input_path,
            '-i', audio_path,
            '-c:v', 'libx264',
            '-preset', 'medium',
            '-crf', '18',
            '-c:a', 'aac',
            '-b:a', '192k',
            '-shortest',
            '-pix_fmt', 'yuv420p',
            output_path
        ]

        try:
            logger.info(f"Starting mastering process: {output_path}")
            # Running with subprocess to manage external FFmpeg binary
            process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate()

            if process.returncode != 0:
                error_msg = stderr.decode()
                logger.error(f"FFmpeg Error: {error_msg}")
                return {"status": "error", "message": error_msg}

            return {"status": "success", "output": output_path}
        except Exception as e:
            logger.error(f"Mastering engine failure: {str(e)}")
            return {"status": "error", "message": str(e)}