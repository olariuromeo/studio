# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: coozila/video/studio/schema_exporter.py
# Description: Standards & Interoperability module. Converts the dynamic 
#              STUDIO_SCHEMA into professional industry formats (FCPXML) and 
#              portable JSON packages for style sharing and archiving.

import json
import os
import xml.etree.ElementTree as ET
from datetime import datetime
from .memory_manager import load_project_state

def export_to_json_package(session_id, user_id):
    """
    Exportă proiectul complet (Schema + Stiluri + Metadata) într-un format 
    portabil care poate fi importat de orice alt asistent Coozila.
    """
    project_data = load_project_state(session_id)
    if not project_data:
        return None

    export_package = {
        "header": {
            "software": "Coozila Studio",
            "version": "2026.1",
            "export_date": datetime.now().isoformat(),
            "user_origin": user_id,
            "project_name": project_data.get("name", "Untitled Project")
        },
        "payload": project_data # STUDIO_SCHEMA complet, inclusiv global_config
    }
    
    return json.dumps(export_package, indent=4)

def export_to_fcpxml(session_id):
    """
    Traduce STUDIO_SCHEMA în format FCPXML 1.13 pentru software-uri de 
    editare profesională (Final Cut, Premiere, DaVinci).
    """
    schema = load_project_state(session_id)
    if not schema:
        return None

    # Rădăcina XML
    root = ET.Element("fcpxml", version="1.13")
    resources = ET.SubElement(root, "resources")
    
    # Format standard 1080p 24fps (cum am stabilit în RationalTime)
    ET.SubElement(resources, "format", id="r1", name="FFVideoFormat1080p24", 
                  frameDuration="1/24s", width="1920", height="1080")

    library = ET.SubElement(root, "library")
    event = ET.SubElement(library, "event", name=schema.get("name", "Coozila_Event"))
    project = ET.SubElement(event, "project", name=schema.get("name", "Coozila_Project"))
    sequence = ET.SubElement(project, "sequence", format="r1", duration="30s", tcStart="0s")
    spine = ET.SubElement(sequence, "spine")

    # Parcurgem track-ul video din Schema
    video_track = schema["tracks"]["children"][0] # Presupunem 0 = Video
    for idx, clip in enumerate(video_track["children"]):
        asset_id = f"r{idx+2}"
        target_url = clip["media_references"]["DEFAULT_MEDIA"]["target_url"]
        
        # Adăugăm resursa
        asset = ET.SubElement(resources, "asset", id=asset_id, name=clip["name"])
        ET.SubElement(asset, "media-rep", kind="original-media", src=target_url)

        # Adăugăm clipul în timeline (RationalTime translation)
        val = clip["source_range"]["duration"]["value"]
        rate = clip["source_range"]["duration"]["rate"]
        duration_str = f"{int(val)}/{int(rate)}s"
        
        ET.SubElement(spine, "asset-clip", name=clip["name"], ref=asset_id, 
                      duration=duration_str, start="0s", offset="0s")

    # Generăm string-ul XML
    return ET.tostring(root, encoding='utf-8', method='xml').decode('utf-8')

def save_export_file(content, filename, user_id, extension="json"):
    """Salvează fișierul de export în folderul de descărcări al userului."""
    export_dir = f"coozila/video/studio/users/{user_id}/exports"
    os.makedirs(export_dir, exist_ok=True)
    
    path = os.path.join(export_dir, f"{filename}.{extension}")
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    
    return path