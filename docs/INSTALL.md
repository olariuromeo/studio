# 1. System Prerequisites (Mandatory)
Ensure your hardware and drivers are correctly configured before running the orchestrator:

* **GPU:** NVIDIA RTX 3080 (or higher, min. 10GB VRAM).
* **Drivers:** NVIDIA Proprietary Drivers (v535+).
* **CUDA:** Toolkit 12.5 (Must be pre-installed and available in your `$PATH`).
* **Version Manager:** [asdf-vm](https://asdf-vm.com/) must be installed on your system.

## 2. One-Click Local Deployment (Non-Docker)
We utilize a **Native Dual-VENV** architecture for development. This ensures maximum performance and direct hardware access without container overhead.

The `install.sh` script automates:
* **Environment Sync:** Pulls Python (3.11.9/3.11.14) and NodeJS (20) versions from `.env`.
* **Dual Isolation:** Creates separate Virtual Environments for Frontend and Backend.
* **Stable Tag Locking:** Clones **ComfyUI v0.18.3** and **Open-WebUI v0.8.12**.
* **Studio Injection:** Automatically overwrites upstream code with Coozila! Custom Core.

### Quick Start:
```bash
git clone [https://github.com/kabballa/studio.git](https://github.com/kabballa/studio.git) coozila-studio
cd coozila-studio
chmod +x install.sh
./install.sh
```

## 3. Engine & Model Deployment (Browser-Based)
To keep the installation lightweight, heavy generation engines are activated via the UI:

### A. Wan 2.2 (Video Engine) activation
1.  Access **ComfyUI (Port 8188)**.
2.  Open **Manager** > **Custom Nodes Manager**.
3.  Search for `WanVideo` (by `kijai`) and click **Install**.
4.  Restart the Studio services.

### B. Model Placement
Once the nodes are installed, place the large-scale models in these specific paths:
* **FLUX.1:** `apps/ComfyUI/models/diffusion_models/flux1-krea-dev_fp8_scaled.safetensors`
* **Wan 2.2:** `apps/ComfyUI/models/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors`
* **VAEs:** Place specific VAEs for Wan/Flux in `apps/ComfyUI/models/vae/`.

## 4. Launch Sequence
The `./install.sh` script automatically boots both services:
1.  **Frontend (Open-WebUI):** http://localhost:3000 (Running in background).
2.  **Backend (ComfyUI Engine):** http://localhost:8188 (Running in foreground).

> [!TIP]
> Use `tail -f open-webui.log` in the root directory to monitor frontend logs.

## 5. UI Activation: Coozila! Studio Bridge
To connect the Interactive Canvas to the worker:

1.  Open **Open-WebUI (3000)** > **Workspace** > **Functions**.
2.  Click **Create New Function** and select **Import**.
3.  Load the logic from:
    `apps/open-webui/backend/open_webui/studio/bridge.py`
4.  Save. The cinematic timeline is now live.

---
**Copyright (C) 2009 - 2026 Coozila! Team. All rights reserved.**
