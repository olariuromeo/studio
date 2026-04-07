# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: coozila/video/studio/comfy_client.py
# Description: API Bridge. Handles POST requests to ComfyUI queue and implements 
#              polling logic to monitor render completion and file retrieval 
#              from Node 113 (Save Video).

import json
import requests
import time

def queue_prompt(payload_json, server_address="127.0.0.1:8188"):
    """
    Sends the dynamically built workflow to the ComfyUI queue.
    """
    p = {"prompt": payload_json}
    url = f"http://{server_address}/prompt"
    
    try:
        response = requests.post(url, json=p)
        response.raise_for_status()
        return response.json()      # Returns the prompt_id
    except requests.exceptions.RequestException as e:
        print(f"Failed to send prompt to ComfyUI: {e}")
        return None

def check_history(prompt_id, server_address="127.0.0.1:8188"):
    """
    Checks if a specific prompt_id has finished processing and is in the history.
    """
    url = f"http://{server_address}/history/{prompt_id}"
    
    try:
        response = requests.get(url)
        response.raise_for_status()
        history_data = response.json()
        
        # If the prompt_id is in the dictionary keys, it means it's done.
        if prompt_id in history_data:
            return history_data[prompt_id]
        return None
    except requests.exceptions.RequestException:
        return None

def send_to_comfyui_and_wait(payload_json, server_address="127.0.0.1:8188"):
    """
    Orchestrates the API flow: sends the prompt, waits for it to finish, 
    and extracts the final video filename from the outputs.
    """
    print(f"-> Sending job to ComfyUI ({server_address})...")
    
    # 1. Trimitem job-ul la coadă
    queue_response = queue_prompt(payload_json, server_address)
    
    if not queue_response or "prompt_id" not in queue_response:
        print("Error: Could not queue prompt. Check if ComfyUI is running.")
        return None
        
    prompt_id = queue_response["prompt_id"]
    print(f"-> Job queued! ID: {prompt_id}. Waiting for render...")
    
    # 2. Bucla de Polling (Interogăm serverul până e gata)
    history = None
    while history is None:
        time.sleep(5) # Așteptăm 5 secunde între verificări pentru a nu sufoca CPU-ul
        history = check_history(prompt_id, server_address)
        
    # 3. Extragem calea fișierului randat
    print("-> Rendering complete! Extracting video path...")
    try:
        # Folosim Nodul 113 conform șablonului tău pentru Wan 2.2
        outputs = history.get('outputs', {})
        save_video_node_id = "113" 
        
        if save_video_node_id in outputs:
            videos = outputs[save_video_node_id].get("videos", [])
            if videos:
                filename = videos[0]["filename"]
                subfolder = videos[0].get("subfolder", "")
                
                # Reconstruim calea relativă
                final_path = f"{subfolder}/{filename}" if subfolder else filename
                print(f"-> Success! Video saved as: {final_path}")
                return final_path
                
        print(f"Warning: Job {prompt_id} finished, but Node {save_video_node_id} has no output.")
        return None
        
    except Exception as e:
        print(f"Error parsing history for Job {prompt_id}: {e}")
        return None