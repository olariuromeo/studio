# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/main.py
# Description: Main Entry Point for the Studio Engine. 
#              Aggregates agnostic routers into a unified FastAPI service.
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
    title="Studio API Engine",
    version="4.1.0-OSS",
    debug=DEBUG_MODE
)

# --- 1. CORS MIDDLEWARE ---
# Configures Cross-Origin Resource Sharing for distributed environments.
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
    Enforces the INTERNAL_TOKEN for all distributed studio calls.
    Protects the agnostic /api/v1/studio namespace.
    """
    if request.url.path.startswith("/api/v1/studio"):
        auth_header = request.headers.get("Authorization")
        if not auth_header or INTERNAL_TOKEN not in auth_header:
            logger.warning(f"Unauthorized access attempt from: {request.client.host}")
            return JSONResponse(
                status_code=403, 
                content={"detail": "Unauthorized: Invalid Internal Token"}
            )
    return await call_next(request)

# --- 3. PERFORMANCE MONITORING MIDDLEWARE ---
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """
    Captures API latency for performance tracking of AI tasks.
    """
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

# --- 4. MOUNT AGNOSTIC ROUTERS ---
# studio_router includes sub-modules for /video and /audio hierarchies.
app.include_router(studio_router)

# --- 5. SYSTEM ENDPOINTS ---

@app.get("/")
async def root():
    """
    Root endpoint for service identification.
    """
    return {
        "status": "online",
        "engine": "Studio API Engine",
        "version": "4.1.0-OSS",
        "timestamp": time.time()
    }

@app.get("/health", tags=["System"])
async def global_health():
    """
    Health check endpoint for infrastructure monitoring.
    """
    return {
        "status": "healthy",
        "subsystems": {
            "studio": "active",
            "video_engine": "initialized",
            "audio_engine": "initialized"
        }
    }

# --- EXECUTION BLOCK ---
if __name__ == "__main__":
    import uvicorn
    from urllib.parse import urlparse

    # Extract Host and Port from environment-defined STUDIO_URL.
    parsed_url = urlparse(STUDIO_URL)
    host = parsed_url.hostname or "0.0.0.0"
    port = parsed_url.port or 8000

    logger.info(f"Starting Engine on {host}:{port} (Debug: {DEBUG_MODE})")
    
    uvicorn.run(
        "coozila.main:app", 
        host=host, 
        port=port, 
        reload=DEBUG_MODE
    )