# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/main.py
# Description: Main Entry Point for Coozila Studio. Mounts all service routers.
#              Configured via .env / .env.dev for distributed environments.
# ----------------------------------------------------------------------------------#

import time
import logging
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# --- IMPORT CONFIGURATION & ROUTERS ---
from coozila.studio.config import (
    setup_logging, 
    DEBUG_MODE, 
    INTERNAL_TOKEN,
    STUDIO_URL
)
from coozila.studio.api import router as studio_router

# Initialize System Logging
setup_logging()
logger = logging.getLogger("coozila.core")

app = FastAPI(
    title="Coozila! Studio API",
    version="4.1-Production",
    debug=DEBUG_MODE
)

# --- 1. CORS MIDDLEWARE ---
# Essential for frontend-backend communication (Svelte/React/Open WebUI)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 2. SECURITY MIDDLEWARE (Internal Token Verification) ---
@app.middleware("http")
async def verify_internal_token(request: Request, call_next):
    """
    Enforces the INTERNAL_TOKEN for all distributed node calls.
    Ensures that only authorized nodes can access the studio namespace.
    """
    if request.url.path.startswith("/api/v1/coozila"):
        auth_header = request.headers.get("Authorization")
        if not auth_header or INTERNAL_TOKEN not in auth_header:
            logger.warning(f"Unauthorized access attempt from: {request.client.host}")
            return JSONResponse(
                status_code=403, 
                content={"detail": "Unauthorized: Invalid Coozila Internal Token"}
            )
    return await call_next(request)

# --- 3. PERFORMANCE MONITORING MIDDLEWARE ---
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """
    Tracks API latency to monitor render and analysis performance.
    """
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

# --- 4. MOUNT HIERARCHICAL ROUTERS ---
# studio_router already contains /video and /audio sub-routers via coozila.studio.api
app.include_router(studio_router)

# --- 5. CORE ENDPOINTS ---

@app.get("/", tags=["System"])
async def root():
    """
    Base landing for the Coozila API.
    """
    return {
        "status": "online",
        "engine": "Coozila! Studio Server",
        "version": "4.1",
        "timestamp": time.time()
    }

@app.get("/health", tags=["System"])
async def global_health():
    """
    Global health check for infrastructure monitoring systems.
    """
    return {
        "status": "healthy",
        "subsystems": {
            "studio": "active",
            "video_engine": "initialized",
            "audio_engine": "initialized"
        },
        "debug_mode": DEBUG_MODE
    }

# --- 🚀 EXECUTION BLOCK ---
if __name__ == "__main__":
    import uvicorn
    import os
    from urllib.parse import urlparse

    # Extract Host and Port from STUDIO_URL defined in .env
    # Example: http://127.0.0.1:8000 -> host="127.0.0.1", port=8000
    parsed_url = urlparse(STUDIO_URL)
    host = parsed_url.hostname or "0.0.0.0"
    port = parsed_url.port or 8000

    logger.info(f"Starting Coozila Engine on {host}:{port} (Debug: {DEBUG_MODE})")
    
    uvicorn.run(
        "coozila.main:app", 
        host=host, 
        port=port, 
        reload=DEBUG_MODE
    )