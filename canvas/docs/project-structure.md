# 🏗️ Core Project Structure

The **Coozila! Video Studio** architecture is designed for modularity and scalability. It separates the "creative intent" (JSON Templates) from the "technical execution" (Python Backend) and the "user interaction" (JavaScript Frontend).

## 📂 Directory Map

### 🧠 Backend (Python) - `/coozila/video/studio/`
* **`orchestrator.py`**: The Central Command. It manages project sessions, clones templates, and coordinates between audio analysis and rendering.
* **`audio_sync.py`**: The Rhythmic Engine. Uses Librosa to extract BPM and beat timestamps to calculate mathematically perfect "cut points".
* **`payload_factory.py`**: The Dynamic Graph Builder. Programmatically assembles ComfyUI node dictionaries (JSON) based on required video length.
* **`style_engine.py`**: The Prompt Architect. Merges visual styles with cinematic camera logic into a final instruction for Wan 2.2.
* **`api.py`**: The Communication Bridge. Registers custom routes in the ComfyUI server to allow the Frontend to talk to the Backend.

### 🎨 Frontend (Web/JS) - `/coozila/video/studio/web/`
* **`studio_tab.js`**: The UI Injector. Adds the "✨ Studio" button to the ComfyUI chat and manages the Modal Overlay.
* **`canvas_renderer.js`**: The Graphics Engine. Responsible for drawing the interactive timeline, audio waveforms, and clip blocks.

### 💾 Data & Templates - `/coozila/video/studio/templates/`
* **`master_schema.json`**: The Blueprint. A professional `Timeline.1` structure compatible with NLE software standards.
* **`styles.json`**: The Aesthetic Library. Pre-configured positive/negative prompts for specific visual "vibes".
* **`shot_presets.json`**: The Director's Manual. Presets for camera movements (Orbit, Push, Crane) and their motion intensities.

### ⚙️ Storage & Assets
* **`/sessions/`**: Stores active project states as JSON files.
* **`/exports/`**: The final destination for rendered `.mp4` files.
* **`/VideoClips/`**: Temporary storage for raw AI-generated chunks before they are merged.