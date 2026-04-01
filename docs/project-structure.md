# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: project-structure.md
# Description: System Architecture and Directory Map for Coozila! Studio.
# ----------------------------------------------------------------------------------#

# 🏗️ Coozila! Video Studio Architecture

The ecosystem relies on an **Overlay & Orchestration** model:
* **Open-WebUI**: The User Interface (Frontend Host).
* **ComfyUI**: The Execution & Rendering Engine (GPU Backend).
* **Coozila! Studio**: The Orchestrator (Canvas & API Tools) that bridges the UI and the engine, preparing data via LLM (Gemini) and managing the video timeline.

## ⚙️ The 5 Phases of the Studio Orchestrator

1. **Pre-Production (Studio Canvas)**
   * *Asset Ingestion*: Uploading reference images and audio via Open-WebUI into ComfyUI shared volumes.
   * *Scene Breakdown*: Gemini 1.5 Pro analyzes audio/lyrics and generates the Canvas table with Scenes, Shots, and Prompts.
   * *Audio Splitting*: Automatic track slicing (3-8 second chunks) using Librosa algorithms.
   * *Storyboard*: Generating keyframes via the ComfyUI API and validating them on the Canvas.
2. **AI Production (Generation Loops)**
   * *Batch Video*: Sending approved keyframes and audio chunks to WanVideo / LivePortrait.
   * *Progress Tracking*: Real-time status monitoring in the Open-WebUI interface.
3. **Offline Editing (Automated Assembly)**
   * *Timeline Conform*: Stitching generated clips over the original audio track (FFmpeg Stitcher) into a low-res video preview.
4. **Finishing (Online Engine)**
   * *High Frame Rate*: 64 FPS temporal interpolation via RIFE in ComfyUI.
   * *8K Tiled Upscale*: Ultimate Upscale processing with strict RAM/VRAM memory management to prevent out-of-memory crashes.
5. **Delivery (Final Master)**
   * *Mastering & Export*: AV1/H.265 encoding (High Bitrate 200Mbps+) and delivering the direct download link.

---

## 📂 Directory Map

The structure is highly modular, separating injection logic (`compose/`), frontend logic (`canvas/`), and the backend orchestrator (`core/`).

### 📁 Project Root (`~/data/dev/apps/coozila-studio/`)
* `docker-compose.yml` - The supreme commander linking networks, volumes, and services.
* `apply_patches.py` - Pre-build injection script (executed from the root context).
* `README.md` / `docs/` / `LICENSE` - Project documentation.
* `apps/` - Contains the clean upstream submodules (Open-WebUI and ComfyUI). **Strictly do not edit manually.**
* `sessions/` - *(Directory)* **[Planned - Dynamic]** Will store active project states as JSON files.
* `exports/` - *(Directory)* **[Planned - Dynamic]** The final destination for rendered `.mp4` master files.
* `temp_chunks/` - *(Directory)* **[Planned - Dynamic]** Temporary storage for raw AI-generated video chunks before FFmpeg assembly.

### 🎨 Frontend Canvas (`/canvas/`)
Contains the Svelte/JS logic injected into Open-WebUI to display the orchestrator's GUI.
* `StudioCanvas.svelte` - Main Svelte component (The Visual Timeline Interface).
* `studio_tab.js` - UI Injector (adds the "✨ Studio" button).
* `orchestrator.js` - Manages client-side logical flow and state.
* `audio_engine.js` - Controls waveform rendering and browser previews.
* `canvas.js` - Logic for drawing and interacting with clip blocks.
* `studio.json` - Local configuration for the frontend extension.
* **`/components/`** - *(Directory)* **[In Development]** Modular Svelte components for a cleaner architecture.
  * `TimelineTrack.svelte` - **[Planned]** Dedicated component for video/audio tracks.
  * `ExportModal.svelte` - **[Planned]** UI for selecting codec, bitrate, and resolution before rendering.
* **`/templates/`** - JSON data models for generation:
  * `master_schema.json` - NLE timeline structure (Timeline.1).
  * `default_schema.json` - Default settings for a new project.
  * `styles.json` - Aesthetic prompt library.
  * `shot_presets.json` - Camera movement blueprints (Orbit, Pan, Zoom).



### 🧠 Backend Core (`/core/studio/`)
The Python logic acting as the API Gateway, Tool Provider for Gemini, and Orchestrator for ComfyUI. It has no GUI; it exclusively receives and returns JSON/Links.
* `api.py` - Communication bridge (API routes injected into the Open-WebUI backend).
* `video_studio_orchestrator.py` & `orchestrator.py` - The central brain managing project states and execution phases (1 to 5).
* `tool_video_studio.py` - The Tool exposed to the LLM (Gemini) to trigger generation and assembly functions.
* `audio_sync.py` - Audio slicing engine (Librosa) for BPM and tempo matching.
* `payload_factory.py` - Assembles ComfyUI prompts (JSON graphs) from scene chunks.
* `comfy_client.py` - Manages HTTP/WebSocket connections to the ComfyUI API.
* `style_engine.py` & `style_analyzer.py` - Translates visual "vibes" into technical Wan 2.2 / FLUX prompts.
* `schema_engine.py` & `schema_exporter.py` - Manipulates the video structure JSON for NLE export.
* `media_processor.py` - FFmpeg wrapper for video assembly and exporting (Phases 3 and 5).
* `memory_manager.py` - Monitors VRAM/RAM during the 8K upscaling process (Phase 4).
* `config.py` - Environment variables and static paths.
* `shot_presets.py` - Backend handler for camera motion parameters.
* `__init__.py` - Python module initializer.
* `requirements.txt` - Python-specific dependencies (librosa, ffmpeg-python, etc.).
* `queue_manager.py` - **[In Development]** Will handle the reliable queueing of batch clip generation (e.g., 92+ clips) to prevent ComfyUI overload.
* `error_recovery.py` - **[Planned]** Logic to catch ComfyUI timeouts or rendering failures and automatically retry specific chunks.
* `llm_prompt_optimizer.py` - **[Planned]** An internal refiner to format Gemini's raw output strictly for LTX-2.3/Wan 2.2 syntax.

### 🐳 Build & Patches (`/compose/`)
The recipe for building the modified Docker images (The Overlay).
* **`/open-webui/`**
  * `Dockerfile` - Extracts sources from `apps/`, applies root patches, and compiles the frontend.
  * **`/src/routes/+layout.svelte`** - Specific Svelte injection point.
  * **`/backend/open_webui/main.py`** - Backend injection point for API routing.
* **`/comfyui/`** - *(Directory)* **[Planned]**
  * `Dockerfile` - **[Planned]** Custom Coozila! environment build for ComfyUI to pre-install specific node dependencies (like `ffmpeg` or custom python modules) without polluting the host.