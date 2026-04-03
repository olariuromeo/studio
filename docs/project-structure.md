# 🏗️ Coozila! Video Studio Architecture

The ecosystem relies on an **Overlay & Orchestration** model built on a Bare-Metal Multi-VENV architecture:
* **Open-WebUI**: The User Interface (Frontend Host).
* **ComfyUI**: The Execution & Rendering Engine (Headless GPU Backend).
* **Coozila! Studio**: The Orchestrator. It acts as the Canvas manager and Tool/API provider. Gemini/GPT prepares the data and triggers these APIs. **Crucially, Studio communicates with ComfyUI exclusively via headless JSON API payloads, receiving back paths to temporary `output/` files.**

## ⚙️ The 5 Phases of the Studio Orchestrator

1. **Pre-Production (Studio Canvas)**
   * **Asset Ingestion**: `File_Uploader` stores reference images and video into shared local folders accessible by ComfyUI.
   * **Scene Breakdown & Scripting**: LLM Engine (Gemini 1.5 Pro) analyzes lyrics/audio, generating a Canvas table with Scenes, Shots, and Prompts.
   * **Audio Splitting & Analysis**: `Audio_Slicer_API` uses Librosa/PyDub to cut the track into 3-8 second chunks and extract high-energy peaks for dynamic transitions.
   * **Storyboard & Scenography Generation**: `ComfyUI_API_Gateway` sends prompt payloads to ComfyUI. Uses **Prompt-Relay** on static images to ensure visually locked environments (consistent world-building) before any video is generated.

2. **AI Production (Generation Loops)**
   * **Dynamic Intra-Shot Routing**: Studio dynamically writes Prompt-Relay mathematical instructions based on audio peaks, allowing a single continuous video shot to evolve (e.g., lighting changes, morphing) exactly on the beat without hard cuts.
   * **Batch Video Generation**: `Wan_Batch_Worker` queues the approved keyframes, dynamic relay scripts, and audio chunks, sending them to the ComfyUI API (WanVideo + LivePortrait nodes).
   * **Progress Tracking**: The `Status_Bar` interface monitors the rendering progress of the batches (e.g., 92 clips at 768px).

3. **Offline Editing (Automated Assembly)**
   * **Timeline Conform**: `FFmpeg_Stitcher` automatically concatenates the generated clips (hard cuts) over the original audio track into a low-res video preview directly in the Canvas.

4. **Finishing (Online Engine)**
   * **High Frame Rate (64 FPS)**: `RIFE_Interpolation_API` sends the low-res master back to ComfyUI for temporal interpolation.
   * **8K Tiled Upscale**: `Ultimate_Upscale_API` runs the upscale process on 64x64 tiles. The `Memory_Check` module ensures the 10GB/64GB limits are never exceeded during the 8K assembly.

5. **Delivery (Final Master)**
   * **Mastering & Export**: `Final_Encoder_API` uses FFmpeg with High Bitrate settings (200Mbps+) and AV1/H.265 codecs, providing a direct download link in the Open-WebUI interface.

---

## 📂 Exact Directory Map

*Note: All paths are relative to the root folder of the Coozila! Studio repository.*

### 📁 Project Root
* `./install.sh` - **Master Orchestrator**. Handles repository syncing, VENV creation, dependency injection, and multi-process server launching.
* `./.env` / `./.env.example` - Global environment variables (Ports, Git Tags, CUDA versions).
* `./requirements.txt` - Global Python dependencies for the Studio API injection.
* `./README.md` / `./docs/` / `./LICENSE` - Documentation.
* `./sessions/` - *(Directory)* **[Planned]** Active project state JSONs.
* `./exports/` - *(Directory)* **[Planned]** Final `.mp4` / `.mkv` master files.
* `./temp_assets/` - *(Directory)* **[Planned]** Shared folder for raw chunks, slices, and ComfyUI `output/` links.

### 📁 Provisioning Scripts (`./scripts/`)
Contains the modular bash scripts executed by `install.sh` to build the isolated environments:
* `./scripts/setup-webui.sh` - Clones and provisions the Open-WebUI frontend.
* `./scripts/setup-comfy.sh` - Builds the ComfyUI backend, installs PyTorch (CUDA 12.4), and core custom nodes (ComfyUI-Manager).
* `./scripts/setup-wan2.sh` - Injects the Wan 2.2 HW acceleration layer (Flash-Attention, SAM2), installs the WanVideoWrapper, and auto-downloads the FP8 scaled models.
* `./scripts/setup-studio.sh` - Installs custom APIs and specialized Python dependencies (e.g., Librosa, PyDub, FFmpeg wrappers) required exclusively by the Studio Orchestrator core.

