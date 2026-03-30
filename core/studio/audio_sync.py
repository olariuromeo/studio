# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: coozila/video/studio/audio_sync.py
# Description: Audio Analysis Engine. Detects BPM, onset strength, and rhythmic 
#              patterns to calculate beat-perfect transition points for the 
#              Studio Timeline.

import librosa
import numpy as np

class AudioSyncEngine:
    """
    Analizează ritmul muzicii pentru a genera puncte de montaj (sync points).
    """
    
    @staticmethod
    def analyze_track(audio_path):
        """
        Detectează BPM-ul și secundele exacte ale beat-urilor.
        """
        try:
            # Încărcăm audio (librosa este standardul industrial pentru asta)
            y, sr = librosa.load(audio_path)
            
            # 1. Detectăm tempo-ul (BPM)
            tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
            
            # 2. Convertim cadrele de beat în secunde
            beat_times = librosa.frames_to_time(beat_frames, sr=sr)
            
            # 3. Calculăm durata totală
            total_duration = librosa.get_duration(y=y, sr=sr)
            
            return {
                "bpm": round(float(tempo), 2),
                "beat_timestamps": beat_times.tolist(),
                "total_duration": round(total_duration, 2)
            }
        except Exception as e:
            print(f"-> Audio Analysis Error: {e}")
            return {"bpm": 120, "beat_timestamps": [], "total_duration": 30.0}

    @staticmethod
    def get_cut_points(analysis, num_shots):
        """
        Alege cele mai bune momente pentru 'cut' dintr-o listă de beat-uri, 
        astfel încât să avem numărul de shot-uri cerut de Regie.
        """
        beats = analysis["beat_timestamps"]
        if not beats:
            # Fallback dacă nu detectăm beat-uri: împărțire egală
            return [i * (analysis["total_duration"] / num_shots) for i in range(1, num_shots + 1)]

        # Împărțim beat-urile în segmente aproximativ egale pentru numărul de cadre
        idx = np.round(np.linspace(0, len(beats) - 1, num_shots + 1)).astype(int)
        cut_points = [beats[i] for i in idx[1:]]
        
        # Ne asigurăm că ultimul punct este fix sfârșitul melodiei
        cut_points[-1] = analysis["total_duration"]
        
        return cut_points