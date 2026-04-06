# 🎬 Coozila! Studio v4.2
### **The Open-Source AI Cinematic Orchestrator**

Coozila! Studio is a professional-grade video production pipeline that bridges the gap between raw Generative AI power and traditional filmmaking workflows. It transforms a simple audio-visual input into a structured, high-fidelity cinematic sequence using a **Consensus-based Scripting Engine** and a **64-bit Aligned Rendering Matrix**.

---

## 🚀 The Core Philosophy: Precision Over Chaos
Unlike standard "text-to-video" tools that produce random results, Coozila! Studio treats AI as a **Technical Director**. Every frame is governed by mathematical constraints to ensure GPU efficiency and narrative consistency.

---

## 1. 📐 The "Holy 64" Resolution Matrix
To maximize **Tensor Core** efficiency and eliminate AI padding artifacts, the Coozila! Orchestrator enforces strict 64-pixel alignment. Dimensions not divisible by 64 are strictly prohibited to ensure stability during the Wan 2.2 and Upscaling phases.

### **📽️ Block A: Landscape (Cinematic & Epic)**
*Optimized for YouTube, Film, and Ultra-Wide displays.*

| Profile | Exact Resolution (W x H) | Aspect Ratio | 64n Divisibility | Role |
| :--- | :--- | :--- | :--- | :--- |
| **PREVIEW** | **896 x 512** | 1.75:1 | $14 \times 8$ | Native Wan 2.2 / OTIO Draft |
| **HD READY** | **1280 x 704** | 1.81:1 | $20 \times 11$ | High-Quality Draft / QC Review |
| **FULL HD** | **1920 x 1088** | 1.76:1 | $30 \times 17$ | Broadcast Master (1080p AI-Aligned) |
| **MASTER 4K**| **4096 x 2304** | 1.77:1 | $64 \times 36$ | Cinematic DCI 4K Production |
| **ULTRA 8K** | **8192 x 4608** | 1.77:1 | $128 \times 72$ | Archival / Future-Proof 8K Master |

### **📱 Block B: Portrait (Mobile & Social Media)**
*Optimized for TikTok, Reels, and Vertical content.*

| Profile | Exact Resolution (W x H) | Aspect Ratio | 64n Divisibility | Role |
| :--- | :--- | :--- | :--- | :--- |
| **PREVIEW** | **512 x 896** | 0.57:1 | $8 \times 14$ | Vertical Native Draft |
| **HD READY** | **704 x 1280** | 0.55:1 | $11 \times 20$ | Vertical QC / Mobile Review |
| **FULL HD** | **1088 x 1920** | 0.56:1 | $17 \times 30$ | Social Media Master (1080p Vertical) |
| **MASTER 4K**| **2304 x 4096** | 0.56:1 | $36 \times 64$ | Vertical 4K Cinematic Production |

### **🟦 Block C: Square (Art & Interfaces)**
*Optimized for Instagram Feeds, Cover Art, and UI.*

| Profile | Exact Resolution (W x H) | Aspect Ratio | 64n Divisibility | Role |
| :--- | :--- | :--- | :--- | :--- |
| **PREVIEW** | **512 x 512** | 1:1 | $8 \times 8$ | Fast Iteration / Storyboarding |
| **STANDARD** | **1024 x 1024** | 1:1 | $16 \times 16$ | High-Res Square / Album Art |
| **MASTER 4K**| **4096 x 4096** | 1:1 | $64 \times 64$ | Tiled Square Mastering / Print-Ready |

---

## 2. 🎭 Character Casting & Spectral Analysis
Before the first watt is consumed by the GPU, the system builds the **Production Bible**:

* **Character Anchors:** Uploaded reference images are processed via Vision-to-Prompt modules to generate dense semantic descriptions. This "Anchor" is injected into every subsequent prompt to ensure character consistency (e.g., specific armor details, scars, or eye color) across the entire timeline.
* **Audio Pulse Analysis:** Using `librosa`, the system identifies:
    * **BPM & Onset Peaks:** Scene transitions are mathematically snapped to the rhythmic "kick" of the audio.
    * **Spectral Centroid:** Visual saturation and lighting moods are automatically adjusted to match the audio's brightness.

---

## 3. 🤝 Scripting Consensus & Prompt Relay
The core of the studio is a bidirectional feedback loop between the Human and the AI Director.

1.  **Timeline Hierarchy:** Production is strictly organized into **Chapters ➔ Scenes ➔ Clips** (2-5 second units).
2.  **The Consensus Dialogue:** The AI proposes a technical script based on the audio mood. The user reviews, edits, and locks the data in the Canvas UI until the status transitions to `READY`.
3.  **Prompt Relay:** Each clip carries a dual-instruction set:
    * **Visual Prompt:** Detailed action based on the Character Anchor.
    * **Motion Prompt:** Camera vectors (e.g., *Dolly In, Pan Left, Tilt Up, Crane Shot, Zoom Burst*).
4.  **Seed Persistence:** The system maintains seed continuity between adjacent clips in the same scene to prevent visual "flicker."

---

## 4. 🚀 The Rendering Lab (Multi-Phase Pipeline)

### **Phase A: Storyboard Sketch**
Generates static thumbnails for every clip. This allows for composition and lighting verification before committing significant VRAM to video generation.

### **Phase B: Motion Preview (Draft)**
* **Resolution:** PREVIEW (896x512).
* **Technique:** 16 FPS using **Distill LoRA** (8-10 sampling steps).
* **Goal:** Instant validation of motion flow and rhythmic synchronization.

### **Phase C: Master Generation & Sequential Finishing**
1.  **High-Fidelity Render:** 30-40 sampling steps, LoRA disabled, leveraging the full texture depth of Wan 2.2.
2.  **Temporal Interpolation (RIFE):** Frames are scaled from 16 FPS ➔ 32 FPS ➔ **64 FPS** for "Buttery Smooth" cinematic motion.
3.  **Spatial Tiled Upscaling:** To reach 4K/8K resolutions on 10-12GB GPUs, the system utilizes 64-pixel aligned tile processing, assembling the final master frame-by-frame.

---

## 5. 📦 Final Mastering & Professional Export
* **FFmpeg Integration:** Muxing high-bitrate video (AV1/H.265 at 200Mbps+) with the original high-fidelity audio track.
* **OTIO Standard:** Exporting an **OpenTimelineIO** file, allowing the entire AI-generated timeline to be imported directly into **DaVinci Resolve** or **Adobe Premiere** for professional color grading and final touches.

---

### **License & Contributions**
Coozila! Studio is licensed under the **MIT License**. We welcome contributions from developers, AI researchers, and filmmakers. 

**Join the revolution. Build the future of cinema.** 🪓🚀🎬