# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: studio/audio_timeline_builder.py
# Description: The OTIO Architect. Converts audio analysis into a synchronized 
#              OpenTimelineIO schema for the Studio Canvas.
# ----------------------------------------------------------------------------------#

import os
import opentimelineio as otio
from .audio_sync import AudioSyncEngine

class AudioTimelineBuilder:
    """
    Construiește structura OTIO bazată pe analiza ritmului audio.
    """

    def __init__(self, fps=24.0):
        self.fps = fps
        self.sync_engine = AudioSyncEngine()

    def build_from_audio(self, audio_path, output_otio_path, num_shots=10):
        """
        Analizează audio-ul și generează un timeline OTIO cu clipuri sync-uite pe beat.
        """
        print(f"🎵 [OTIO] Building timeline for: {os.path.basename(audio_path)}")
        
        # 1. Analiză Audio (BPM & Beat points)
        analysis = self.sync_engine.analyze_track(audio_path)
        cut_points = self.sync_engine.get_cut_points(analysis, num_shots)
        
        # 2. Inițializare Timeline OTIO
        timeline = otio.schema.Timeline(name="Coozila_Studio_Project")
        video_track = otio.schema.Track(name="Video_Track", kind=otio.schema.TrackKind.Video)
        audio_track = otio.schema.Track(name="Master_Audio", kind=otio.schema.TrackKind.Audio)
        
        timeline.tracks.append(video_track)
        timeline.tracks.append(audio_track)

        # 3. Adăugăm Referința Audio Master
        audio_ref = otio.schema.ExternalReference(
            target_url=os.path.abspath(audio_path),
            available_range=otio.opentime.TimeRange(
                start_time=otio.opentime.RationalTime(0, self.fps),
                duration=otio.opentime.RationalTime(analysis["total_duration"], 1).rescaled_to(self.fps)
            )
        )
        audio_clip = otio.schema.Clip(name="Audio_Track", media_reference=audio_ref)
        audio_track.append(audio_clip)

        # 4. Generăm Clipuri Video (Shots) aliniate la Beat-uri
        last_time = 0.0
        for i, cut_time in enumerate(cut_points):
            duration = cut_time - last_time
            
            # Creăm un clip "Placeholder" care va fi înlocuit de randarea AI
            shot_name = f"Shot_{i+1:03d}"
            clip = otio.schema.Clip(
                name=shot_name,
                source_range=otio.opentime.TimeRange(
                    start_time=otio.opentime.RationalTime(0, self.fps), # Fiecare render începe de la 0
                    duration=otio.opentime.RationalTime(duration, 1).rescaled_to(self.fps)
                )
            )
            
            # Injectăm metadate Coozila! (Aici punem Prompt-ul sau Actorul mai târziu)
            clip.metadata["Coozila"] = {
                "shot_id": i + 1,
                "bpm_sync": True,
                "target_fps": self.fps,
                "prompt": "Pending AI Generation..."
            }
            
            video_track.append(clip)
            last_time = cut_time

        # 5. Salvare fișier OTIO
        otio.adapters.write_to_file(timeline, output_otio_path)
        print(f"✅ [SUCCESS] Timeline saved to: {output_otio_path}")
        return output_otio_path

# --- TEST UNITAR (Rulare directă pentru verificare) ---
if __name__ == "__main__":
    # Testăm dacă avem un fișier audio de test (pune o cale validă aici)
    test_audio = "data/assets/test_track.wav" 
    if os.path.exists(test_audio):
        builder = AudioTimelineBuilder()
        builder.build_from_audio(test_audio, "studio/project_v1.otio")
    else:
        print("ℹ️  [INFO] Trimite o cale audio validă pentru a genera un OTIO de test.")