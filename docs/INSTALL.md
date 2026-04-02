# 1. System Prerequisites (Mandatory)
Before running the automated installer, ensure your hardware layer is correctly configured. This installer is optimized for a clean **Ubuntu Desktop 22.04 LTS** environment.

* **GPU:** NVIDIA RTX 3080 (or higher, min. 10GB VRAM).
* **Drivers:** NVIDIA Proprietary Drivers (v535+).
* **CUDA:** Toolkit 12.5 must be pre-installed and available in your `$PATH`.

## 2. One-Click Deployment
We have simplified the entire ecosystem setup into a single command. The `install.sh` script handles:
* **System Deps:** Installs `ffmpeg`, `git`, `build-essential`, `jq`, etc.
* **Runtime Manager:** Installs and configures **asdf** and **Python 3.11.9**.
* **Auto-Cloning:** Downloads `open-webui`, `ComfyUI`, and `ComfyUI-Manager` into the `apps/` directory.
* **Environment:** Creates a clean Virtual Environment and installs the AI Stack (Torch cu125, Studio Core).

### Quick Start:
```bash
git clone [https://github.com/kabballa/studio.git](https://github.com/kabballa/studio.git) coozila-studio
cd coozila-studio
chmod +x install.sh
./install.sh
```

## 3. Model Deployment
Once the installation is complete, place the high-capacity cinematic models in their respective paths:

* **FLUX.1 (Storyboard Engine):** `apps/ComfyUI/models/diffusion_models/flux1-krea-dev_fp8_scaled.safetensors`
* **Wan 2.2 (Video Engine):** `apps/ComfyUI/models/unet/wan2.2_s2v_14B_fp8_scaled.safetensors`

## 4. Launch Sequence

### A. Backend (Studio Engine)
The engine is automatically started by the `install.sh` script. For subsequent boots, use:
```bash
./install.sh
```
*Optimized for RTX 3080: Includes `--lowvram`, `--enable-dynamic-vram`, and `--async-offload`.*

### B. Frontend (Open-WebUI)
Launch the Studio-patched interface using Docker:
```bash
# From the coozila-studio root
docker compose up -d --build
```

---

## 5. UI Activation: Coozila! Studio Bridge
To activate the Interactive Canvas, you must register the bridge function:

1.  Open **Open-WebUI (Port 3000)**.
2.  Navigate to **Workspace > Functions**.
3.  Click **Create New Function** (Action/Tool).
4.  **Import Logic** from the local file injected into the container:
    * **Internal Path:** `backend/open_webui/studio/bridge.py`
5.  Save. The timeline is now live and connected to your worker.

---

**Copyright (C) 2009 - 2026 Coozila! Team. All rights reserved.**
```