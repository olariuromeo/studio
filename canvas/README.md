<p align="center"\>
    <a href="https://github.com/kabballa/studio/dev/dev/LICENSE" target="_blank"><img src="https://img.shields.io/badge/license-MIT-1c7ed6" alt="License" /></a>
</p\>

> If you enjoy the project, please consider giving us a GitHub star ⭐️. Thank you\!

## Sponsors

If you want to support our project and help us grow it, you can [become a sponsor on GitHub](https://github.com/sponsors/coozila)

-----

# 🎬 Coozila\! Video Studio v4.0

## The Ultimate Hybrid AI Orchestrator for Cinematic Production

**Coozila\! Video Studio** is a professional-grade production environment built directly into **ComfyUI**. Optimized for the **2026** tech stack (**CUDA 12.5 / RTX 3080**), it transforms your chat interface into an **Interactive Visual Canvas**. This allows you to orchestrate high-fidelity video projects by synchronizing cinematic directing with musical rhythm (BPM) in real-time.

### Why Choose Coozila\! Video Studio?

  * **Hybrid Powerhouse**: Leverages **FLUX.1 Krea-dev** for ultra-detailed storyboards and **Wan 2.2 (14B)** for state-of-the-art cinematic motion.
  * **Tiered Rendering Pipeline**: Optimized VRAM management. Move from high-speed **Distill LoRA Previews** to **720p Production Masters** seamlessly.
  * **Rhythmic Precision**: Achieve frame-perfect synchronization using advanced **Librosa-based** audio analysis.
  * **Visual Storyboarding**: Lock actor consistency across shots using integrated **IP-Adapter FaceID** logic directly on the Canvas.
  * **Dynamic Graph Architecture**: Automatically builds complex, duration-aware node graphs for **Wan 2.2** based on your audio track's structure.

### Documentation

  * [Core Project Structure](https://www.google.com/search?q=docs/project-structure.md)
  * [The Visual Production Flow](https://www.google.com/search?q=docs/how-the-visual-flow-works.md)
  * [Detailed Installation Guide (CUDA 12.5)](https://www.google.com/search?q=docs/INSTALL.md)

-----

### Core Features

  * **Interactive Timeline**: Visually manage clips, audio waveforms, and style previews. No more "guessing" node connections.
  * **Master Schema (Timeline.1)**: A professional data standard compatible with industry-leading NLEs (FCPXML/EDL).
  * **Automated Directing**: Apply cinematic templates (Epic Action, Noir, Sci-Fi) that auto-adjust to your music's BPM.
  * **Intelligent VRAM Chunking**: Sequential rendering for **Wan 2.2**, allowing high-quality 720p exports even on 10GB-12GB consumer cards.
  * **Actor Persistence**: One-click face locking to ensure your protagonist remains identical from the first shot to the last.

-----

## ⚡ The Production Pipeline (3-Stage Workflow)

To maximize resources on the **RTX 3080**, Coozila\! Studio utilizes a progressive rendering flow:

1.  **Quick Preview (Distill Mode)**: Uses low-step **Distill LoRA** nodes to validate motion and composition in seconds.
2.  **Production Master (720p)**: Generates the final cinematic output at **720p** resolution using the full **Wan 2.2** engine for maximum physics and detail.
3.  **Future Upscaling (Roadmap)**: Planned integration for **LTX Video-to-Video** and specialized Diffusion Upscalers to push 720p masters into 4K/8K territory (*Coming in v4.5*).

-----

## Project Structure

### 🖥️ I. Interface & UI (Web/JS)

  * **`canvas.js`**: The primary orchestrator for the visual timeline.
  * **`payload_factory.js`**: Translates UI actions into JSON instructions for ComfyUI.

### 🧠 II. Logic Components (Python - Backend)

  * **`orchestrator.py`**: Handles project lifecycles and template cloning.
  * **`audio_sync.py`**: The "Heartbeat" engine for rhythmic cut-point calculation.
  * **`payload_factory.py`**: Dynamically wires the **FLUX/Wan** hybrid nodes.

### 💾 III. Data Libraries (JSON Templates)

  * **`master_schema.json`**: The technical blueprint for the timeline.
  * **`styles.json`**: A curated catalog of 2026's best visual aesthetics.

-----

## How the Visual Flow Works

1.  **Activation**: Click the **✨ Studio** button in your chat interface to launch the **Canvas**.
2.  **Import**: Upload your `.wav` track. The system immediately renders the waveform and calculates BPM.
3.  **Storyboard**: Use **FLUX.1** to generate consistent character stills for each beat.
4.  **Preview**: Trigger a **Distill Render** to check motion paths and character consistency.
5.  **Master**: Hit **Master Render** to export your cinematic **720p** video synced to the audio.

-----

## References and Credits

### AI Contributions

This documentation and architecture were enhanced with the assistance of **Hypatia AI**, a project of **Coozila\! AGI**, ensuring the project remains at the cutting edge of 2026's AI standards.

### What is Wan 2.2?

The definitive open-source video model of 2026, orchestrated by Coozila\! to produce artifact-free, high-motion cinematic results.

## Support & Installation

For personalized enterprise assistance or high-load server setup, contact the **Coozila\! Team** at [lab@coozila.com](mailto:lab@coozila.com).

**Copyright (C) 2009 - 2026 Coozila\! Team. Licensed under the MIT License.**

-----

**Happy Coding & Filming\!**

-----