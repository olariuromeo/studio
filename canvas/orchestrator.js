// ----------------------------------------------------------------------------------#
//                                                                                   #
//   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
//   Coozila! Team    lab@coozila.com                                                #
//                                                                                   #
// ----------------------------------------------------------------------------------#

/**
 * Location: studio/orchestrator.js
 * Description: Professional API Translator for Wan 2.2. 
 * Handles 720p Storyboard (Stills) and Video Render jobs.
 */

export class StudioOrchestrator {
    constructor(config = {}) {
        this.comfyUrl = config.comfyUrl || 'http://localhost:8188';
    }

    /**
     * Dispatcher for Video Render (Phase 2)
     */
    async dispatchJob(data) {
        console.log("🧠 Orchestrator: Building 720p Video payload...");
        const payload = this.buildWanPayload(data);
        return this.sendToWorker(`${this.comfyUrl}/prompt`, payload);
    }

    /**
     * Dispatcher for Storyboard Stills (Phase 1)
     */
    async dispatchStoryboard(data) {
        console.log("🎨 Orchestrator: Building Storyboard Batch payload...");
        
        // We build the graph for a batch of N static images
        const payload = this.buildStoryboardPayload(data);
        
        return this.sendToWorker(`${this.comfyUrl}/prompt`, payload);
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
            
            if (!response.ok) throw new Error(`HTTP Error: ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error("❌ Worker Connection Error:", error);
            return { status: "error", message: error.message };
        }
    }

    /**
     * Payload for Static Storyboard Images (One per beat)
     */
    buildStoryboardPayload(data) {
        const seed = Math.floor(Math.random() * 1000000000000);
        
        return {
            "client_id": "studio_storyboard_" + Date.now(),
            "prompt": {
                "3": { 
                    "inputs": { 
                        "seed": seed, "steps": 20, "cfg": 4, 
                        "sampler_name": "uni_pc", "scheduler": "simple", 
                        "denoise": 1, "model": ["107", 0], 
                        "positive": ["6", 0], "negative": ["7", 0], 
                        "latent_image": ["93", 0] 
                    } 
                },
                "6": { "inputs": { "text": data.prompt, "clip": ["38", 0] } },
                "7": { "inputs": { "text": "distorted, blurry, low quality", "clip": ["38", 0] } },
                "37": { "inputs": { "unet_name": "wan2.2_s2v_14B_fp8_scaled.safetensors", "weight_dtype": "fp8_e5m2" } },
                "38": { "inputs": { "clip_name": "google/t5-v1_1-xxl", "type": "wan" } },
                "39": { "inputs": { "vae_name": "wan2.2_vae.safetensors" } },
                "52": { "inputs": { "image": data.assets[0] || "actor_ref.png" } }, // First reference image
                "93": { 
                    "inputs": { 
                        "width": 720, 
                        "height": 480, 
                        "length": 1, // LENGTH 1 = STATIC IMAGE
                        "batch_size": data.shotCount || 1, // Generate one image per beat
                        "vae": ["39", 0],
                        "ref_image": ["52", 0]
                    } 
                },
                "107": { "inputs": { "lora_name": "wan2.2_distill_lora.safetensors", "strength_model": 1, "model": ["37", 0] } },
                "113": { "inputs": { "filename_prefix": "STORYBOARD", "images": ["80", 0] } },
                "80": { "inputs": { "samples": ["3", 0], "vae": ["39", 0] }, "class_type": "VAEDecode" }
            }
        };
    }

    /**
     * Payload for Video Render (77-81 frames)
     */
    buildWanPayload(data) {
        const seed = Math.floor(Math.random() * 1000000000000);
        return {
            "client_id": "studio_video_" + Date.now(),
            "prompt": {
                "3": { "inputs": { "seed": seed, "steps": 25, "cfg": 6, "sampler_name": "uni_pc", "scheduler": "simple", "denoise": 1, "model": ["107", 0], "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["93", 0] } },
                "6": { "inputs": { "text": data.prompt, "clip": ["38", 0] } },
                "7": { "inputs": { "text": "distorted, blurry, low quality", "clip": ["38", 0] } },
                "37": { "inputs": { "unet_name": "wan2.2_s2v_14B_fp8_scaled.safetensors", "weight_dtype": "fp8_e5m2" } },
                "38": { "inputs": { "clip_name": "google/t5-v1_1-xxl", "type": "wan" } },
                "39": { "inputs": { "vae_name": "wan2.2_vae.safetensors" } },
                "58": { "inputs": { "audio": data.audioFileName || "input.wav" } },
                "93": { "inputs": { "width": 720, "height": 480, "length": 81, "batch_size": 1, "vae": ["39", 0], "ref_image": ["52", 0] } },
                "107": { "inputs": { "lora_name": "wan2.2_distill_lora.safetensors", "strength_model": 1, "model": ["37", 0] } }
            }
        };
    }

    async checkJobStatus(promptId) {
        try {
            const response = await fetch(`${this.comfyUrl}/history/${promptId}`);
            const history = await response.json();
            return history[promptId] ? { status: "done", data: history[promptId] } : { status: "processing" };
        } catch (error) {
            return { status: "error", message: error.message };
        }
    }
}