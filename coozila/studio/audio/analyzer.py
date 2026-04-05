# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/audio/analyzer.py
# Description: Audio Analysis Engine. Uses Librosa for rhythmic feature extraction,
#              tempo detection (BPM), and onset synchronization.
# ----------------------------------------------------------------------------------#

import librosa
import numpy as np
import logging

# Initialize logger for the audio module
logger = logging.getLogger(__name__)

class AudioSyncEngine:
    """
    The Rhythmic Heart of Coozila Studio.
    This engine extracts mathematical timing data from audio files to ensure
    that video transitions (cuts) happen exactly on musical beats.
    """
    
    @staticmethod
    def analyze_track(audio_path: str) -> dict:
        """
        Performs a full rhythmic scan of an audio file.
        
        Args:
            audio_path (str): Absolute path to the source audio file (.wav, .mp3, etc.)
            
        Returns:
            dict: A dictionary containing:
                - bpm (float): Detected Beats Per Minute.
                - beat_timestamps (list): List of seconds where each beat occurs.
                - total_duration (float): Total length of the track in seconds.
        """
        try:
            # 1. LOAD AUDIO SIGNAL
            # 'y' is the audio time series, 'sr' is the sampling rate.
            # Librosa defaults to 22050Hz, which is perfect for rhythmic analysis.
            y, sr = librosa.load(audio_path)
            
            # 2. TEMPO & BEAT TRACKING
            # beat_track identifies the dominant global tempo and the frames where beats hit.
            # It uses an onset envelope to find periodic peaks in energy.
            tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
            
            # 3. FRAME TO TIME CONVERSION
            # Convert internal frame indices (integer positions) to absolute seconds (float).
            beat_times = librosa.frames_to_time(beat_frames, sr=sr)
            
            # 4. DURATION CALCULATION
            # Get the precise total length of the audio file.
            total_duration = librosa.get_duration(y=y, sr=sr)
            
            # Ensure BPM is handled as a float (Librosa might return an array in some versions)
            bpm_val = tempo[0] if isinstance(tempo, np.ndarray) else tempo

            logger.info(f"🎵 [AUDIO ANALYZER] Analysis complete: {round(float(bpm_val), 1)} BPM detected.")

            return {
                "bpm": round(float(bpm_val), 2),
                "beat_timestamps": beat_times.tolist(),
                "total_duration": round(total_duration, 2)
            }

        except Exception as e:
            logger.error(f"❌ [AUDIO ANALYZER] Failed to process audio: {str(e)}")
            # Safe Fallback: Standard 120 BPM tempo with a 30s default duration
            return {
                "bpm": 120.0, 
                "beat_timestamps": [], 
                "total_duration": 30.0
            }

    @staticmethod
    def get_cut_points(analysis: dict, num_shots: int) -> list:
        """
        Calculates optimized transition timestamps (cuts) based on detected beats.
        
        This logic ensures that shots are not just equal in length, but are 
        mathematically aligned with the closest musical peak.
        
        Args:
            analysis (dict): The dictionary returned by analyze_track().
            num_shots (int): The number of video clips required for the timeline.
            
        Returns:
            list: A list of timestamps (seconds) where each video shot should end.
        """
        beats = analysis.get("beat_timestamps", [])
        duration = analysis.get("total_duration", 30.0)

        # CASE A: NO BEATS DETECTED (Fallback)
        # If the audio is silent or lacks a clear rhythm, we divide time equally.
        if not beats:
            logger.warning("⚠️ [AUDIO ANALYZER] No clear beats detected. Using linear division.")
            return [i * (duration / num_shots) for i in range(1, num_shots + 1)]

        # CASE B: RHYTHMIC ALIGNMENT (The Magic)
        # We use linspace to find 'ideal' cut indices, then map them to the nearest actual beats.
        # This prevents the timeline from drifting out of sync over time.
        idx = np.round(np.linspace(0, len(beats) - 1, num_shots + 1)).astype(int)
        cut_points = [beats[i] for i in idx[1:]]
        
        # FINAL ADJUSTMENT
        # We force the last cut point to be exactly at the end of the duration
        # to avoid empty frames or audio overhang.
        cut_points[-1] = duration
        
        logger.info(f"✂️ [AUDIO ANALYZER] Generated {len(cut_points)} beat-perfect cut points.")
        return cut_points