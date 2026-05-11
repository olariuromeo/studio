# 🚀 ComfyUI Studio – Feature Overview

## 🧠 Core Engine

* ComfyUI integrated as a Git submodule
* Automatic startup via script (`nohup`, PID tracking, log file)
* Configurable network binding (`--listen 0.0.0.0`)
* VRAM mode support (`$VRAM_MODE`)

---

## 🎬 AI / Model Pipeline

* WAN video / talking-head pipeline
* MultiTalk patch system
* Separate VAE loading
* Dynamic VRAM staging
* On-demand model loading (no full preload)

---

## ⚙️ GPU / CUDA Stack

* NVIDIA auto-detection (`nvidia-smi`)
* CUDA environment bootstrap:

  * `CUDA_HOME`
  * `PATH`
  * `LD_LIBRARY_PATH`
* `nvcc` validation
* PyTorch CUDA runtime test

---

## 🔥 PyTorch Layer

* Dynamic install based on `CUDA_VERSION`
* CPU fallback if CUDA install fails
* Full validation:

  * Torch version
  * CUDA runtime
  * GPU tensor test

---

## ⚡ FlashAttention Optimization

* Built from source (avoids ABI mismatch)
* Matches exact local PyTorch + CUDA
* Resource-limited compilation:

  * `MAX_JOBS = nproc / 2`
* GPU architecture targeting:

  * `TORCH_CUDA_ARCH_LIST="8.6"` (RTX 3080)
* Post-build validation

---

## 🧩 Modular Engine System

* External module execution system
* Example engines:

  * WAN Engine
  * Extendable for additional modules
* Isolated execution (`PYTHONNOUSERSITE=1`)

---

## 📦 Dependency Layers

* Core dependencies (`requirements.txt`)
* Manager dependencies
* Plugin-specific requirements

---

## 🔌 Git Submodule System

* ComfyUI
* ComfyUI-Manager
* WanVideoWrapper
* HeartMuLa
* Open-WebUI

Features:

* Auto-registration if missing
* Recursive initialization
* Tag pinning support

---

## 🧠 Manager Integration

* ComfyUI-Manager as submodule
* Strict version pinning via `MANAGER_TAG`
* Auto-symlink into:

  ```
  custom_nodes/ComfyUI-Manager
  ```
* Automatic dependency installation

---

## 🧪 System Validation

* GPU availability check
* Device name output
* Post-install verification

---

## 🧹 Self-Cleaning Environment

* Full `venv` wipe on setup
* Clean reproducible builds
* No dependency drift

---

## 🐍 Python Management

* ASDF support
* Version controlled via:

  ```
  COMFY_PYTHON_VERSION
  ```

---

## 🧾 Environment Config System

* Mandatory `.env.dev`
* Auto-generated from `.env.example`
* Centralized configuration:

  * repositories
  * versions / tags
  * ports
  * CUDA settings

---

## 🧠 Resource Control

* Controlled compilation load (FlashAttention)
* VRAM optimization modes
* Swap-aware execution (large model support)
* Designed for heavy workloads (WAN21)

---

## 📡 Process Management

* Background execution (`nohup`)
* PID tracking:

  ```
  .comfy.pid
  ```
* Log file:

  ```
  comfy.log
  ```
* Process health check

---

## 🔄 Port Management

* Automatic port cleanup:

  ```
  fuser -k <port>
  ```

---

## 🧱 Architecture Summary

* Modular
* Reproducible
* GPU-aware
* Production-ready

---

## 💥 Summary

This setup provides:

* A fully automated AI pipeline
* High-performance GPU integration
* Modular extensibility via submodules
* Stable and reproducible environment provisioning
* Advanced optimization for large-scale inference workloads
