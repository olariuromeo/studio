# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: core/coozila/studio/payload_factory.py
# Description: Professional Hybrid Factory for FLUX.1 (Storyboard) & Wan 2.2 (Video)
# ----------------------------------------------------------------------------------#

import json
import random
import os

class CoozilaPayloadFactory:
    def __init__(self, is_preview=True):
        self.is_preview = is_preview
        # Preluăm mediul pentru a ruta corect fișierele de input/output
        self.data_dir = os.getenv("DATA_DIR", "data")

    def _get_seed(self):
        return random.randint(1000, 999999999999999)

    def build_storyboard_payload(self, prompt, actor_ref_path, shot_count):
        """Generates high-fidelity images using FLUX.1 + IP-Adapter for FaceID."""
        wf = {}
        seed = self._get_seed()

        # 1. LOADERS: FLUX Engine
        wf["37"] = {
            "inputs": {"unet_name": "flux1-krea-dev_fp8_scaled.safetensors", "weight_dtype": "fp8_e4m3fn"},
            "class_type": "UNETLoader"
        }
        wf["38"] = {
            "inputs": {"clip_name1": "t5xxl_fp8_e4m3fn.safetensors", "clip_name2": "clip_l.safetensors", "type": "flux"},
            "class_type": "DualCLIPLoader"
        }
        wf["39"] = {"inputs": {"vae_name": "ae.safetensors"}, "class_type": "VAELoader"}

        # 2. FACE CONSISTENCY: IP-Adapter FLUX
        wf["50"] = {
            "inputs": {"preset": "FLUX - FaceID", "model": ["37", 0]},
            "class_type": "IPAdapterUnifiedLoader"
        }
        wf["51"] = {
            "inputs": {
                "weight": 0.85, 
                "ipadapter": ["50", 0], 
                "image": ["52", 0]
            },
            "class_type": "IPAdapterApply"
        }

        # 3. INPUTS & LATENT
        wf["6"] = {"inputs": {"text": f"(Cinematic, photorealistic:1.2), {prompt}", "clip": ["38", 0]}, "class_type": "CLIPTextEncode"}
        # actor_ref_path trebuie să fie relativ la folderul 'input' al ComfyUI sau cale absolută
        wf["52"] = {"inputs": {"image": actor_ref_path}, "class_type": "LoadImage"}
        
        wf["93"] = {
            "inputs": {"width": 896, "height": 512, "batch_size": shot_count}, # Rezoluție optimă FLUX
            "class_type": "EmptyLatentImage"
        }

        # 4. SAMPLING
        wf["3"] = {
            "inputs": {
                "seed": seed, "steps": 20, "sampler_name": "euler", "scheduler": "simple",
                "denoise": 1.0, "model": ["51", 0], "positive": ["6", 0], 
                "negative": ["6", 0], "latent_image": ["93", 0]
            },
            "class_type": "KSampler"
        }

        # 5. DECODE & SAVE
        wf["80"] = {"inputs": {"samples": ["3", 0], "vae": ["39", 0]}, "class_type": "VAEDecode"}
        wf["113"] = {"inputs": {"filename_prefix": "STORYBOARD_FLUX", "images": ["80", 0]}, "class_type": "SaveImage"}

        return wf

    def build_video_payload(self, clip_params, audio_path, style_config):
        """Animates storyboard stills using Wan 2.2 with Audio Sync."""
        wf = {}
        seed = self._get_seed()

        # 1. LOADERS: Wan 2.2 (14B) Engine
        wf["37"] = {
            "inputs": {"unet_name": "wan2.2_s2v_14B_fp8_scaled.safetensors", "weight_dtype": "fp8_e5m2"}, 
            "class_type": "UNETLoader"
        }
        wf["38"] = {
            "inputs": {"clip_name": "umt5_xxl_fp8_e4m3fn_scaled.safetensors", "type": "wan"}, 
            "class_type": "CLIPLoader"
        }
        wf["39"] = {"inputs": {"vae_name": "Wan2_1_VAE_bf16.safetensors"}, "class_type": "VAELoader"}

        # 2. AUDIO ANALYSIS (Wan-Specific Audio Sync)
        wf["58"] = {"inputs": {"audio": audio_path}, "class_type": "LoadAudio"}
        wf["57"] = {
            "inputs": {"audio_encoder_name": "wav2vec2_large_english_fp16.safetensors"}, 
            "class_type": "AudioEncoderLoader"
        }
        wf["56"] = {
            "inputs": {"audio_encoder": ["57", 0], "audio": ["58", 0]}, 
            "class_type": "AudioEncoderEncode"
        }

        # 3. PROMPTING & I2V CONDITIONING
        wf["6"] = {"inputs": {"text": style_config.get('positive', ''), "clip": ["38", 0]}, "class_type": "CLIPTextEncode"}
        wf["7"] = {"inputs": {"text": "static, boring, low resolution, noisy", "clip": ["38", 0]}, "class_type": "CLIPTextEncode"}
        wf["52"] = {"inputs": {"image": clip_params["media_url"]}, "class_type": "LoadImage"}

        # 4. WAN I2V CORE (Wan 2.2 Wrapper Logic)
        wf["93"] = {
            "inputs": {
                "width": 720, "height": 480, "length": 81, # 81 frames (~3 sec @ 24fps)
                "positive": ["6", 0], "negative": ["7", 0], "vae": ["39", 0],
                "audio_encoder_output": ["56", 0], "ref_image": ["52", 0]
            },
            "class_type": "WanSoundImageToVideo"
        }

        # 5. SAMPLING (Uni_PC is recommended for Wan 2.2)
        wf["3"] = {
            "inputs": {
                "seed": seed, "steps": 30, "cfg": 5.5, "sampler_name": "uni_pc", "scheduler": "simple",
                "denoise": 1.0, "model": ["37", 0], 
                "positive": ["93", 0], "negative": ["93", 1], "latent_image": ["93", 2]
            },
            "class_type": "KSampler"
        }

        # 6. VIDEO DECODE & OUTPUT
        wf["80"] = {"inputs": {"samples": ["3", 0], "vae": ["39", 0]}, "class_type": "VAEDecode"}
        wf["113"] = {"inputs": {"filename_prefix": "VIDEO_WAN_SYNC", "images": ["80", 0]}, "class_type": "SaveImage"}

        return wf