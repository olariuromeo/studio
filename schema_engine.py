# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: coozila/video/studio/schema_engine.py
# Description: The "Living Schema" manager. It populates the base JSON template 
#              with dynamic shots, audio cues, and style metadata.

import json
import copy
from .styles import STYLE_PRESETS

def create_new_project(user_id, project_name):
    """Încarcă scheletul și îi dă o identitate."""
    with open('coozila/video/studio/templates/base_schema.json', 'r') as f:
        schema = json.load(f)
    schema["name"] = project_name
    schema["user_id"] = user_id
    return schema

def inject_shot(schema, shot_data):
    """Adaugă un clip nou în track-ul video din JSON-ul viu."""
    # Logica de a împinge (append) în schema["tracks"]["children"][0]["children"]
    schema["tracks"]["children"][0]["children"].append(shot_data)
    return schema