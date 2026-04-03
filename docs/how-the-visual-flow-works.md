# 🚀 The Visual Production Flow

Coozila! Video Studio follows a strict, logical production pipeline that mirrors a real-world film studio, but is accelerated and automated by Generative AI. The entire flow operates on a **Headless API** architecture: the frontend (Open-WebUI) sends mathematical JSON payloads to the backend (ComfyUI), receiving back rendering paths without ever blocking the user interface.

## 1. Activation & Pre-Production (The Writer's Room)
When you open the **Studio Canvas**, the `Orchestrator` initializes a new `STUDIO_SCHEMA`.
1.  **Context Loading:** Any style ideas, character descriptions, or themes discussed in the Open-WebUI chat are pre-loaded into the schema metadata.
2.  **Asset Ingestion:** You upload your base track (e.g., "Eternisys.mp3"). The `File_Uploader` safely stores it in the shared `temp_assets/` volume.

## 2. Audio-Visual Pulse & Casting (The Director's Desk)
Upon uploading the audio track, the backend initiates a dual-layer analysis:
1.  **Mathematical Analysis (`librosa` / `pydub`):** Identifies track duration, BPM, onset strength (beats), and massive energy shifts (beat drops, bridges).
2.  **Semantic Analysis & Diarization (`whisperx`):** Transcribes lyrics with millisecond accuracy and separates distinct voices (e.g., `SPEAKER_00` vs `SPEAKER_01`).
3.  **The Casting Dialogue:** The AI Assistant presents the analysis in the chat, asking the director to assign physical descriptions to the detected voices (e.g., "SPEAKER_00 is a red-haired woman in a burgundy gown").
4.  **Canvas Rendering:** The Canvas displays the visual waveform, overlaying the generated Scene Breakdown (Storyboard) exactly where the lyrics and beats dictate.

## 3. Dynamic Directing & Prompt-Relay
The director reviews the AI-generated timeline in the Canvas.
* **Snap-to-Beat:** Each clip's duration is perfectly synchronized to the nearest mathematical beat or lyric cue.
* **Continuous Morphing (`Prompt-Relay`):** Instead of relying entirely on hard cuts, the director can set "Relay Points" within a single shot. The `dynamic_relay_composer` creates mathematical instructions (e.g., Frame 0: "Woman singing", Frame 60: "Woman transforms into mist"), allowing a continuous shot to evolve exactly on the beat.
* **Approval:** Once the text-based storyboard and transitions are approved, the batch is queued.

## 4. The Rendering Pipeline (Dual-Phase Production)

### Phase A: Quick Preview (The Sketch)
* **Target:** Fast validation of motion, Prompt-Relay morphing, and composition.
* **Logic:** The `Wan_Batch_Worker` sends low-resolution, low-step (8-10 steps) payloads to the ComfyUI API using the **Turbo/Distill LoRA**.
* **Result:** The `FFmpeg_Stitcher` quickly concatenates these low-res clips over the original audio, displaying a rough-cut preview directly in the Canvas.

### Phase B: Master Render (The Final Film)
* **Target:** High-fidelity, cinematic production.
* **Logic:** The timeline is locked. LoRA is disabled; sampling steps increase (25-30) for maximum Wan 2.2 detail.
* **Finishing:** * `RIFE_Interpolation_API` pushes the framerate to buttery-smooth 64 FPS.
    * `Ultimate_Upscale_API` runs an 8K tiled upscale, closely monitored by the `Memory_Check` module to prevent VRAM overflow.
* **Result:** `Final_Encoder_API` uses FFmpeg (AV1/H.265 at 200Mbps+) to merge the stunning 8K video with the original audio track, providing a direct download link in the Open-WebUI chat.