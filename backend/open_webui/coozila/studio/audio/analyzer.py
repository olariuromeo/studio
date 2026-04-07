# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/studio/audio/analyzer/engine.py
# Description: Core Audio Analysis Engine using Librosa.
# ----------------------------------------------------------------------------------#

import librosa
import numpy as np
import logging
import os

logger = logging.getLogger(__name__)

class AudioSyncEngine:
    """
    Rhythmic analysis engine for frame-accurate musical synchronization.
    """
    
    @staticmethod
    def analyze_track(audio_path: str) -> dict:
        """
        Extracts BPM and beat timestamps from a source audio file.
        """
        try:
            if not os.path.exists(audio_path):
                raise FileNotFoundError(f"Audio file not found: {audio_path}")

            # Load signal at default 22050Hz for optimized peak detection
            y, sr = librosa.load(audio_path)
            
            # Extract dominant tempo and rhythmic onset frames
            tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
            
            # Map frames to absolute time in seconds
            beat_times = librosa.frames_to_time(beat_frames, sr=sr)
            total_duration = librosa.get_duration(y=y, sr=sr)
            
            # Handle BPM as float
            bpm_val = tempo[0] if isinstance(tempo, np.ndarray) else tempo

            logger.info(f"Audio analysis complete: {round(float(bpm_val), 1)} BPM.")

            return {
                "status": "success",
                "bpm": round(float(bpm_val), 2),
                "beat_timestamps": beat_times.tolist(),
                "total_duration": round(total_duration, 2)
            }

        except Exception as e:
            logger.error(f"Audio analysis failed: {str(e)}")
            return {
                "status": "error",
                "bpm": 120.0, 
                "beat_timestamps": [], 
                "total_duration": 30.0
            }

    @staticmethod
    def get_cut_points(analysis: dict, num_shots: int) -> list:
        """
        Calculates shot transition points aligned to the nearest musical beats.
        """
        beats = analysis.get("beat_timestamps", [])
        duration = analysis.get("total_duration", 30.0)

        if not beats:
            return [i * (duration / num_shots) for i in range(1, num_shots + 1)]

        # Map shots to the closest detected beats to prevent rhythmic drift
        idx = np.round(np.linspace(0, len(beats) - 1, num_shots + 1)).astype(int)
        cut_points = [beats[i] for i in idx[1:]]
        
        # Ensure the last shot aligns with the end of the track
        cut_points[-1] = duration
        return cut_points