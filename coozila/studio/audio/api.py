# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/audio/api.py
# Description: Audio Service API. Provides endpoints for BPM detection, 
#              rhythmic analysis, and beat-synced transition calculation.
# ----------------------------------------------------------------------------------#

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from typing import List, Dict, Any
import logging

# Internal imports from the Coozila namespace
from coozila.audio.analyzer import AudioSyncEngine

router = APIRouter()
logger = logging.getLogger(__name__)

# --- 📝 DATA MODELS (Pydantic Validation) ---

class AudioAnalysisRequest(BaseModel):
    """
    Data model for an audio analysis request.
    Requires an absolute path to the media file on the shared volume.
    """
    file_path: str

class SyncPointsRequest(BaseModel):
    """
    Data model for calculating rhythmic cut points.
    Accepts previously generated analysis data and the desired number of shots.
    """
    analysis_data: Dict[str, Any]
    num_shots: int

class AudioAnalysisResponse(BaseModel):
    """
    Standardized response for rhythmic metadata.
    """
    bpm: float
    beat_timestamps: List[float]
    total_duration: float
    status: str = "success"

# --- 🚀 API ENDPOINTS ---

@router.post("/analyze", response_model=AudioAnalysisResponse)
async def analyze_audio_track(request: AudioAnalysisRequest):
    """
    Endpoint: Full Rhythmic Scan.
    Processes the raw audio file to extract BPM and individual beat timestamps.
    This data is used by the Orchestrator to populate the OTIO Metadata.
    """
    logger.info(f"🎵 [AUDIO API] Initiating analysis for: {request.file_path}")
    
    # Trigger the heavy-lifting analysis engine
    analysis = AudioSyncEngine.analyze_track(request.file_path)
    
    # Check if the engine returned fallback data (indicating a potential processing failure)
    if not analysis.get("beat_timestamps") and analysis.get("bpm") == 120.0:
        logger.warning(f"⚠️ [AUDIO API] Analysis for {request.file_path} resulted in fallback data.")
    
    return analysis

@router.post("/sync-points")
async def get_rhythmic_cuts(request: SyncPointsRequest):
    """
    Endpoint: Beat-Synced Cut Calculation.
    Calculates the exact timestamps for video transitions based on musical peaks.
    Used for instant timeline updates when the director changes the number of shots.
    """
    logger.info(f"✂️ [AUDIO API] Calculating {request.num_shots} sync points for the timeline.")
    
    try:
        # Map the requested number of shots to the nearest musical beats
        cut_points = AudioSyncEngine.get_cut_points(
            request.analysis_data, 
            request.num_shots
        )
        
        return {
            "status": "success",
            "cut_points": cut_points,
            "count": len(cut_points)
        }
    except Exception as e:
        logger.error(f"❌ [AUDIO API] Rhythmic sync calculation failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail="Failed to calculate rhythmic sync points."
        )

@router.get("/health")
async def health_check():
    """
    Endpoint: Service Health Monitoring.
    Returns the status and version of the Coozila Audio Node.
    """
    return {
        "status": "online", 
        "service": "Coozila Audio Engine", 
        "version": "4.1-Distributed"
    }