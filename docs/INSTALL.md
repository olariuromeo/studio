# 🛠️ Coozila! Studio v4.1 - Developer Environment

## 1. System Prerequisites (Mandatory)
Ensure your hardware and drivers are correctly configured before running the orchestrator:

* **GPU:** NVIDIA RTX 3080 (or higher, min. 10GB VRAM).
* **Drivers:** NVIDIA Proprietary Drivers (v535+).
* **CUDA:** Toolkit 12.4+ (Must be pre-installed).
* **Version Manager:** [asdf-vm](https://asdf-vm.com/) (Required for Node 22.13.0 & Python 3.11.14).

## 2. Quick Start Deployment (Dev Mode)

### Step 1: Clone & Prepare
Open your terminal and run the following commands to pull the environment:
```bash
git clone [https://github.com/kabballa/studio.git](https://github.com/kabballa/studio.git) coozila-studio
cd coozila-studio
chmod +x dev.sh
````

### Step 2: Launch Frontend (Terminal 1)

Execute the orchestrator to sterilize the environment and start the UI:

```bash
./dev.sh
```

  * **UI URL:** [http://localhost:5173](https://www.google.com/search?q=http://localhost:5173)
  * **Status:** Keep this terminal open to maintain the Vite Dev Server.

### Step 3: Launch Backend Engine (Terminal 2)

Open a **NEW TERMINAL** window, navigate to the backend folder, and fire up the engine:

```bash
cd apps/open-webui/backend
source ../venv/bin/activate
pip install -r requirements.txt -U
sh dev.sh
```

  * **Backend API:** [http://localhost:8080](https://www.google.com/search?q=http://localhost:8080)

-----

## 3\. Accessing the Studio

Once both terminals are running, the application is split to allow real-time code changes:

  * **Primary UI [Port 5173]:** This is your workspace. Login and use the Cinematic Timeline here.
  * **Backend Engine [Port 8080]:** The UI communicates with this port automatically.

> [\!CAUTION]
> If you visit port 8080 directly in your browser, you will see a "Frontend build directory not found" error. This is **NORMAL** in Dev Mode. Always use port **5173** for the full interface experience.

-----

**Copyright (C) 2009 - 2026 Coozila\! Team. All rights reserved.**