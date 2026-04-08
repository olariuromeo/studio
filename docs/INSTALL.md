# 🛠️ Coozila! Studio v4.1 - Developer Environment

## 1. System Prerequisites (Mandatory)
Optimized for high-fidelity AI production on consumer-grade hardware.

* **GPU:** NVIDIA RTX 3080 (min. 10GB VRAM).
* **System RAM:** 64GB (Required for Wan 2.2 14B VRAM overflow/offloading).
* **Drivers:** NVIDIA Proprietary Drivers (v535+).
* **CUDA:** Toolkit 12.4+ (Pre-installed & in $PATH).
* **Version Manager:** [asdf-vm](https://asdf-vm.com/) (Required for Node 22.13.0 & Python 3.11.14).

---

## 2. Quick Start Deployment

### Step 1: Clone the Repository
Open your terminal and prepare the Studio root directory:
```bash
git clone [https://github.com/kabballa/studio.git](https://github.com/kabballa/studio.git) coozila-studio
cd coozila-studio
````

### Step 2: Environment Configuration (CRITICAL)

Before running the orchestrator, you must initialize and configure your local environment settings.

1.  **Create your dev environment file:**
    ```bash
    cp .env.example .env.dev
    ```
2.  **Configure `.env.dev`:**
    Open the file and ensure the following settings are applied for 10GB VRAM hardware:
      * `VRAM_MODE=lowvram` (Enables System RAM offloading).
      * `HF_TOKEN=your_huggingface_token_here` (Required for model syncing).
      * Ensure `COMFY_ARGS` includes `--fp8_e4m3fn-text-enc` for Wan 2.2 stability.

### Step 3: Launch Orchestrator (Terminal 1)

Run the master script. This performs a **Scorched Earth** cleanup, installs dependencies, injects Studio modules, and starts the Vite Dev Server.

```bash
chmod +x dev.sh
./dev.sh
```

  * **Status:** Keep this terminal open to monitor the HMR (Hot Module Replacement) engine.

### Step 4: Launch Backend Engine (Terminal 2)

Open a **NEW TERMINAL** window to start the FastAPI/Uvicorn backend.

```bash
cd apps/open-webui/backend
source ../venv/bin/activate
pip install -r requirements.txt -U
sh dev.sh
```

-----

## 3\. Service Access & GUIs

Once the deployment is complete, you can access the different layers of the studio via your browser:

### 🌐 Main Workspace (Open WebUI + Studio Canvas)

**URL:** [http://localhost:5173](http://localhost:5173)

  * **Description:** This is your primary entry point. Access the Cinematic Timeline, Coozila\! Studio Canvas, and the bilingual Iliad workspace here.

### 🎬 Wan Video Engine (ComfyUI Wrapper GUI)

**URL:** [http://localhost:8188](http://localhost:8188)

  * **Description:** This is the "Engine Room". Access the ComfyUI nodes directly to tweak Wan 2.2 parameters, manage the 14B model sharding, and monitor the Silver Bow's render progress.

### ⚙️ Backend API

**URL:** [http://localhost:8080/docs](http://localhost:8080/docs)

  * **Description:** Swagger/OpenAPI documentation for the backend orchestration logic.

-----

## 4\. Hardware-Specific Notes (Wan 2.2)

  * **VRAM Management:** On 10GB cards, the 14B model will utilize \~15GB of System RAM as a buffer. The first video generation will take longer as the model shards are loaded into memory.
  * **Model Integrity:** The `dev.sh` script includes a Zero-Byte Guard. If a model download is interrupted, it will resume automatically on the next run.

> [\!CAUTION]
> Visiting port 8080 directly in your browser will result in a "Frontend build directory not found" error. This is **EXPECTED** in Dev Mode. Always use **port 5173** for the Studio interface.

-----

**Copyright (C) 2009 - 2026 Coozila\! Team. All rights reserved. Licensed under MIT.** *Special thanks to the collaborative effort between the Coozila\! Team and AI assistants for optimizing 14B model execution on constrained hardware.*