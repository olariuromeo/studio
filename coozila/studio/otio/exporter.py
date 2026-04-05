# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/otio/exporter.py
# Description: Advanced OTIO Exporter. Generates professional-grade timelines
#              with rich AI metadata for xStudio review and playback.
# ----------------------------------------------------------------------------------#

import os
import logging
import opentimelineio as otio
from datetime import datetime

# Internal Coozila Imports
from coozila.studio.session import load_project_state

logger = logging.getLogger(__name__)

def export_to_otio_file(session_id: str, output_filename: str = None) -> str:
    """
    Converts the STUDIO_SCHEMA into a native .otio file.
    Includes rich Coozila-specific metadata for xStudio visual overlays.
    """
    schema = load_project_state(session_id)
    if not schema:
        logger.error(f"❌ [OTIO EXPORTER] Project state not found for {session_id}")
        return ""

    # 1. Create the OTIO Timeline
    timeline = otio.schema.Timeline(name=schema.get("name", "Coozila_Project"))
    video_track = otio.schema.Track(name="Main Video", kind=otio.schema.TrackKind.Video)
    timeline.tracks.append(video_track)

    # Global Metadata for the entire project
    timeline.metadata["coozila"] = {
        "engine_version": "v4.1-Wan2.2",
        "export_date": datetime.now().isoformat(),
        "style_id": schema["metadata"].get("active_style_id"),
        "global_negative": schema["metadata"].get("global_negative_prompt")
    }

    try:
        # 2. Iterate through Clips in the Schema
        clips_data = schema["tracks"]["children"][0].get("children", [])
        
        for idx, clip_data in enumerate(clips_data):
            # Calculate timing
            duration_val = clip_data["source_range"]["duration"]["value"]
            rate = clip_data["source_range"]["duration"]["rate"]
            
            # Create the OTIO Clip
            clip = otio.schema.Clip(
                name=clip_data.get("name", f"Shot_{idx+1}"),
                source_range=otio.opentime.TimeRange(
                    start_time=otio.opentime.RationalTime(0, rate),
                    duration=otio.opentime.RationalTime(duration_val, rate)
                )
            )

            # --- 🧠 THE AI INTELLIGENCE BUNDLE (For xStudio) ---
            # This metadata allows xStudio to show "HUD" overlays for the director
            clip.metadata["coozila"] = {
                "shot_id": idx + 1,
                "vibe": clip_data["metadata"].get("vibe", "cinematic"),
                "motion": clip_data["metadata"].get("motion", 5),
                "ai_prompt": schema["metadata"].get("custom_style_reference", ""),
                "status": "ready_for_review"
            }

            # 3. Add Media Reference
            target_url = clip_data["media_references"]["DEFAULT_MEDIA"]["target_url"]
            # We use an ExternalReference so xStudio knows where to find the rendered MP4
            clip.media_reference = otio.schema.ExternalReference(
                target_url=os.path.abspath(target_url),
                available_range=clip.source_range
            )

            video_track.append(clip)

        # 4. Save the .otio file
        export_path = f"data/coozila/exports/{session_id}.otio"
        os.makedirs(os.path.dirname(export_path), exist_ok=True)
        
        otio.adapters.write_to_file(timeline, export_path)
        
        logger.info(f"🎬 [OTIO EXPORTER] Master Timeline exported to: {export_path}")
        return export_path

    except Exception as e:
        logger.error(f"❌ [OTIO EXPORTER] Export failed: {str(e)}")
        return ""