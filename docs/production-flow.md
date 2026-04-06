# Coozila! Studio v4.2: Technical Production Architecture

Coozila! Studio is a professional-grade AI video orchestration suite designed to bridge the gap between generative neural models and traditional cinematic workflows. By implementing a **Scripting Consensus Engine** and a **64-bit Aligned Rendering Matrix**, it ensures narrative consistency and maximum hardware efficiency for high-end film production.

## 1. Standardized Resolution Matrix (64-pixel Alignment)

To maximize **Tensor Core** efficiency and prevent sampling artifacts during the **Wan 2.2** and **RIFE** phases, the system enforces strict 64-pixel alignment. Dimensions not divisible by 64 are rejected by the orchestrator to ensure VRAM stability.

### Block A: Landscape (16:9 / Cinematic)
*Optimized for YouTube, Feature Film, and Ultra-Wide displays.*

| Profile | Exact Resolution (W x H) | Aspect Ratio | 64n Divisibility | Technical Role |
| :--- | :--- | :--- | :--- | :--- |
| **PREVIEW** | **896 x 512** | 1.75:1 | $14 \times 8$ | Native Wan 2.2 Inference / OTIO Draft |
| **HD READY** | **1280 x 704** | 1.81:1 | $20 \times 11$ | High-Quality QC Draft / Review |
| **FULL HD** | **1920 x 1088** | 1.76:1 | $30 \times 17$ | Broadcast Master (1080p AI-Aligned) |
| **MASTER 4K**| **4096 x 2304** | 1.77:1 | $64 \times 36$ | Cinematic DCI 4K Production |
| **ULTRA 8K** | **8192 x 4608** | 1.77:1 | $128 \times 72$ | Archival / Deep-Detail 8K Master |

### Block B: Portrait (9:16 / Mobile & Social)
*Optimized for TikTok, Reels, and Vertical content.*

| Profile | Exact Resolution (W x H) | Aspect Ratio | 64n Divisibility | Technical Role |
| :--- | :--- | :--- | :--- | :--- |
| **PREVIEW** | **512 x 896** | 0.57:1 | $8 \times 14$ | Vertical Native Draft / Motion Test |
| **HD READY** | **704 x 1280** | 0.55:1 | $11 \times 20$ | Vertical QC / Mobile Review |
| **FULL HD** | **1088 x 1920** | 0.56:1 | $17 \times 30$ | Social Media Master (1080p Vertical) |
| **MASTER 4K**| **2304 x 4096** | 0.56:1 | $36 \times 64$ | Vertical 4K Cinematic Production |

### Block C: Square (1:1 / UI & Art)
*Optimized for Instagram Feeds, Album Art, and UI design.*

| Profile | Exact Resolution (W x H) | Aspect Ratio | 64n Divisibility | Technical Role |
| :--- | :--- | :--- | :--- | :--- |
| **PREVIEW** | **512 x 512** | 1:1 | $8 \times 8$ | Fast Iteration / Storyboarding |
| **STANDARD** | **1024 x 1024** | 1:1 | $16 \times 16$ | High-Resolution Square / Cover Art |
| **MASTER 4K**| **4096 x 4096** | 1:1 | $64 \times 64$ | Tiled Square Mastering / Print-Ready |

---

## 2. Character Casting & Spectral Analysis

Before rendering begins, the system generates the **Production Bible** to ensure long-term visual coherence:

* **Character Anchors:** Reference images are processed via Vision-to-Prompt modules to generate dense semantic descriptors. This anchor is injected into every clip prompt to maintain fidelity of specific features (armor, facial scars, eye color) across the entire sequence.
* **Audio Pulse Analysis (`librosa` & `whisperx`):** Identifies BPM and onset peaks for rhythmic editing. Spectral analysis automatically adjusts visual lighting and saturation parameters based on the audio's emotional and frequency profile.

---

## 3. Scripting Consensus & Prompt Relay

The orchestrator operates as a **Technical Director**, enforcing a bidirectional feedback loop between the user and the AI.

1.  **Timeline Hierarchy:** Production is organized into **Chapters ➔ Scenes ➔ Clips** (atomic 2-5 second units).
2.  **The Consensus Dialogue:** The AI proposes a technical script based on audio analysis. The user reviews and edits clip descriptions within the Canvas UI until the status transitions to `READY`.
3.  **Prompt Relay Engine:** Each clip utilizes a dual-instruction set:
    * **Visual Prompt:** Action description derived from the Character Anchor.
    * **Motion Prompt:** Camera vectors including Dolly In, Pan Left, Tilt Up, Crane Shot, and Zoom Burst.
4.  **Seed Persistence:** Maintains seed continuity between adjacent clips in the same scene to eliminate visual "flickering" or character drifting.

---

## 4. Multi-Phase Execution Pipeline

### Phase A: Storyboard Sketch
Generates static thumbnails for every clip on the timeline. This allows for composition and lighting verification before committing significant VRAM resources to video generation.

### Phase B: Motion Preview (Draft)
* **Resolution:** PREVIEW (896x512).
* **Methodology:** 16 FPS using **Distill LoRA** (8-10 sampling steps).
* **Objective:** Immediate validation of motion flow and rhythmic synchronization with the audio track.

### Phase C: Master Generation & Sequential Finishing
1.  **High-Fidelity Render:** 30-40 sampling steps, LoRA disabled, leveraging the full texture depth of the Wan 2.2 model.
2.  **Temporal Interpolation (RIFE):** Frames are scaled from 16 FPS to 32 FPS, then to **64 FPS** for fluid cinematic motion.
3.  **Spatial Tiled Upscaling:** To achieve 4K/8K resolutions on consumer-grade GPUs, the system utilizes 64-pixel aligned tile processing, assembling the final master frame-by-frame without memory overflows.

---

## 5. Mastering & Professional Export

* **FFmpeg Integration:** Final muxing of processed video (AV1 or H.265 at 200Mbps+) with the original high-fidelity audio.
* **OTIO Standard:** Exporting an **OpenTimelineIO** file, allowing the entire AI-generated project to be imported directly into industry-standard NLEs like **DaVinci Resolve** or **Adobe Premiere Pro**.

---

### License
Coozila! Studio is licensed under the **MIT License**. Copyright (C) 2009 - 2026 Coozila! Team.