# 🚀 The Production Flow (v4.1)

Coozila! Studio follows a professional, high-fidelity pipeline where the transition from a "Sketch" to a "Master" is governed by precision scaling and sequential post-processing. All internal rendering is strictly bound to **64-pixel alignment** to maximize GPU Tensor Core efficiency and prevent AI padding artifacts.

## 1. 📐 Standardized Resolution Matrix (64-pixel Aligned)

The orchestrator enforces these resolutions across all phases. No other dimensions are permitted to ensure perfect VRAM management and model stability.

### 📽️ Block A: Landscape (16:9 / Cinematic)
*Optimized for YouTube, Film, and TV.*

| Profile | Resolution (W x H) | Ratio | Divisibility (64) | Role |
| :--- | :--- | :--- | :--- | :--- |
| **PREVIEW** | **896 x 512** | 1.75 | $14 \times 8$ | Wan 2.2 Native / OTIO Draft |
| **HD READY** | **1280 x 704** | 1.81 | $20 \times 11$ | QC Draft (720p AI Aligned) |
| **FULL HD** | **1920 x 1088** | 1.76 | $30 \times 17$ | Broadcast Master (1080p AI Aligned) |
| **MASTER 4K**| **4096 x 2304** | 1.77 | $64 \times 36$ | Cinematic DCI 4K |
| **ULTRA 8K** | **8192 x 4608** | 1.77 | $128 \times 72$ | Deep-Detail Archival 8K |

### 📱 Block B: Portrait (9:16 / Mobile & Social)
*Optimized for TikTok, Reels, and Shorts.*

| Profile | Resolution (W x H) | Ratio | Divisibility (64) | Role |
| :--- | :--- | :--- | :--- | :--- |
| **PREVIEW** | **512 x 896** | 0.57 | $8 \times 14$ | Vertical Native Draft |
| **HD READY** | **704 x 1280** | 0.55 | $11 \times 20$ | Vertical QC |
| **FULL HD** | **1088 x 1920** | 0.56 | $17 \times 30$ | Social Media Master |
| **MASTER 4K**| **2304 x 4096** | 0.56 | $36 x 64$ | Vertical 4K Production |

### 🟦 Block C: Square (1:1 / UI & Instagram)
*Optimized for Feed-based content and Iconography.*

| Profile | Resolution (W x H) | Ratio | Divisibility (64) | Role |
| :--- | :--- | :--- | :--- | :--- |
| **PREVIEW** | **512 x 512** | 1:1 | $8 \times 8$ | Fast Iteration |
| **STANDARD** | **1024 x 1024** | 1:1 | $16 \times 16$ | High-Res Square |
| **MASTER 4K**| **4096 x 4096** | 1:1 | $64 \times 64$ | Tiled Square Mastering |

---

## 2. Activation & OTIO Initialization
When you open the **Studio Canvas**, the orchestrator initializes a new schema based on the OTIO standard.
* **Context Loading:** Metadata (Style, Characters) is injected into the OTIO schema.
* **Asset Ingestion:** Audio is placed in `data/assets`, and the `Audio_Timeline_Builder` creates the base track.

## 3. Audio-Visual Pulse & Casting
The backend triggers a multi-layer analysis:
* **Mathematical Analysis (`librosa`):** Identifies BPM and onset peaks for rhythm-synced cuts.
* **Semantic Analysis (`whisperx`):** Transcribes lyrics and performs speaker diarization.
* **The Casting Dialogue:** AI maps characters to SPEAKER_ID. Descriptions (e.g., "Elara, red hair") are stored in OTIO clip metadata.

## 4. The Rendering Pipeline (Multi-Phase Execution)

### Phase A: Quick Preview (The Sketch)
* **Target:** Fast validation of motion and consistency at **PREVIEW** resolution.
* **Logic:** Low step count ($8 \dots 10$) using Distill LoRAs.
* **Result:** 16 FPS low-res assembly for immediate feedback.

### Phase B: Master Render (High-Fidelity Generation)
* **Target:** Clean cinematic frames at **PREVIEW** resolution (896x512).
* **Logic:** Increased sampling (**30 to 40 steps**). 
* **Output:** High-quality raw sequence at 16 FPS.

### Phase C: Sequential Post-Processing (The Finishing Lab)

#### 1. Temporal Interpolation (FPS Scaling)
The project transitions from 16 FPS to a fluid master using `RIFE`:
* **Stage 1:** 16 FPS ➔ 32 FPS.
* **Stage 2:** 32 FPS ➔ 64 FPS ("Buttery Smooth").

#### 2. Multi-Phase Tiled Upscaling (Spatial Scaling)
Spatial upscale is initiated only after the frame rate is locked at 64 FPS:
* **Tiled Architecture:** `Ultimate_Upscale_API` deconstructs frames into 64-bit aligned tiles (e.g., 512x512 or 1024x1024).
* **Master Targets:** Full HD ➔ 4K ➔ 8K (Brick-by-Brick assembly).

---

## 5. Delivery & Final Mastering
* **Mastering:** `Final_Encoder_API` generates the final file (AV1/H.265) at 200Mbps+.
* **Professional Export:** Final Video + Master `.otio` file for NLE integration (Resolve/Premiere).



---

### 📝 Commit Message:
`docs: finalize production flow v4.1 with 64-bit resolution blocks 🚀📐`