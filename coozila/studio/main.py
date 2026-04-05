# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/main.py
# Description: Main Application Entry Point. Aggregates all distributed routers 
#              (Studio, Audio, Upscaler) into a unified FastAPI service.
# ----------------------------------------------------------------------------------#

import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Import Coozila Unified Configuration
from coozila.studio.config import setup_logging, DEBUG_MODE, INTERNAL_TOKEN

# Import Specialized Service Routers
from coozila.studio.api import router as studio_router
from coozila.audio.api import router as audio_router
from coozila.upscaler.api import router as upscaler_router

# 1. Setup Global Logging
setup_logging()

# 2. Initialize FastAPI "The Tank"
app = FastAPI(
    title="Coozila! Studio Core",
    description="Unified AI Video Production Ecosystem (Wan 2.2 Optimized)",
    version="4.1.0",
    debug=DEBUG_MODE
)

# 3. Configure CORS (Cross-Origin Resource Sharing)
# Critical for allowing the Svelte/React frontend to talk to the Python backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 4. Security Middleware (Token Verification)
@app.middleware("http")
async def verify_internal_token(request: Request, call_next):
    """
    Optional: Enforces the INTERNAL_TOKEN for all Coozila API calls 
    to ensure only authorized nodes can talk to each other.
    """
    if request.url.path.startswith("/api/v1/coozila"):
        auth_header = request.headers.get("Authorization")
        if not auth_header or INTERNAL_TOKEN not in auth_header:
            return JSONResponse(
                status_code=403, 
                content={"detail": "Unauthorized: Invalid Coozila Internal Token"}
            )
    return await call_next(request)

# 5. Mount Service Routers
# Each module is isolated under its own namespace prefix
app.include_router(studio_router, prefix="/api/v1/coozila/studio", tags=["Studio Orchestrator"])
app.include_router(audio_router, prefix="/api/v1/coozila/audio", tags=["Audio Analysis"])
app.include_router(upscaler_router, prefix="/api/v1/coozila/upscale", tags=["8K Tiled Upscaler"])

# 6. Global Health Check
@app.get("/", tags=["System"])
async def root():
    return {
        "status": "online",
        "message": "Coozila! Studio Core v4.1 is operational.",
        "engine": "Wan 2.2 Ready"
    }

# --- 🚀 EXECUTION BLOCK ---
if __name__ == "__main__":
    # Start the engine using Uvicorn
    # In production, use environment variables for HOST and PORT
    uvicorn.run(
        "coozila.main:app", 
        host="0.0.0.0", 
        port=8000, 
        reload=DEBUG_MODE
    )