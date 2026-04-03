# 🚀 The Visual Production Flow (v4.0)

Coozila! Studio follows a strict, logical production pipeline inspired by top-tier film studio workflows, accelerated by Generative AI. The entire system operates on a **Headless API** architecture, using **OpenTimelineIO (OTIO)** as the core data structure to maintain perfect synchronization between script, audio, and imagery.

## 1. Activation & OTIO Initialization (The Writer's Room)
When you open the **Studio Canvas**, the orchestrator initializes a new schema based on the OTIO standard.
* **Context Loading:** Style ideas, character descriptions, and themes previously discussed with the AI assistant are injected directly into the OTIO schema metadata to ensure creative continuity.
* **Asset Ingestion:** You upload the master audio track. The `File_Uploader` places it in the shared volume, and the `Audio_Timeline_Builder` creates the base audio track in the OTIO timeline.

## 2. Audio-Visual Pulse & Casting (The Director's Desk)
Immediately after upload, the backend triggers a multi-layer analysis to populate the timeline:
* **Mathematical Analysis (`librosa`):** Identifies the BPM and intensity points (onset peaks) to suggest precise cuts synced to the rhythm.
* **Semantic Analysis & Diarization (`whisperx`):** Transcribes lyrics with exact timestamps and separates detected voices (e.g., SPEAKER_00, SPEAKER_01).
* **The Casting Dialogue:** The AI presents the analysis in chat: *"I detected a male and a female voice. Who are these actors?"*. 
    * **Director's Input:** You define the characters (e.g., "SPEAKER_00 is Elara, burgundy gown, red hair"). The assistant maps these descriptions into the corresponding OTIO clip metadata.
* **Canvas Rendering:** The visual timeline renders the audio waveform and clip blocks mathematically aligned to lyrics and beats.

## 3. Dynamic Directing & Prompt-Relay
The director refines the automatically generated structure directly within the Canvas interface:
* **Snap-to-Beat:** Every clip duration is automatically synchronized to end exactly on a musical note or at the conclusion of a lyric phrase.
* **Continuous Morphing (`Prompt-Relay`):** Within a single clip, the director can set transformation points (Relay Points). The `dynamic_relay_composer` writes interpolation instructions into the OTIO metadata (e.g., Frame 0: "Sad Character", Frame 60: "Smiling Character"), allowing the image to evolve fluidly without hard cuts.

## 4. The Rendering Pipeline (Dual-Phase Production)

### Phase A: Quick Preview (The Sketch)
* **Target:** Validation of composition, motion, and visual consistency.
* **Logic:** The `Wan_Batch_Worker` translates OTIO clips into ComfyUI payloads using the **Turbo/Distill LoRA** (8-10 steps).
* **Result:** A low-res preview is assembled via the `FFmpeg_Stitcher` and displayed in the Canvas for immediate feedback.

### Phase B: Master Render (The Final Film)
* **Target:** High-fidelity 8K cinematic production.
* **Logic:** Upon approval, LoRA is disabled, and sampling increases to 25-30 steps for maximum Wan 2.2 detail.
* **Finishing:** * `RIFE_Interpolation_API` boosts the framerate to **64 FPS**.
    * `Ultimate_Upscale_API` performs tiled **8K** upscaling.
    * `Memory_Check` prevents hardware resource overflow during final assembly.

## 5. Delivery & Final Mastering
* **Mastering:** The `Final_Encoder_API` generates the final video file using a high bitrate (200Mbps+) and professional codecs (AV1/H.265).
* **Professional Export:** The system provides both the final video and the master `.otio` file for download, allowing the project to be imported directly into DaVinci Resolve or Premiere Pro for further post-production.