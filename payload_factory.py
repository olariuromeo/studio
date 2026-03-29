# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: coozila/video/studio/payload_factory.py
# Description: Dynamic Workflow Factory. Programmatically assembles ComfyUI nodes
#              for Wan 2.2 based on required video length and extensions.

import json
import random

class WanWorkflowFactory:
    def __init__(self, is_preview=True):
        self.workflow = {}
        self.is_preview = is_preview
        self.last_latent_id = None
        self.last_node_id = 0
        
        # Inițializăm constantele de bază
        self._add_static_loaders()

    def _next_id(self):
        self.last_node_id += 1
        return str(self.last_node_id)

    def _add_static_loaders(self):
        """Configurează motoarele de bază care nu se schimbă (UNET, VAE, CLIP)."""
        # Loaders principale
        self.workflow["37"] = {"inputs": {"unet_name": "wan2.2_s2v_14B_fp8_scaled.safetensors", "weight_dtype": "fp8_e5m2"}, "class_type": "UNETLoader"}
        self.workflow["38"] = {"inputs": {"clip_name": "umt5_xxl_fp8_e4m3fn_scaled.safetensors", "type": "wan"}, "class_type": "CLIPLoader"}
        self.workflow["39"] = {"inputs": {"vae_name": "Wan2_1_VAE_bf16.safetensors"}, "class_type": "VAELoader"}
        self.workflow["57"] = {"inputs": {"audio_encoder_name": "wav2vec2_large_english_fp16.safetensors"}, "class_type": "AudioEncoderLoader"}
        
        # Nodul 107: LoRA Distill
        self.workflow["107"] = {
            "inputs": {
                "lora_name": "lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors",
                "strength_model": 1.0 if self.is_preview else 0.0,
                "model": ["37", 0]
            },
            "class_type": "LoraLoaderModelOnly"
        }
        
        # Sampler Settings (Primitives)
        self.workflow["54"] = {"inputs": {"shift": 8, "model": ["107", 0]}, "class_type": "ModelSamplingSD3"}
        self.workflow["103"] = {"inputs": {"value": 8 if self.is_preview else 25}, "class_type": "PrimitiveInt"}
        self.workflow["105"] = {"inputs": {"value": 3.5 if self.is_preview else 6.0}, "class_type": "PrimitiveFloat"}
        self.workflow["104"] = {"inputs": {"value": 77}, "class_type": "PrimitiveInt"} # Chunk Length

    def build_from_timeline(self, clip_params, audio_url, style_config):
        """Asamblează întreg workflow-ul bazat pe datele din Orchestrator."""
        
        # 1. Prompts & Media Inputs
        self.workflow["6"] = {"inputs": {"text": f"[Style Tags]: {style_config['positive']}\n\n[Action]: {clip_params['name']}", "clip": ["38", 0]}, "class_type": "CLIPTextEncode"}
        self.workflow["7"] = {"inputs": {"text": style_config['negative'], "clip": ["38", 0]}, "class_type": "CLIPTextEncode"}
        self.workflow["52"] = {"inputs": {"image": clip_params["media_url"]}, "class_type": "LoadImage"}
        self.workflow["58"] = {"inputs": {"audio": audio_url}, "class_type": "LoadAudio"}
        self.workflow["56"] = {"inputs": {"audio_encoder": ["57", 0], "audio": ["58", 0]}, "class_type": "AudioEncoderEncode"}

        # 2. Primul segment (I2V Base)
        self.workflow["93"] = {
            "inputs": {
                "width": 720, "height": 368, "length": ["104", 0], "batch_size": 1,
                "positive": ["6", 0], "negative": ["7", 0], "vae": ["39", 0],
                "audio_encoder_output": ["56", 0], "ref_image": ["52", 0]
            },
            "class_type": "WanSoundImageToVideo"
        }
        
        self.workflow["3"] = {
            "inputs": {
                "seed": random.randint(1000, 99999), "steps": ["103", 0], "cfg": ["105", 0],
                "sampler_name": "uni_pc", "scheduler": "simple", "denoise": 1,
                "model": ["54", 0], "positive": ["93", 0], "negative": ["93", 1], "latent_image": ["93", 2]
            },
            "class_type": "KSampler"
        }
        self.last_latent_id = "3"

        # 3. Adăugare Extensii DINAMIC (Dacă avem nevoie de mai mult de 77 cadre)
        num_extensions = (clip_params["frames"] // 77)
        for i in range(num_extensions):
            self._add_extension_layer(i)

        # 4. Nodurile de finalizare
        self._add_output_nodes()
        
        return self.workflow

    def _add_extension_layer(self, index):
        """Creează un nou strat de Extend + KSampler + Concat."""
        ext_id = f"ext_{index}"
        samp_id = f"samp_{index}"
        concat_id = f"concat_{index}"

        # SoundImageToVideoExtend
        self.workflow[ext_id] = {
            "inputs": {
                "length": ["104", 0], "positive": ["6", 0], "negative": ["7", 0],
                "vae": ["39", 0], "video_latent": [self.last_latent_id, 0],
                "audio_encoder_output": ["56", 0], "ref_image": ["52", 0]
            },
            "class_type": "WanSoundImageToVideoExtend"
        }

        # KSampler pentru extensie
        self.workflow[samp_id] = {
            "inputs": {
                "seed": random.randint(1000, 99999), "steps": ["103", 0], "cfg": ["105", 0],
                "sampler_name": "uni_pc", "scheduler": "simple", "denoise": 1,
                "model": ["54", 0], "positive": [ext_id, 0], "negative": [ext_id, 1], "latent_image": [ext_id, 2]
            },
            "class_type": "KSampler"
        }

        # Concatenează noul rezultat la cel anterior
        self.workflow[concat_id] = {
            "inputs": {"dim": "t", "samples1": [self.last_latent_id, 0], "samples2": [samp_id, 0]},
            "class_type": "LatentConcat"
        }
        
        self.last_latent_id = concat_id

    def _add_output_nodes(self):
        """Adaugă decodarea VAE și salvarea video."""
        self.workflow["80"] = {"inputs": {"samples": [self.last_latent_id, 0], "vae": ["39", 0]}, "class_type": "VAEDecode"}
        self.workflow["82"] = {"inputs": {"fps": 16, "images": ["80", 0], "audio": ["58", 0]}, "class_type": "CreateVideo"}
        self.workflow["113"] = {
            "inputs": {"filename_prefix": "studio_render", "video": ["82", 0]},
            "class_type": "SaveVideo"
        }