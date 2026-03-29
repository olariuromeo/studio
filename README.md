<p align="center"\>
    <a href="[https://github.com/coozila/video-studio/blob/dev/LICENSE](https://www.google.com/search?q=https://github.com/coozila/video-studio/blob/dev/LICENSE)" target="\_blank"\>\<img src="[https://img.shields.io/badge/license-MIT-7e22ce](https://www.google.com/search?q=https://img.shields.io/badge/license-MIT-7e22ce)" alt="License" /\>\</a\>
</p\>

> If you enjoy the project, please consider giving us a GitHub star ⭐️. Thank you\!

## Sponsors

If you want to support our project and help us grow it, you can [become a sponsor on GitHub](https://www.google.com/search?q=https://github.com/sponsors/coozila)

<p align="center"\>
    <a href="[https://github.com/sponsors/coozila](https://www.google.com/search?q=https://github.com/sponsors/coozila)"\>
    </a\>
</p\>

# 🎬 Coozila\! Video Studio

## The Ultimate AI Music Video Orchestrator with Visual Canvas

**Coozila\! Video Studio** is not just a backend; it is a hybrid editing environment integrated directly into **ComfyUI**. By clicking the dedicated button in the chat interface, you open an **Interactive Canvas** that allows you to visually manage your video projects, synchronizing cinematic directing with musical rhythm (BPM) in real-time.

### Why Choose Coozila\! Video Studio?

  - **Rhythmic Precision**: Achieve perfect synchronization with the beat using advanced audio analysis algorithms (Librosa-based).
  - **Visual Editing Workflow**: Manage your timeline visually rather than through code, using an intuitive Canvas integrated within the ComfyUI chat.
  - **Dynamic Graph Generation**: Automatically build complex node graphs for **Wan 2.2**, tailored specifically to your project's duration.
  - **AI-Powered Style Vision**: Extract visual aesthetics directly from reference images to maintain artistic consistency across all shots.
  - **Dual Rendering Modes**: Save time and resources with a "Quick Preview" (Distill LoRA) mode before committing to high-fidelity 8K final renders.

### Documentation

  - [Core Project Structure](docs/project-structure)
  - [The Visual Production Flow](docs/how-the-visual-flow-works)
  - [Detailed Installation Guide](docs/INSTALL.md) *(Coming Soon)*

### Core Features

  - **Interactive Timeline**: Visually render clips, audio waveforms, and style previews directly in your browser.
  - **Master Schema (Timeline.1)**: Utilizes a professional data standard compatible with industry-standard editing software (FCPXML).
  - **Automated Directing**: Apply cinematic templates (Epic Romance, Action Track) that auto-adjust to the music's structure.
  - **Persistent Session Memory**: Project states are automatically saved; never lose your progress even if you close the window.
  - **Multi-Threaded Architecture**: Harness the power of sequential rendering for Wan 2.2, managing VRAM through intelligent chunking.

### Easy Deployment

The package comes with a straightforward setup process (`setup_studio.py`), enabling developers to configure the **Python 3.11** environment and required folder structures in minutes. Get your "✨ Studio" button running and start creating immediately.

### Who Is It For?

  - **AI Artists**: Looking for total control over montage without leaving the ComfyUI ecosystem.
  - **Music Producers**: In need of high-quality music videos perfectly synced to their tracks.
  - **Content Creators**: Aiming for professional-grade cinematic results with minimal manual effort and maximum creative freedom.

-----

## Project Structure

### 🖥️ I. Interface & UI (Web/JS)

  - **`studio_tab.js`**: The UI extension that injects the Studio button and handles the modal overlay.
  - **`canvas_renderer.js`**: The graphics engine that translates the Studio Schema into interactive timeline blocks.

### 🧠 II. Logic Components (Python - Backend)

  - **`orchestrator.py`**: The Central Command managing the project lifecycle and cloning templates.
  - **`audio_sync.py`**: The Rhythmic Engine that calculates "cut points" based on BPM analysis.
  - **`payload_factory.py`**: The Instruction Factory that dynamically wires Wan 2.2 nodes.
  - **`style_engine.py`**: The Architect building complex prompts based on chosen styles and camera logic.

### 💾 III. Data Libraries (JSON Templates)

  - **`master_schema.json`**: The technical blueprint for professional timelines.
  - **`styles.json`**: A curated catalog of visual aesthetics (Nolan, Gothic, Anime).
  - **`shot_presets.json`**: A library of pre-calculated cinematic camera movements.

-----

## How the Visual Flow Works

1.  **Activation**: Click the **✨ Studio** button in the Chat area to open the **Studio Canvas**.
2.  **Import**: Upload your track. `audio_sync.py` immediately draws the waveform on the Canvas.
3.  **Directing**: Select a Cinematic Preset. The Canvas populates with shots perfectly timed to the beat.
4.  **Preview**: Trigger a "Quick Preview" job (Distill) to validate camera motion and composition.
5.  **Finalize**: Once satisfied, hit **Master Render** to generate the high-fidelity 8K final video.

-----

## References and Credits

### AI Contributions:

We gratefully acknowledge **Hypatia AI**, a project of **Coozila\! AGI**, for providing intelligent assistance and support in developing this documentation and enhancing the overall project architecture.

### What is Coozila\! Studio Schema?

It is a structured data format (Timeline, Track, Clip) designed to be the bridge between Generative AI and professional non-linear video editors (NLEs).

### What is Wan 2.2?

The state-of-the-art open-source video model in 2026, which Coozila\! orchestrates to produce stable, artifact-free results at cinematic resolutions.

## Installation Assistance

If you would like personalized assistance with the installation of this product, please contact the **Coozila\! Team** at [lab@coozila.com](mailto:lab@coozila.com). We will be happy to help you with the setup process and ensure a smooth integration into your workflow.

Based on the size and complexity of your project, we will provide you with a tailored pricing quote.

You can also check out our developer profile: [Romulus (Coozila\! Founder)](https://www.coozila.com/plus/view-persons-profile/romulus).

## Trademarks and Copyright

### Copyright

Copyright (C) 2009 - 2026 Coozila\! Team. Licensed under the **MIT License**.

### Licenses

  - **Coozila\! Studio**: [MIT License](https://www.google.com/search?q=https://github.com/coozila/video-studio/blob/main/LICENSE)
  - **Wan 2.2**: [Wan License](https://www.google.com/search?q=https://github.com/wan-video/Wan2.1/blob/main/LICENSE.md)
  - **ComfyUI**: [GPL License](https://www.google.com/search?q=https://github.com/comfyanonymous/ComfyUI/blob/master/LICENSE)

### Disclaimer

This product is provided "as is," without any guarantees regarding performance in high-load production environments without prior testing. Users are responsible for their own GPU resources and compliance with the licenses of the AI models utilized.

-----

**Happy Coding & Filming\!**

-----