### 📁 Upstream Environments (`./apps/`)
Target directories for the cloned repositories. Each runs in its own isolated Virtual Environment (`venv`):
* **`./apps/open-webui/`** - Active frontend host (Port 3000). Contains injected Coozila frontend code.
* **`./apps/ComfyUI/`** - Active backend engine (Port 8188). 
  * `./apps/ComfyUI/custom_nodes/ComfyUI-Manager/` - Core node manager.
  * `./apps/ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper/` - Wan 2.2 main wrapper.
  * `./apps/ComfyUI/custom_nodes/Prompt-Relay/` - **[NEW]** Frame-accurate morphing and temporal control node.
  * `./apps/ComfyUI/models/` - Houses the ingested AI weights (diffusion_models, vae, text_encoders, audio_encoders).

### 🎨 Frontend Canvas Source (`./canvas/`)
*Code written here is automatically copied into `./apps/open-webui/src/` during the `install.sh` process.*
* `./canvas/StudioCanvas.svelte` - Main visual timeline interface.
* `./canvas/studio_tab.js` - UI Injector.
* `./canvas/orchestrator.js` - Client-side logical flow.
* `./canvas/canvas.js` - Clip block drawing logic.
* **`./canvas/api_bridges/`** - *(Directory)* **[In Development]** Frontend connectors to Backend Tools.
  * `./canvas/api_bridges/file_uploader_bridge.js` - **[Planned]** Handles asset ingestion and shared volume routing.
  * `./canvas/api_bridges/status_bar.js` - **[Planned]** WebSocket listener for ComfyUI progress tracking.
* **`./canvas/templates/`** - Data models:
  * `./canvas/templates/master_schema.json`
  * `./canvas/templates/default_schema.json`
  * `./canvas/templates/styles.json`
  * `./canvas/templates/shot_presets.json`

### 🧠 Backend Core Source (`./core/studio/`)
*Code written here is automatically copied into `./apps/open-webui/backend/` during the `install.sh` process.* The Python API layer injected into Open-WebUI. Translates Canvas commands into FFmpeg executions or headless ComfyUI JSON API requests.

* **Main Controllers:**
  * `./core/studio/video_studio_orchestrator.py` - Central state machine mapping the 5 phases.
  * `./core/studio/api.py` - Open-WebUI backend route injector.
  * `./core/studio/tool_video_studio.py` - Main Tool exposed to the LLM (Gemini/GPT).
  * `./core/studio/llm_schema_parser.py` - **[Planned]** Parses LLM output into strict Canvas table structures.

* **Phase 1: Pre-Production Tools**
  * `./core/studio/asset_manager.py` - **[Planned]** Handles shared folder file saving.
  * `./core/studio/audio_slicer_api.py` - **[Planned]** Librosa/PyDub logic for splitting audio and mapping energy peaks.
  * `./core/studio/storyboard_generator.py` - **[Planned]** Builds JSON payloads for keyframe generation.
  * `./core/studio/scenography_builder.py` - **[Planned]** Utilizes Prompt-Relay for image generation to lock background consistency across scenes based on Gemini's script.

* **Phase 2 & 4: ComfyUI Headless Execution Tools**
  * `./core/studio/comfyui_api_gateway.py` - **[Planned]** The core WebSocket/HTTP client. Sends JSON, waits for execution, returns paths to temporary files.
  * `./core/studio/dynamic_relay_composer.py` - **[Planned]** Translates audio beats and image assets into dynamic Prompt-Relay JSON arrays (frame-accurate morphing instructions).
  * `./core/studio/intra_shot_relay.py` - **[Planned]** Injects the dynamic relay JSON arrays into Wan 2.2 payloads for seamless, continuous action takes.
  * `./core/studio/latent_bridge_optimizer.py` - **[Planned]** Modulates transition speeds between relayed prompts based on music intensity.
  * `./core/studio/payload_factory.py` - Assembles raw ComfyUI JSON workflows dynamically.
  * `./core/studio/wan_batch_worker.py` - **[Planned]** Manages queues for bulk video generation.
  * `./core/studio/rife_interpolation_api.py` - **[Planned]** Submits the low-res master for 64 FPS interpolation.
  * `./core/studio/ultimate_upscale_api.py` - **[Planned]** Submits the tiled 8K upscale job.
  * `./core/studio/memory_check.py` - **[Planned]** Hardware monitor preventing VRAM/RAM overflow during massive upscale/stitch tasks.

* **Phase 3 & 5: Offline Editing & Delivery Tools (FFmpeg)**
  * `./core/studio/ffmpeg_stitcher.py` - **[Planned]** Timeline Conform logic. Concatenates AI clips over the original audio.
  * `./core/studio/final_encoder_api.py` - **[Planned]** AV1/H.265 Mastering script (200Mbps+ output).

* **Configs & Models:**
  * `./core/studio/config.py` - Environment variables (ComfyUI URL, Local paths).
  * `./core/studio/style_engine.py`
  * `./core/studio/shot_presets.py` - Prompt engineering logic.
  * **`./core/studio/comfy_workflows/`** - *(Directory)* **[Planned]** Contains the raw JSON API format exported from ComfyUI (e.g., `wan2.2_relay_api.json`, `rife_api.json`). `payload_factory.py` reads these and injects dynamic variables.