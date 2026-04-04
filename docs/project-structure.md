# 🏗️ Coozila! Video Studio Architecture

The ecosystem relies on an **Overlay & Orchestration** model built on a Bare-Metal Multi-VENV architecture:
* **Open-WebUI**: The User Interface (Frontend Host).
* **ComfyUI**: The Execution & Rendering Engine (Headless GPU Backend).
* **OpenTimelineIO (OTIO)**: The Data Backbone. Industry-standard schema for editorial timing and metadata.
* **Coozila! Studio**: The Orchestrator. Manages the OTIO Timeline, Canvas UI, and Tool/API provider.

## ⚙️ The 5 Phases of the Studio Orchestrator

1. **Pre-Production (Studio Canvas & OTIO Initialization)**
   * **Asset Ingestion**: `File_Uploader` stores reference assets in shared local folders.
   * **Audio-Visual Pulse**: `WhisperX` & `Librosa` analyze the track.
   * **OTIO Generation**: `Audio_Timeline_Builder` creates the initial `.otio` schema with synchronized clips based on beats and lyrics.
   * **The Casting Dialogue**: LLM maps detected voices to character descriptions within the OTIO metadata.

2. **AI Production (Prompt-Relay Loops)**
   * **Dynamic Routing**: `Dynamic_Relay_Composer` writes mathematical instructions into OTIO clip metadata for intra-shot morphing.
   * **Batch Execution**: `Wan_Batch_Worker` translates OTIO clips into headless ComfyUI JSON payloads.
   * **Progress Tracking**: Real-time rendering status updates in the Studio Status Bar.

3. **Offline Editing (OTIO Conform)**
   * **Timeline Assembly**: `FFmpeg_Stitcher` reads the OTIO schema to concatenate generated clips over the master audio for a low-res preview.

4. **Finishing (High-Fidelity Engine)**
   * **Temporal & Spatial Upscale**: `RIFE` (64 FPS) and `Ultimate Upscale` (8K) processes are triggered via API, utilizing `Memory_Check` to guard system RAM/VRAM.

5. **Delivery (Final Master)**
   * **Mastering**: `Final_Encoder_API` encodes the OTIO master into AV1/H.265 at 200Mbps+.

---

## 📂 Exact Directory Map

### 📁 Project Root
* `./install.sh` - **Master Orchestrator**. (Now triggers OTIO & Studio setup).
* `./.env` - **Global Config**. (Contains `OTIO_TAG`, `HF_TOKEN`, `CUDA_VERSION`).
* `./requirements.txt` - Global dependencies.

### 📁 Provisioning Scripts (`./scripts/`)
* `./scripts/setup-webui.sh` - Frontend provisioning.
* `./scripts/setup-comfy.sh` - Backend provisioning.
* `./scripts/setup-wan2.sh` - Wan 2.2 Environment & Wrapper setup (No heavy downloads).
* `./scripts/setup-otio.sh` - **[DYNAMIC]** Installs OTIO $OTIO_TAG and clones `otioview`.
* `./scripts/setup-studio.sh` - Injects Core Studio Python dependencies.
* `./scripts/download-models.sh` - **[ASYNC]** Smart downloader with HF Auth & Existence checks.

### 📁 Upstream Environments (`./apps/`)
* **`./apps/open-webui/`** - Frontend Host.
* **`./apps/ComfyUI/`** - Backend Engine.
* **`./apps/otioview/`** - **[NEW]** Native visual debugger for OTIO files.

### 🎨 Frontend Canvas Source (`./canvas/`)
* `./canvas/StudioCanvas.svelte` - **Main Container** (Multi-Tab Logic).
* **`./canvas/tabs/`** - **[NEW]** Modular UI components:
  * `./canvas/tabs/TimelineTab.svelte` - OTIO visual track editor.
  * `./canvas/tabs/CastingTab.svelte` - Character/Voice management.
  * `./canvas/tabs/DirectorTab.svelte` - Prompt-Relay & Preview controls.
* `./canvas/orchestrator.js` - OTIO-to-UI state manager.

### 🧠 Backend Core Source (`./core/studio/`)
* `./core/studio/audio_timeline_builder.py` - **[NEW]** Generates OTIO files from Audio/Lyrics analysis.
* `./core/studio/comfyui_api_gateway.py` - OTIO-to-ComfyUI JSON translator.
* `./core/studio/dynamic_relay_composer.py` - Manages Prompt-Relay math within OTIO metadata.
* `./core/studio/asset_manager.py` - Handles shared volume file routing.

### 📁 Workflows & Templates
* **`./core/studio/comfy_workflows/`** - API JSON templates for Wan 2.2, RIFE, and Upscale.
* **`./canvas/templates/`** - Default OTIO schemas and style presets.