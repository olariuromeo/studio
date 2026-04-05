<p align="center"\>
    <a href="[https://github.com/kabballa/studio/dev/dev/LICENSE](https://github.com/kabballa/studio/dev/dev/LICENSE)" target="\_blank"\>\<img src="[https://img.shields.io/badge/license-MIT-1c7ed6](https://img.shields.io/badge/license-MIT-1c7ed6)" alt="License" /\>\</a\>
</p\>

> If you enjoy the project, please consider giving us a GitHub star. Thank you\!

## Sponsors

If you want to support our project and help us grow it, you can [become a sponsor on GitHub](https://github.com/sponsors/coozila)

-----

# Coozila\! Studio v4.0

### The Latent Orchestrator for Deterministic Cinema

**Coozila\! Studio** is a professional-grade production environment built directly into **ComfyUI**. Engineered for the **2026** stack (**CUDA 12.5 / RTX 3080+**), it transforms the interface into a **Latent Control Surface**, synchronizing high-fidelity generative video with rhythmic audio structures (BPM) in real-time.

### Why Choose Coozila\! Studio?

  * **Deterministic Orchestration**: Leverages **FLUX.1 Krea-dev** for high-fidelity semantic anchoring and **Wan 2.2 (14B)** for state-of-the-art motion synthesis.
  * **Prompt-Relay Logic**: The definitive solution for visual continuity. It enables **Intra-Shot Dynamics**, allowing multiple seamless actions and scene evolutions within a single continuous video path.
  * **Tiered Inference Pipeline**: Optimized VRAM management that maneuvers from **Distill LoRA Previews** to **720p Production Masters** without memory overflows.
  * **Kinetic-Audio Precision**: Achieves frame-perfect synchronization using advanced **Librosa-based** spectral analysis to map motion vectors to audio energy.
  * **Actor Persistence Engine**: Hard-locks character consistency across disparate shots using integrated **IP-Adapter FaceID** logic directly on the Canvas.
  * **Dynamic Graph Architecture**: Automatically constructs complex, duration-aware node topologies for **Wan 2.2** based on your audio track's structural metadata.

### Documentation

  * [Core Project Structure](https://www.google.com/search?q=docs/project-structure.md)
  * [The Visual Production Flow](https://www.google.com/search?q=docs/how-the-visual-flow-works.md)
  * [Detailed Installation Guide (CUDA 12.5)](https://www.google.com/search?q=docs/INSTALL.md)

-----

### Core Features

  * **Interactive Visual Canvas**: A node-free timeline interface to manage clips, waveforms, and latent previews—eliminating manual node connection guesswork.
  * **Audio-Driven Prompt Routing**: Studio dynamically generates Prompt-Relay instructions based on spectral peaks, shifting narrative weight exactly on the beat.
  * **Intra-Shot Dynamics**: Evolve environments internally (e.g., temporal morphing or lighting shifts) without hard cuts, maintaining world-building integrity.
  * **Master Schema (Timeline.1)**: A professional data protocol compatible with industry-leading NLEs (**FCPXML/EDL**).
  * **Automated Directing**: Apply cinematic templates (Epic, Noir, Sci-Fi) that auto-adjust camera kinematics to your music's BPM.
  * **Intelligent VRAM Chunking**: Sequential rendering for **Wan 2.2**, enabling high-quality 720p exports on 10GB-12GB consumer-grade hardware.
  * **Identity Lock**: One-click face persistence to ensure your protagonist remains identical from pre-production to the final master.

-----

## The Production Pipeline (4-Stage Workflow)

Coozila\! Studio utilizes a progressive rendering flow to maximize the **RTX 3080** duty cycle:

1.  **Semantic Anchoring (Pre-Production)**: Uses **FLUX.1 + Prompt-Relay** to generate locked character stills and scenography for each musical beat.
2.  **Temporal Mockup (Distill Mode)**: Employs low-step **Distill LoRA** nodes to validate motion paths and Prompt-Relay handovers in seconds.
3.  **Synthesis Master (720p)**: Generates the final cinematic output using the full **Wan 2.2** engine. Latent stitching is handled by Prompt-Relay routing, while hard cuts are finalized via FFmpeg.
4.  **Neural Mastering (Roadmap)**: Integration for **LTX Video-to-Video** and specialized Diffusion Upscalers to push masters into 4K/8K territory (Coming in v4.5).

-----

## How the Visual Flow Works

1.  **Activation**: Click the **Studio** button in your interface to launch the **Canvas**.
2.  **Spectral Analysis**: Upload your .wav track. The system renders the waveform, calculates BPM, and extracts kinetic energy peaks.
3.  **Visual Anchoring**: Use **FLUX.1 + Prompt-Relay** to lock characters and environments across your storyboard.
4.  **Latent Scripting**: The AI calculates frame-accurate Prompt-Relay transitions based on music energy and asset metadata.
5.  **Preview**: Trigger a **Distill Render** to verify motion vectors and temporal morphing.
6.  **Export**: Run the **Master Render** to export your cinematic **720p** video, natively synced to audio.

-----

## References and Credits

### AI Strategy

This documentation and architecture were refined with the assistance of **Hypatia AI**, a **Coozila\! AGI** project, ensuring compliance with 2026's state-of-the-art computational standards.

### Technical Core

  * **Wan 2.2**: The definitive open-source video model of 2026.
  * **Prompt-Relay**: Cutting-edge cross-attention routing for artifact-free cinematic consistency.

## Support & Installation

For enterprise licensing or high-load server implementations, contact the **Coozila\! Team** at lab@coozila.com.

**Copyright (C) 2009 - 2026 Coozila\! Team. Licensed under the MIT License.**

-----

**Happy Coding & Filming\!**