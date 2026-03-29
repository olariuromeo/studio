# 🚀 The Visual Production Flow

Coozila! Video Studio follows a logical production pipeline that mirrors a real-world film studio, but accelerated by Generative AI.

## 1. Activation & Context
When you open the **Studio Canvas**, the `Orchestrator` initializes a new `STUDIO_SCHEMA`. If you have been chatting with the AI, the context (style ideas, themes) is already pre-loaded into the metadata.

## 2. Audio-Visual Pulse
Upon uploading an audio track:
1.  **`audio_sync.py`** performs a spectral analysis.
2.  It identifies the **BPM** and **Onset Strength** (beats).
3.  The **Canvas** renders a visual waveform, highlighting the best moments for scene transitions.

## 3. Dynamic Directing
You select a **Cinematic Template** (e.g., "Gothic Waltz"). 
* The system automatically populates the timeline with clips.
* Each clip's duration is snapped to the nearest beat.
* For clips longer than 5 seconds, the **`payload_factory`** prepares "Extend" nodes to ensure continuity.

## 4. The Rendering Pipeline (Dual-Phase)

### Phase A: Quick Preview (The Sketch)
* **Target:** Validation of motion and composition.
* **Logic:** Uses **Distill LoRA** (Node 107) with low step counts (8-10).
* **Result:** A fast, low-res render to ensure the "Directing" matches your vision.

### Phase B: Master Render (The Final Film)
* **Target:** High-fidelity production.
* **Logic:** LoRA is disabled; sampling steps increase (25-30) for maximum Wan 2.2 detail.
* **Result:** An 8K-ready cinematic video merged with the original audio via FFmpeg.