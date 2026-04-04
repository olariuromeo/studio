# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/audio/analyzer.py
# Description: Audio Analysis Engine using Librosa to detect BPM and rhythmic beats.

import librosa
import numpy as np
import logging

logger = logging.getLogger(__name__)

class AudioSyncEngine:
    """
    Analyzes music rhythm to generate synchronization points (cuts) for the timeline.
    """
    
    @staticmethod
    def analyze_track(audio_path: str):
        """
        Detects BPM and exact timestamps for musical beats.
        """
        try:
            # Load audio file (Librosa is the industry standard)
            y, sr = librosa.load(audio_path)
            
            # 1. Detect tempo (BPM) and beat frames
            tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
            
            # 2. Convert beat frames to seconds
            beat_times = librosa.frames_to_time(beat_frames, sr=sr)
            
            # 3. Calculate total duration
            total_duration = librosa.get_duration(y=y, sr=sr)
            
            # Extract tempo value (handle array if needed)
            bpm_val = tempo[0] if isinstance(tempo, np.ndarray) else tempo

            return {
                "bpm": round(float(bpm_val), 2),
                "beat_timestamps": beat_times.tolist(),
                "total_duration": round(total_duration, 2)
            }
        except Exception as e:
            logger.error(f"❌ [AUDIO ANALYZER] Analysis Error: {e}")
            # Safe Fallback
            return {"bpm": 120, "beat_timestamps": [], "total_duration": 30.0}

    @staticmethod
    def get_cut_points(analysis: dict, num_shots: int):
        """
        Selects the best 'cut' moments from the beat list to match the required number of shots.
        """
        beats = analysis["beat_timestamps"]
        duration = analysis["total_duration"]

        if not beats:
            # Fallback: Equal division if no beats are detected
            return [i * (duration / num_shots) for i in range(1, num_shots + 1)]

        # Linearly space indices to pick beats based on required shot count
        idx = np.round(np.linspace(0, len(beats) - 1, num_shots + 1)).astype(int)
        cut_points = [beats[i] for i in idx[1:]]
        
        # Ensure the last point matches the exact end of the audio
        cut_points[-1] = duration
        
        return cut_points