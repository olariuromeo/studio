// ----------------------------------------------------------------------------------#
//                                                                                   //
//   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              //
//   Coozila! Team    lab@coozila.com                                                //
//                                                                                   //
// ----------------------------------------------------------------------------------#

/**
 * Location: static/canvas/orchestrator.js
 * Description: Professional API Translator for Wan 2.2. 
 * Handles Dynamic Schemas from Python but includes robust internal FALLBACKS.
 */

export class StudioOrchestrator {
    constructor(config = {}) {
        this.comfyUrl = config.comfyUrl || 'http://localhost:8188';
        console.log(`🚀 [Orchestrator] Connected to Worker at: ${this.comfyUrl}`);
    }

    /**
     * Extracts values from Python's Schema with ROBUST DEFAULT FALLBACKS.
     * Prevents crashes if the API is down or returns incomplete data.
     */
    extractConfig(data = {}) {
        const engine = data.engine_config || {};
        const res = engine.resolution || {};
        const samp = engine.sampling || {};
        const state = data.initial_state || {};
        
        // Handle Seed (-1 means random)
        const seedVal = (state.seed !== undefined && state.seed !== -1) 
            ? state.seed 
            : Math.floor(Math.random() * 1e12);

        return {
            seed: seedVal,
            steps: samp.steps || 4, // Default to Turbo/Preview
            cfg: samp.cfg || 1.0,
            sampler_name: samp.sampler || "uni_pc",
            scheduler: samp.scheduler || "simple",
            prompt: state.prompt || "Cinematic shot, high quality, highly detailed.",
            negative_prompt: state.negative_prompt || "distorted, blurry, low quality, static",
            model_unet: engine.model_unet || "wan2.2_s2v_14B_fp8_scaled.safetensors",
            vae_name: engine.vae_name || "wan2.2_vae.safetensors",
            lora_name: engine.lora_name || "wan2.2_distill_lora.safetensors",
            width: res.width || 896,   // Safe 64-bit aligned Wan 2.2 default
            height: res.height || 512,
            frames: state.frames || 81, // Default 4 seconds at 20fps
            ref_image: state.ref_image || "actor_ref.png",
            audio_file: state.audio_file || "default_ambience.wav",
            session_id: data.session_id || "fallback_session"
        };
    }

    /**
     * Dispatcher for Video Render (Phase 2)
     */
    async dispatchJob(data) {
        console.log("🧠 Orchestrator: Dispatching Video Render job...");
        const payload = this.buildWanPayload(data);
        const response = await this.sendToWorker(`${this.comfyUrl}/prompt`, payload);
        
        if (response && response.prompt_id) {
            return await this.waitForJob(response.prompt_id);
        }
        return response;
    }

    /**
     * Dispatcher for Storyboard Stills (Phase 1)
     */
    async dispatchStoryboard(data) {
        console.log("🎨 Orchestrator: Dispatching Storyboard Batch...");
        const payload = this.buildStoryboardPayload(data);
        const response = await this.sendToWorker(`${this.comfyUrl}/prompt`, payload);

        if (response && response.prompt_id) {
            return await this.waitForJob(response.prompt_id);
        }
        return response;
    }

    /**
     * Payload for Video Render (Full Sequence)
     */
    buildWanPayload(data) {
        const conf = this.extractConfig(data);
        
        return {
            "client_id": `vid_${conf.session_id}_${Date.now()}`,
            "prompt": {
                "3": { "inputs": { "seed": conf.seed, "steps": conf.steps, "cfg": conf.cfg, "sampler_name": conf.sampler_name, "scheduler": conf.scheduler, "denoise": 1, "model": ["107", 0], "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["93", 0] } },
                "6": { "inputs": { "text": conf.prompt, "clip": ["38", 0] } },
                "7": { "inputs": { "text": conf.negative_prompt, "clip": ["38", 0] } },
                "37": { "inputs": { "unet_name": conf.model_unet, "weight_dtype": "fp8_e5m2" } },
                "38": { "inputs": { "clip_name": "google/t5-v1_1-xxl", "type": "wan" } },
                "39": { "inputs": { "vae_name": conf.vae_name } },
                "52": { "inputs": { "image": conf.ref_image } },
                "58": { "inputs": { "audio": conf.audio_file } },
                "93": { "inputs": { "width": conf.width, "height": conf.height, "length": conf.frames, "batch_size": 1, "vae": ["39", 0], "ref_image": ["52", 0] } },
                "107": { "inputs": { "lora_name": conf.lora_name, "strength_model": 1, "model": ["37", 0] } }
            }
        };
    }

    /**
     * Payload for Static Storyboard Images (One per beat)
     */
    buildStoryboardPayload(data) {
        const conf = this.extractConfig(data);
        
        return {
            "client_id": `sb_${conf.session_id}_${Date.now()}`,
            "prompt": {
                "3": { "inputs": { "seed": conf.seed, "steps": conf.steps, "cfg": conf.cfg, "sampler_name": conf.sampler_name, "scheduler": conf.scheduler, "denoise": 1, "model": ["107", 0], "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["93", 0] } },
                "6": { "inputs": { "text": conf.prompt, "clip": ["38", 0] } },
                "7": { "inputs": { "text": conf.negative_prompt, "clip": ["38", 0] } },
                "37": { "inputs": { "unet_name": conf.model_unet, "weight_dtype": "fp8_e5m2" } },
                "38": { "inputs": { "clip_name": "google/t5-v1_1-xxl", "type": "wan" } },
                "39": { "inputs": { "vae_name": conf.vae_name } },
                "52": { "inputs": { "image": conf.ref_image } },
                "93": { "inputs": { "width": conf.width, "height": conf.height, "length": 1, "batch_size": 1, "vae": ["39", 0], "ref_image": ["52", 0] } }, // length 1 for stills
                "107": { "inputs": { "lora_name": conf.lora_name, "strength_model": 1, "model": ["37", 0] } },
                "113": { "inputs": { "filename_prefix": "STORYBOARD", "images": ["80", 0] } },
                "80": { "inputs": { "samples": ["3", 0], "vae": ["39", 0] }, "class_type": "VAEDecode" }
            }
        };
    }

    /**
     * Helper to send JSON to ComfyUI
     */
    async sendToWorker(url, payload) {
        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error("❌ Worker Sync Failure:", error);
            return { status: "error", message: error.message };
        }
    }

    /**
     * Checks job status on ComfyUI History API
     */
    async checkJobStatus(promptId) {
        try {
            const response = await fetch(`${this.comfyUrl}/history/${promptId}`);
            const history = await response.json();
            return history[promptId] ? { status: "done", data: history[promptId] } : { status: "processing" };
        } catch (error) {
            return { status: "error", message: error.message };
        }
    }

    /**
     * Professional Polling: Awaits job completion before returning results.
     */
    async waitForJob(promptId, timeout = 600000) { // 10 min timeout default
        const start = Date.now();
        while (Date.now() - start < timeout) {
            const status = await this.checkJobStatus(promptId);
            
            if (status.status === "done") {
                console.log(`✅ [Orchestrator] Job ${promptId} completed successfully.`);
                return status.data;
            }
            if (status.status === "error") {
                throw new Error(`Job failed in ComfyUI: ${status.message}`);
            }
            
            await new Promise(r => setTimeout(r, 3000));
            console.log(`⏳ [Orchestrator] Rendering in progress (ID: ${promptId})...`);
        }
        throw new Error("Job Timeout: ComfyUI took too long to respond.");
    }
}