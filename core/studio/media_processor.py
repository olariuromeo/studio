# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: coozila/video/studio/media_processor.py
# Description: The "Assembly Line". Executes FFmpeg commands to concatenate 
#              video chunks, synchronize audio, and extract frames for continuity.

import subprocess
import os
import logging

# Configurare logging pentru monitorizarea proceselor FFmpeg
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("MediaProcessor")

def merge_videos_and_audio_ffmpeg(chunks, audio_path, output_filename):
    """
    Concatenează fragmentele video și adaugă piesa audio finală.
    Folosește metoda demuxer pentru eficiență maximă fără re-encodare inutilă.
    """
    if not chunks:
        logger.error("No video chunks provided for merging.")
        return None

    # 1. Creăm un fișier temporar cu lista de clipuri pentru FFmpeg concat
    list_file = "concat_list.txt"
    with open(list_file, "w") as f:
        for chunk in chunks:
            # FFmpeg necesită căi absolute sau relative corecte în fișierul de listă
            f.write(f"file '{os.path.abspath(chunk)}'\n")

    try:
        logger.info(f"Merging {len(chunks)} chunks with audio: {audio_path}")
        
        # 2. Comanda FFmpeg:
        # -f concat: folosește metoda de concatenare
        # -i concat_list.txt: lista de fișiere
        # -i audio_path: fișierul audio
        # -c:v copy: copiază stream-ul video fără re-encodare (viteză maximă)
        # -c:a aac -shortest: encodează audio și oprește-te la cel mai scurt stream (video/audio)
        
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
        logger.info(f"Final video successfully created: {output_filename}")
        
        # Curățăm fișierul temporar de listă
        os.remove(list_file)
        return output_filename

    except subprocess.CalledProcessError as e:
        logger.error(f"FFmpeg Error: {e.stderr.decode()}")
        if os.path.exists(list_file): os.remove(list_file)
        return None

def extract_last_frame(video_path, output_image_path):
    """
    Extrage ultimul cadru dintr-un clip video. 
    Utilizat de Asistent pentru a genera 'Start Frame' pentru următoarea scenă.
    """
    try:
        # Comanda caută ultimul cadru și îl salvează ca imagine
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
        return output_image_path
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to extract last frame: {e.stderr.decode()}")
        return None