# 🛠️ Coozila! Studio v4.1 - Developer Environment

## 1. System Prerequisites (Mandatory)
Ensure your hardware and drivers are correctly configured before running the orchestrator:

* **GPU:** NVIDIA RTX 3080 (or higher, min. 10GB VRAM).
* **Drivers:** NVIDIA Proprietary Drivers (v535+).
* **CUDA:** Toolkit 12.4+ (Must be pre-installed).
* **Version Manager:** [asdf-vm](https://asdf-vm.com/) (Required for Node 22.13.0 & Python 3.11.14).

## 2. Master Orchestrator (`dev.sh`)
Currently, we use a specialized development orchestrator that handles environment sterilization, repo syncing, and dual-engine launching.

> [!IMPORTANT]
> The full automated `install.sh` is currently **PLANNED**. Use `dev.sh` for the current development cycle.

### Quick Start (Dev Mode):
1. **Frontend Launch:** Run `./dev.sh`. This prepares the environment and starts the UI on **[http://localhost:5173](http://localhost:5173)**.
2. **Backend Handoff:** Open a **NEW TERMINAL** and follow the commands printed by the orchestrator to start the Engine on port **8080**.

## 3. Accessing the Studio
Once both terminals are running, the application is split to allow real-time code changes:

* **Primary UI:** [http://localhost:5173](http://localhost:5173) 
    *(This is where you log in and use the Cinematic Timeline)*.
* **Backend Engine:** [http://localhost:8080](http://localhost:8080) 
    *(The UI automatically communicates with this port in the background)*.

> [!CAUTION]
> If you visit port 8080 directly in your browser, you will see a "Frontend build directory not found" error. This is **NORMAL** in Dev Mode because Vite (5173) is serving the interface. Always use port **5173** for the full experience.

---
**Copyright (C) 2009 - 2026 Coozila! Team. All rights reserved.**