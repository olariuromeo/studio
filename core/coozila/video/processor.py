# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/video/processor.py
# Description: The "Assembly Line". Executes FFmpeg commands to concatenate 
#              video chunks, synchronize audio, and extract frames for continuity.

import subprocess
import os
import logging

# Logger configuration for monitoring FFmpeg subprocesses
logger = logging.getLogger(__name__)

def merge_videos_and_audio_ffmpeg(chunks: list, audio_path: str, output_filename: str):
    """
    Concatenates video fragments and overlays the final audio track.
    Uses the demuxer method for maximum efficiency without unnecessary re-encoding.
    """
    if not chunks:
        logger.error("❌ [MEDIA PROCESSOR] No video chunks provided for merging.")
        return None

    # 1. Create a temporary list file for FFmpeg concat demuxer
    list_file = "concat_list.txt"
    try:
        with open(list_file, "w") as f:
            for chunk in chunks:
                # FFmpeg requires correct absolute paths in the list file
                f.write(f"file '{os.path.abspath(chunk)}'\n")

        logger.info(f"🎬 [MEDIA PROCESSOR] Merging {len(chunks)} chunks with audio: {audio_path}")
        
        # 2. FFmpeg Command Logic:
        # -f concat: Uses the concatenation demuxer
        # -c:v copy: Copies video stream without re-encoding (ultra-fast)
        # -c:a aac: Encodes audio to a standard compatible format
        # -shortest: Finish encoding when the shortest stream (video or audio) ends
        
        command = [
            "ffmpeg", "-y", 
            "-f", "concat", "-safe", "0", "-i", list_file,
            "-i", audio_path,
            "-c:v", "copy", 
            "-c:a", "aac", 
            "-b:a", "192k",
            "-shortest",
            output_filename
        ]

        subprocess.run(command, check=True, capture_output=True)
        logger.info(f"✅ [MEDIA PROCESSOR] Final video mastered: {output_filename}")
        
        return output_filename

    except subprocess.CalledProcessError as e:
        logger.error(f"❌ [FFMPEG ERROR] {e.stderr.decode()}")
        return None
    finally:
        # Always clean up the temporary list file
        if os.path.exists(list_file):
            os.remove(list_file)

def extract_last_frame(video_path: str, output_image_path: str):
    """
    Extracts the final frame from a video clip. 
    Used by the Assistant to generate a 'Start Frame' for the subsequent scene.
    """
    try:
        # Seek near the end of the file (-sseof) to extract the last frame efficiently
        command = [
            "ffmpeg", "-y",
            "-sseof", "-0.1", 
            "-i", video_path,
            "-update", "1", 
            "-q:v", "2",
            "-vframes", "1",
            output_image_path
        ]
        subprocess.run(command, check=True, capture_output=True)
        logger.info(f"🖼️ [MEDIA PROCESSOR] Continuity frame extracted to: {output_image_path}")
        return output_image_path
    except subprocess.CalledProcessError as e:
        logger.error(f"❌ [FFMPEG ERROR] Failed to extract last frame: {e.stderr.decode()}")
        return None