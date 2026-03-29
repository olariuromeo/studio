# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: studio/payload_factory.py
# Description: Unified Factory with IP-Adapter for Face Consistency.
#              Ensures actors and scenery stay the same across the storyboard.

import json
import random
import copy

class WanPayloadFactory:
    def __init__(self, is_preview=True):
        self.workflow = {}
        self.is_preview = is_preview
        self._add_base_loaders()

    def _add_base_loaders(self):
        """Standard loaders for UNET, VAE, CLIP and IP-Adapter."""
        # Core Models
        self.workflow["37"] = {"inputs": {"unet_name": "wan2.2_s2v_14B_fp8_scaled.safetensors", "weight_dtype": "fp8_e5m2"}, "class_type": "UNETLoader"}
        self.workflow["38"] = {"inputs": {"clip_name": "umt5_xxl_fp8_e4m3fn_scaled.safetensors", "type": "wan"}, "class_type": "CLIPLoader"}
        self.workflow["39"] = {"inputs": {"vae_name": "Wan2_1_VAE_bf16.safetensors"}, "class_type": "VAELoader"}
        
        # IP-Adapter Nodes for Face Consistency
        self.workflow["50"] = {
            "inputs": {
                "preset": "PLUS (faceid)", 
                "model": ["107", 0] # Connects after LoRA
            }, 
            "class_type": "IPAdapterUnifiedLoader"
        }
        
        # LoRA Distill (Node 107)
        self.workflow["107"] = {
            "inputs": {
                "lora_name": "lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors",
                "strength_model": 1.0 if self.is_preview else 0.0,
                "model": ["37", 0]
            },
            "class_type": "LoraLoaderModelOnly"
        }
        
        # Quality Primitives
        self.workflow["103"] = {"inputs": {"value": 8 if self.is_preview else 25}, "class_type": "PrimitiveInt"}
        self.workflow["105"] = {"inputs": {"value": 3.5 if self.is_preview else 6.0}, "class_type": "PrimitiveFloat"}

    def build_storyboard_payload(self, prompt, actor_ref_url, shot_count):
        """Generates N consistent static images using IP-Adapter for the actor's face."""
        wf = copy.deepcopy(self.workflow)
        
        # IP-Adapter Apply (Node 51) - This locks the face
        wf["51"] = {
            "inputs": {
                "weight": 0.8, # High weight for strong face consistency
                "noise": 0.3,
                "ipadapter": ["50", 0],
                "image": ["52", 0] # Reference Image of the actor
            },
            "class_type": "IPAdapterApply"
        }

        wf["93"] = {
            "inputs": {
                "width": 720, "height": 480, "length": 1, 
                "batch_size": shot_count, 
                "positive": ["6", 0], "negative": ["7", 0], "vae": ["39", 0],
                "ref_image": ["52", 0]
            },
            "class_type": "WanImageToVideo"
        }
        
        # Re-wire KSampler to use the IP-Adapter model
        wf["3"]["inputs"]["model"] = ["51", 0]
        
        return self._finalize_workflow(wf, prompt, actor_ref_url, "STORYBOARD")

    def build_video_payload(self, clip_params, audio_url, style_config):
        """Assembles Video workflow (Wan 2.2) using the actor reference."""
        wf = copy.deepcopy(self.workflow)
        
        wf["58"] = {"inputs": {"audio": audio_url}, "class_type": "LoadAudio"}
        wf["57"] = {"inputs": {"audio_encoder_name": "wav2vec2_large_english_fp16.safetensors"}, "class_type": "AudioEncoderLoader"}
        wf["56"] = {"inputs": {"audio_encoder": ["57", 0], "audio": ["58", 0]}, "class_type": "AudioEncoderEncode"}

        wf["93"] = {
            "inputs": {
                "width": 720, "height": 480, "length": 81, "batch_size": 1,
                "positive": ["6", 0], "negative": ["7", 0], "vae": ["39", 0],
                "audio_encoder_output": ["56", 0], "ref_image": ["52", 0]
            },
            "class_type": "WanSoundImageToVideo"
        }
        
        prompt = f"[Actor Reference Applied] [Style]: {style_config['positive']}\n\n[Action]: {clip_params['name']}"
        return self._finalize_workflow(wf, prompt, clip_params["media_url"], "VIDEO")

    def _finalize_workflow(self, wf, prompt, ref_img, prefix):
        """Injects prompt, seed, and output nodes."""
        seed = random.randint(1000, 99999)
        
        wf["6"] = {"inputs": {"text": prompt, "clip": ["38", 0]}, "class_type": "CLIPTextEncode"}
        wf["7"] = {"inputs": {"text": "distorted, blurry, low quality, deformed face", "clip": ["38", 0]}, "class_type": "CLIPTextEncode"}
        wf["52"] = {"inputs": {"image": ref_img}, "class_type": "LoadImage"}
        
        if "3" not in wf: # Ensure KSampler exists
            wf["3"] = {
                "inputs": {
                    "seed": seed, "steps": ["103", 0], "cfg": ["105", 0],
                    "sampler_name": "uni_pc", "scheduler": "simple", "denoise": 1,
                    "model": ["107", 0], "positive": ["93", 0], "negative": ["93", 1], "latent_image": ["93", 2]
                },
                "class_type": "KSampler"
            }
        else:
             wf["3"]["inputs"]["seed"] = seed

        wf["80"] = {"inputs": {"samples": ["3", 0], "vae": ["39", 0]}, "class_type": "VAEDecode"}
        wf["113"] = {"inputs": {"filename_prefix": f"studio_{prefix}_{seed}", "images": ["80", 0]}, "class_type": "SaveImage"}
        
        return wf