# 🛠️ Installation Guide: Coozila! Studio Canvas v4.0 (2026 Production)

## 1. System Prerequisites
Optimized for **Ubuntu 24.04+**, **CUDA 12.5**, and **Python 3.11.9**.
```bash
sudo apt update && sudo apt install -y ffmpeg git build-essential libssl-dev python3-dev
```

## 2. Step Zero: Clone the Ecosystem
We separate the **Frontend** and the **Worker** into distinct environments to prevent dependency conflicts between OpenWebUI and the heavy Wan 2.2/FLUX requirements.

```bash
# 1. Clone the Frontend
git clone https://github.com/open-webui/open-webui.git
cd open-webui

# 2. Clone the Worker (Outside the frontend root)
cd ..
git clone https://github.com/comfyanonymous/ComfyUI.git
```

## 3. Step One: Deploy Coozila! Studio "The Glue"
Your `studio` repository acts as both the interface provider and the custom processing node.

### A. Frontend Integration (OpenWebUI)
```bash
cd open-webui
git submodule add https://github.com/kabballa/studio.git backend/open_webui/static/studio
git submodule update --init --recursive
```

### B. Backend Integration (ComfyUI)
```bash
cd ../ComfyUI/custom_nodes
git clone https://github.com/kabballa/studio.git studio
```

## 4. Environment & CUDA 12.5 Management
Configure the worker environment to utilize the **cu125** index for peak RTX 3080 performance.

```bash
# Inside ComfyUI directory
python -m venv venv
source venv/bin/activate
pip install --upgrade pip

# Install Torch for CUDA 12.5 (2026 Stable)
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu125

# Install Studio & Worker dependencies
pip install -r requirements.txt
pip install accelerate diffusers transformers insightface opencv-python pydub matplotlib pandas sam2
```

## 5. Model Deployment
Ensure high-capacity models are placed in the correct paths before booting.

* **FLUX.1 (Storyboard Engine):** `ComfyUI/models/diffusion_models/flux1-krea-dev_fp8_scaled.safetensors`
* **Wan 2.2 (Video Engine):** `ComfyUI/models/unet/wan2.2_s2v_14B_fp8_scaled.safetensors`

## 6. Launch Sequence
1.  **Start the Worker (ComfyUI):**
    ```bash
    # Mandatory: Use --lowvram to fit the 11GB FLUX model on the 10GB 3080
    python main.py --port 8188 --enable-manager --lowvram --preview-method auto
    ```
2.  **Start the Frontend (OpenWebUI):**
    ```bash
    cd open-webui
    open-webui serve
    ```

---

## 7. UI Activation: Coozila! Studio Bridge
The activation logic is already included in your cloned repository. **Do not write new code for this step.**

1.  Navigate to **OpenWebUI > Workspace > Functions**.
2.  Select **Create New Function** (Action/Tool).
3.  **Import/Copy** the logic directly from the local file:
    * **File Path:** `backend/open_webui/static/studio/bridge.py`
4.  Save the function. This bridge automatically connects the Canvas UI to your ComfyUI worker and keeps the production logic in sync with your local edits.

---
