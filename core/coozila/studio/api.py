# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: backend/open_webui/coozila/video/studio/api.py
# Description: Studio API Bridge. Connects the Svelte Frontend to the 
#              VideoStudioManager Orchestrator. 

from fastapi import APIRouter, Request, HTTPException
from pydantic import BaseModel
import json
import logging

# Importăm Managerul folosind calea absolută configurată pentru Open WebUI
from open_webui.studio.orchestrator import VideoStudioManager

router = APIRouter()
logger = logging.getLogger(__name__)

# --- 📝 MODELE DE DATE (Request Validation) ---

class StudioAction(BaseModel):
    session_id: str
    action: str
    payload: dict = {}

# --- 🚀 RUTELE API ---

@router.post("/action")
async def handle_studio_action(data: StudioAction, request: Request):
    """
    Endpoint principal pentru acțiunile din Studio Canvas.
    Gestionează comunicarea între Frontend și Orchestrator.
    """
    # Verificăm utilizatorul autentificat în contextul Open WebUI
    user = getattr(request.state, "user", None)
    if not user:
        raise HTTPException(status_code=401, detail="Neautorizat - Sesiune invalidă")

    # Inițializăm Managerul pentru sesiunea curentă
    manager = VideoStudioManager(data.session_id, user.id)
    
    logger.info(f"🎬 [STUDIO API] Action: {data.action} | Session: {data.session_id}")

    # 1. Obținere Schema (Proiectul curent)
    if data.action == "get_schema":
        return {"status": "success", "schema": manager.schema}
    
    # 2. Aplicare Stil din Librărie
    elif data.action == "apply_style":
        style_id = data.payload.get("style_id")
        success = manager.apply_style_from_library(style_id)
        return {"status": "success" if success else "error", "schema": manager.schema}

    # 3. Sincronizare Audio (BPM & Timeline)
    elif data.action == "sync_audio":
        audio_path = data.payload.get("audio_path")
        template_id = data.payload.get("template_id", "default")
        await manager.auto_sync_timeline_to_audio(audio_path, template_id)
        return {"status": "success", "schema": manager.schema}

    # 4. Lansare Render (Preview sau Final)
    elif data.action == "render":
        is_preview = data.payload.get("is_preview", True)
        audio_path = data.payload.get("audio_path")
        
        if is_preview:
            job_result = await manager.request_preview(audio_path)
        else:
            job_result = await manager.finalize_production(audio_path)
            
        return {"status": "success", "output": job_result}
    
    return {"status": "error", "message": "Unknown Studio Action"}

# Mesaj de confirmare în consolă la pornirea Open WebUI
print("🚀 Coozila Studio API Router: LOADED & READY")