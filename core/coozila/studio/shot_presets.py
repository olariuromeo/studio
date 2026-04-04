# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

import json
import os

def load_cinematic_templates():
    """
    Încarcă baza de date cu șabloane cinematografice din JSON.
    """
    path = "coozila/video/studio/templates/shot_presets.json"
    if not os.path.exists(path):
        return {}
        
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

# Putem păstra o referință rapidă pentru Orchestrator
TEMPLATES = load_cinematic_templates()