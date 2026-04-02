# 1. System Prerequisites (Mandatory)
Before running the automated installer, ensure your hardware layer is correctly configured.

* **GPU:** NVIDIA RTX 3080 (or higher, min. 10GB VRAM).
* **Drivers:** NVIDIA Proprietary Drivers (v535+).
* **CUDA:** Toolkit 12.5 must be pre-installed and available in your `$PATH`.

## 2. One-Click Local Deployment (Non-Docker)
We have shifted to a **Native Dual-VENV** architecture for local development. This ensures maximum performance and direct access to Python runtimes without container overhead.

The `install.sh` script automates:
* **System Deps:** `ffmpeg`, `git`, `build-essential`, `jq`, etc.
* **Runtime Manager:** Installs **asdf** and **Python 3.11.9** (global studio standard).
* **Dual Isolation:** Creates separate Virtual Environments for Frontend and Backend.
* **Stable Tag Locking:** Clones **ComfyUI v0.18.3** and **Open-WebUI v0.8.12**.
* **AI Stack:** Installs Torch optimized for **CUDA 12.5** (`cu125`).

### Quick Start:
```bash
git clone [https://github.com/kabballa/studio.git](https://github.com/kabballa/studio.git) coozila-studio
cd coozila-studio
chmod +x install.sh
./install.sh
```

## 3. Model Deployment
Place the cinematic models in their respective paths within the `apps/` directory:

* **FLUX.1 (Storyboard Engine):** `apps/ComfyUI/models/diffusion_models/flux1-krea-dev_fp8_scaled.safetensors`
* **Wan 2.2 (Video Engine):** `apps/ComfyUI/models/unet/wan2.2_s2v_14B_fp8_scaled.safetensors`

## 4. Launch Sequence (Local Development)
The script `./install.sh` will automatically launch both services:
1.  **Frontend (Open-WebUI):** Starts in the background on port `3000`.
2.  **Backend (ComfyUI):** Starts in the foreground on port `8188` with Manager enabled.

> [!IMPORTANT]
> **Docker Integration:** Containerization via `docker-compose` is currently disabled and scheduled for implementation **ONLY** after successful local development validation.

---

## 5. UI Activation: Coozila! Studio Bridge
To activate the Interactive Canvas:

1.  Open **Open-WebUI** at `http://localhost:3000`.
2.  Navigate to **Workspace > Functions**.
3.  Click **Create New Function** (Action/Tool).
4.  **Import Logic** from your local studio directory:
    * **File Path:** `apps/open-webui/backend/open_webui/static/studio/bridge.py`
5.  Save. The timeline is now live and connected to your local worker.

---

**Copyright (C) 2009 - 2026 Coozila! Team. All rights reserved.**