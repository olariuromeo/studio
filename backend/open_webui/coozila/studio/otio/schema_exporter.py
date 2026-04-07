# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/otio/exporter.py
# Description: Standards & Interoperability module. Converts STUDIO_SCHEMA into 
#              professional formats (FCPXML) and portable JSON project packages.

import json
import os
import xml.etree.ElementTree as ET
from datetime import datetime
import logging

# Internal Imports
from coozila.studio.session import load_project_state

logger = logging.getLogger(__name__)

def export_project_json(session_id: str, user_id: str) -> str:
    """
    Exports the complete project (Schema + Styles + Metadata) into a 
    portable format for sharing between Coozila instances.
    """
    project_data = load_project_state(session_id)
    if not project_data:
        logger.error(f"❌ [EXPORTER] No project found for session: {session_id}")
        return ""

    export_package = {
        "header": {
            "software": "Coozila Studio",
            "version": "2026.1",
            "export_date": datetime.now().isoformat(),
            "user_origin": user_id,
            "project_name": project_data.get("name", "Untitled_Project")
        },
        "payload": project_data 
    }
    
    return json.dumps(export_package, indent=4)

def export_to_fcpxml(session_id: str) -> str:
    """
    Translates STUDIO_SCHEMA to FCPXML 1.13 format for professional 
    NLE software (Final Cut Pro, Premiere, DaVinci Resolve).
    """
    schema = load_project_state(session_id)
    if not schema:
        return ""

    # XML Root setup
    root = ET.Element("fcpxml", version="1.13")
    resources = ET.SubElement(root, "resources")
    
    # Standard format: 1080p 24fps (aligned with RationalTime logic)
    ET.SubElement(resources, "format", id="r1", name="FFVideoFormat1080p24", 
                  frameDuration="1/24s", width="1920", height="1080")

    library = ET.SubElement(root, "library")
    event = ET.SubElement(library, "event", name=schema.get("name", "Coozila_Event"))
    project = ET.SubElement(event, "project", name=schema.get("name", "Coozila_Project"))
    sequence = ET.SubElement(project, "sequence", format="r1", tcStart="0s")
    spine = ET.SubElement(sequence, "spine")

    try:
        # Traverse the primary video track from the Schema
        video_track = schema["tracks"]["children"][0]
        
        for idx, clip in enumerate(video_track.get("children", [])):
            asset_id = f"r{idx+2}"
            target_url = clip["media_references"]["DEFAULT_MEDIA"]["target_url"]
            
            # Add resource asset
            asset = ET.SubElement(resources, "asset", id=asset_id, name=clip["name"])
            ET.SubElement(asset, "media-rep", kind="original-media", src=os.path.abspath(target_url))

            # Timeline placement (RationalTime conversion)
            val = clip["source_range"]["duration"]["value"]
            rate = clip["source_range"]["duration"]["rate"]
            duration_str = f"{int(val)}/{int(rate)}s"
            
            ET.SubElement(spine, "asset-clip", name=clip["name"], ref=asset_id, 
                          duration=duration_str, start="0s", offset="0s")
            
        logger.info(f"🎞️ [EXPORTER] Generated FCPXML for project: {schema.get('name')}")
        return ET.tostring(root, encoding='utf-8', method='xml').decode('utf-8')

    except (KeyError, IndexError) as e:
        logger.error(f"❌ [EXPORTER] XML translation failed: {str(e)}")
        return ""

def save_export(content: str, filename: str, user_id: str, extension: str = "json") -> str:
    """
    Saves the export file into the persistent data directory for user downloads.
    """
    # Using the standardized data persistence path
    export_dir = f"data/coozila/exports/user_{user_id}"
    os.makedirs(export_dir, exist_ok=True)
    
    clean_filename = filename.replace(" ", "_").lower()
    path = os.path.join(export_dir, f"{clean_filename}.{extension}")
    
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    
    logger.info(f"📁 [EXPORTER] File saved to: {path}")
    return path