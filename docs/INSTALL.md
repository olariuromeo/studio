# 🛠️ Installation Guide: Coozila! Studio Canvas (Full Stack)

```text
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#   Studio Repo: https://github.com/kabballa/studio                                 #
#                                                                                   #
# ----------------------------------------------------------------------------------#
```

## 1. System Prerequisites
```bash
sudo apt update && sudo apt install -y ffmpeg git build-essential libssl-dev
```

## 2. Step Zero: Clone the Ecosystem
We need both the **Frontend (OpenWebUI)** and the **Worker (ComfyUI)**.

```bash
# Clone the Frontend
git clone https://github.com/open-webui/open-webui.git
cd open-webui

# Clone the Worker (Outside or alongside OpenWebUI)
cd ..
git clone https://github.com/comfyanonymous/ComfyUI.git
```

## 3. Step One: Deploy Coozila! Studio (Frontend & Backend)
We use your repository as a submodule in OpenWebUI for the interface, and we link the logic into ComfyUI for the processing.

### A. Frontend (OpenWebUI Static)
```bash
cd open-webui
git submodule add https://github.com/kabballa/studio.git backend/open_webui/static/studio
git submodule update --init --recursive
```

### B. Backend (ComfyUI Custom Node)
We install the same core logic into ComfyUI so it can understand the Studio's API commands.
```bash
cd ../ComfyUI/custom_nodes
git clone https://github.com/kabballa/studio.git studio
```

## 4. Environment & Version Management (asdf)
We lock both environments to **Python 3.11.9**.

```bash
# Set versions
asdf install python 3.11.9
asdf local python 3.11.9

# Setup Virtual Environment
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

# Install dependencies for both shells
pip install -r ../../open-webui/backend/requirements.txt
pip install -r ../requirements.txt
pip install librosa numpy aiohttp requests ffmpeg-python Pillow python-dotenv
```

## 5. Launch Sequence
You need both "engines" running for the Studio to work.

1.  **Start the Worker (ComfyUI):**
    ```bash
    cd ComfyUI
    python main.py --port 8188
    ```
2.  **Start the Frontend (OpenWebUI):**
    ```bash
    cd open-webui
    open-webui serve
    ```

---

## 6. UI Activation: Coozila! Studio Canvas
Go to **OpenWebUI > Workspace > Functions > Create New Function (Action)**:

```python
"""
title: Coozila! Studio Canvas
author: Coozila Team
version: 3.2
"""
class Action:
    async def action(self, body: dict, __event_emitter__: callable = None):
        launcher_html = """
        <script>
            if (!window.coozilaStudioStarted) {
                const s = document.createElement('script');
                s.src = '/static/studio/canvas.js';
                s.type = 'module';
                document.head.appendChild(s);
                window.coozilaStudioStarted = true;
            }
        </script>
        <button onclick="window.openStudioCanvas()" style="background:#7e22ce; color:white; border:none; padding:8px 18px; border-radius:20px; cursor:pointer; font-weight:bold;">
            🎬 Launch Studio
        </button>
        """
        if __event_emitter__:
            await __event_emitter__({"type": "message", "data": {"content": launcher_html}})
        return True
```

## 7. Final Valve Check
Open the **Valves** for the action and ensure `comfy_url` points to `http://127.0.0.1:8188`. The `studio` folder inside `custom_nodes` will now handle the incoming JSON from the Canvas.

---