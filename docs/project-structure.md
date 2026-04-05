# 🗺️ Coozila! Studio: Full Directory Map (v4.2)

### 📁 **1. Project Root & Orchestration**
Nivelul superior care gestionează mediile virtuale și sincronizarea submodulelor.
* `./dev.sh` — **Master Bootstrapper**. Rulează setup-ul complet.
* `./.env.dev` — **Dev Config**. Definește toate variabilele de mediu și căile.
* `./.gitmodules` — **Registry**. Stochează link-urile către repo-urile externe.
* `./requirements.txt` — Dependențe Python globale pentru Studio.
* `./docker-compose.yml` — Configurație pentru rulare containerizată.

---

### 📁 **2. Deployment Logic (`./dev/`)**
Scripturi modulare de instalare și configurare.
* `./dev/setup-webui.sh` — Instalare frontend + înregistrare submodul.
* `./dev/setup-comfy.sh` — Instalare backend GPU + ComfyUI-Manager.
* `./dev/setup-otio.sh` — Provisioning pentru engine-ul de Timeline și Viewer.
* `./dev/setup-wan2.sh` — Configurare mediu specializat pentru Wan 2.2.
* `./dev/setup-studio.sh` — Instalare pachete Python pentru core-ul Studio.
* `./dev/download-models.sh` — Downloader asincron pentru modele (HuggingFace).

---

### 📁 **3. Backend Core Engine (`./core/coozila/`)**
Creierul aplicației, unde se procesează datele și se generează payload-urile.
* **`./core/coozila/studio/`** — **Studio Orchestrator**
    * `config.py` — Registru centralizat de servicii și rezoluții.
    * `payload_factory.py` — Fabrica de JSON-uri pentru ComfyUI (FLUX/Wan).
    * `schema_engine.py` — Validarea și managementul sesiunilor OTIO.
    * `api.py` — Endpoint-urile FastAPI pentru comunicarea cu Frontend-ul.
    * **`./schemas/`** — **Logic Blueprints** (Templates JSON).
* **`./core/coozila/audio/`** — Procesare audio (WhisperX, Librosa).
* **`./core/coozila/video/`** — Procesare video (FFmpeg Stitcher, Encoders).
* **`./core/coozila/interpolation/`** — Logica pentru RIFE (60 FPS).
* **`./core/coozila/upscaler/`** — Logica pentru Ultimate SD Upscale (4K/8K).

---

### 📁 **4. Frontend Canvas (`./core/static/canvas/`)**
Componentele vizuale injectate în Open-WebUI.
* `./core/static/canvas/StudioCanvas.svelte` — Containerul principal UI.
* `./core/static/canvas/orchestrator.js` — Bridge-ul de stare între OTIO și Svelte.
* **`./core/static/canvas/studio/`** — Componente Tab-based:
    * `TimelineTab.svelte` — Editorul vizual de track-uri.
    * `CastingTab.svelte` — Gestiune caractere și voci.
    * `DirectorTab.svelte` — Controlul generării și preview-ului.

---

### 📁 **5. Submodule Apps (`./apps/`)**
Aplicațiile externe rulate ca microservicii sincronizate.
* **`./apps/open-webui/`** — Host-ul pentru interfața utilizator.
* **`./apps/ComfyUI/`** — Motorul de rendering GPU (Headless).
* **`./apps/otio/`** — Librăria oficială OpenTimelineIO.
* **`./apps/otioview/`** — Debugger-ul vizual pentru fișiere `.otio`.
* **`./apps/ComfyUI-WanVideoWrapper/`** — Nodurile custom pentru Wan 2.2.

---

### 📁 **6. Persistent Storage (`./data/`)**
Volumele partajate între toate submodulele.
* `./data/coozila/assets/` — Fișiere sursă (audio, imagini referință).
* `./data/coozila/sessions/` — Fișierele `.otio` active ale proiectelor.
* `./data/coozila/outputs/` — Cadrele generate și videoclipurile intermediare.
* `./data/coozila/exports/` — Masterele finale (4K/8K).

---