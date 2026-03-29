# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

import json
import random
import copy

def build_precise_payload(base_template_json, clip_params, audio_url, global_style_config, is_preview=True):
    """
    Asamblează payload-ul ComfyUI. 
    Dacă is_preview=True -> Folosește LoRA Distill (Nod 107) + Puțini pași (Nod 103).
    Dacă is_preview=False -> Dezactivează LoRA sau crește calitatea + Pași mulți.
    """
    workflow = copy.deepcopy(base_template_json)
    
    # 1. GENERARE PROMPT (Stil + Acțiune)
    style_tags = global_style_config.get("custom_style_reference") or ""
    action_description = clip_params["name"]
    final_positive = f"[Style Tags]: {style_tags}\n\n[Action]: {action_description}"
    
    # 2. INJECȚIE DATE DE BAZĂ
    workflow["6"]["inputs"]["text"] = final_positive
    workflow["7"]["inputs"]["text"] = global_style_config.get("global_negative_prompt", "")
    workflow["52"]["inputs"]["image"] = clip_params["media_url"]
    workflow["58"]["inputs"]["audio"] = audio_url
    workflow["104"]["inputs"]["value"] = clip_params["frames"]
    
    # 3. LOGICA DE CALITATE (PREVIEW VS FINAL)
    if is_preview:
        # Folosim LoRA de Distill (Nod 107) la putere maximă
        workflow["107"]["inputs"]["strength_model"] = 1.0
        # Reducem pașii pentru viteză (Nod 103) - ex: 8 pași pentru distill
        workflow["103"]["inputs"]["value"] = 8 
        # CFG mai mic (Nod 105) adecvat pentru distill
        workflow["105"]["inputs"]["value"] = 3.5
    else:
        # Final Render: Dezactivăm LoRA-ul de preview (Nod 107)
        workflow["107"]["inputs"]["strength_model"] = 0.0
        # Creștem pașii pentru calitate maximă (Nod 103)
        workflow["103"]["inputs"]["value"] = 25
        # CFG standard pentru Wan 2.2
        workflow["105"]["inputs"]["value"] = 6.0

    # 4. SEMINȚE ȘI RE-WIRING (Extensii 79:76, 85:184)
    main_seed = clip_params["seed"]
    workflow["3"]["inputs"]["seed"] = main_seed
    
    # Actualizăm toate nodurile de KSampler (inclusiv extensiile)
    ksampler_ids = ["3", "79:77", "85:183"]
    for i, node_id in enumerate(ksampler_ids):
        if node_id in workflow:
            workflow[node_id]["inputs"]["seed"] = main_seed + i
            # Ne asigurăm că extensiile respectă noile setări de pași/CFG
            workflow[node_id]["inputs"]["steps"] = ["103", 0]
            workflow[node_id]["inputs"]["cfg"] = ["105", 0]

    # Prefix fișier (Node 113)
    phase_prefix = "PREVIEW" if is_preview else "FINAL"
    workflow["113"]["inputs"]["filename_prefix"] = f"studio_{phase_prefix}_{main_seed}"

    return workflow