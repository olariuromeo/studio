# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/otio/builder.py
# Description: OTIO Architect. Converts audio analysis into a synchronized schema.

import os
import logging
import opentimelineio as otio
from coozila.audio.analyzer import AudioSyncEngine

logger = logging.getLogger(__name__)

class AudioTimelineBuilder:
    """
    Constructs an OTIO structure based on rhythmic audio analysis.
    """

    def __init__(self, fps: float = 24.0):
        self.fps = fps
        self.sync_engine = AudioSyncEngine()

    def build_from_audio(self, audio_path: str, num_shots: int = 10):
        """
        Analyzes audio and generates an OTIO timeline with beat-synced clips.
        Returns the OTIO timeline object.
        """
        logger.info(f"🎵 [OTIO BUILDER] Initializing timeline for: {os.path.basename(audio_path)}")
        
        # 1. Audio Analysis (BPM & Beat points)
        analysis = self.sync_engine.analyze_track(audio_path)
        cut_points = self.sync_engine.get_cut_points(analysis, num_shots)
        
        # 2. Initialize OTIO Timeline
        timeline = otio.schema.Timeline(name="Coozila_Studio_Project")
        video_track = otio.schema.Track(name="Video_Track", kind=otio.schema.TrackKind.Video)
        audio_track = otio.schema.Track(name="Master_Audio", kind=otio.schema.TrackKind.Audio)
        
        timeline.tracks.append(video_track)
        timeline.tracks.append(audio_track)

        # 3. Add Master Audio Reference
        duration_frames = otio.opentime.RationalTime(analysis["total_duration"], 1).rescaled_to(self.fps)
        
        audio_ref = otio.schema.ExternalReference(
            target_url=os.path.abspath(audio_path),
            available_range=otio.opentime.TimeRange(
                start_time=otio.opentime.RationalTime(0, self.fps),
                duration=duration_frames
            )
        )
        audio_clip = otio.schema.Clip(name="Main_Audio", media_reference=audio_ref)
        audio_track.append(audio_clip)

        # 4. Generate Video Clips (Shots) aligned to Beats
        last_time = 0.0
        for i, cut_time in enumerate(cut_points):
            duration = cut_time - last_time
            clip_duration = otio.opentime.RationalTime(duration, 1).rescaled_to(self.fps)
            
            shot_name = f"Shot_{i+1:03d}"
            clip = otio.schema.Clip(
                name=shot_name,
                source_range=otio.opentime.TimeRange(
                    start_time=otio.opentime.RationalTime(0, self.fps),
                    duration=clip_duration
                )
            )
            
            # Inject Coozila! Metadata for the Studio Canvas
            clip.metadata["Coozila"] = {
                "shot_id": i + 1,
                "bpm_sync": True,
                "target_fps": self.fps,
                "status": "pending_generation"
            }
            
            video_track.append(clip)
            last_time = cut_time

        logger.info(f"✅ [OTIO BUILDER] Timeline built with {len(video_track)} beat-synced shots.")
        return timeline