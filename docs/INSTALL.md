# 🛠️ Coozila! Studio v4.1 - Developer Environment

## 1. System Prerequisites (Mandatory)
Ensure your hardware and drivers are correctly configured before running the orchestrator:

* **GPU:** NVIDIA RTX 3080 (or higher, min. 10GB VRAM).
* **Drivers:** NVIDIA Proprietary Drivers (v535+).
* **CUDA:** Toolkit 12.4+ (Pre-installed & in $PATH).
* **Version Manager:** [asdf-vm](https://asdf-vm.com/) (Required for Node 22.13.0 & Python 3.11.14).

## 2. Quick Start Deployment (Dev Mode)

### Step 1: Clone & Permissions
Open your terminal and prepare the environment. We use a **Native Dual-VENV** architecture for maximum performance.

```bash
git clone https://github.com/kabballa/studio.git coozila-studio
cd coozila-studio
chmod +x dev.sh
```

### Step 2: Launch Frontend (Terminal 1)
Execute the master orchestrator. This script performs a **Scorched Earth** cleanup, syncs repositories, aligns ASDF runtimes, and starts the Vite Dev Server in the background.

```bash
./dev.sh
```
* **UI URL:** http://localhost:5173
* **Status:** **KEEP THIS TERMINAL OPEN.** It hosts the Hot-Reload engine.
* **Logs:** Monitor via `tail -f logs/frontend_dev.log`.

### Step 3: Launch Backend Engine (Terminal 2)
Open a **NEW TERMINAL** window to start the FastAPI/Uvicorn engine. This terminal will provide full visibility for backend debugging and Studio/OTIO logic.

```bash
cd apps/open-webui/backend
source ../venv/bin/activate
pip install -r requirements.txt -U
sh dev.sh
```
* **Backend API:** http://localhost:8080
* **API Docs:** http://localhost:8080/docs

---

## 3. Accessing the Studio
The application operates in a decoupled state during development to allow instant code updates:

* **Primary Workspace [Port 5173]:** This is your main entry point. Access the Cinematic Timeline and Studio Canvas here.
* **Service Engine [Port 8080]:** The frontend communicates with this port for all AI and data logic.

> [!CAUTION]
> If you visit port 8080 directly in your browser, you will see a "Frontend build directory not found" error. This is **EXPECTED** in Dev Mode because the UI is being served by Vite on port 5173. Always use **http://localhost:5173** for the full interface.

## 4. Development Workflow & Injection
The `dev.sh` orchestrator automatically handles:
* **Canvas Injection:** Maps Coozila! Studio components into `apps/open-webui/src/lib/`.
* **Core Injection:** Injects the Studio Python engine into `apps/open-webui/backend/open_webui/`.
* **ASDF Locking:** Generates `.tool-versions` dynamically from `.env.dev`.

---
**Copyright (C) 2009 - 2026 Coozila! Team. All rights reserved. Licensed under MIT.**
