# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/video/style_engine.py
# Description: The "Creative Director" logic. Interprets AI-generated tags and 
#              user intent to build a standardized style package for Wan 2.2.
#              Ensures consistent visual identity across the entire project.

import logging
from coozila.video.styles import STYLE_PRESETS

logger = logging.getLogger(__name__)

class StyleEngine:
    """
    The engine that assembles the project's visual 'DNA'.
    The AI Assistant uses this logic to prepare the final prompt layers 
    that the Wan 2.2 model will execute.
    """

    @staticmethod
    def construct_style_package(selected_style_id: str = None, 
                                custom_user_input: str = None, 
                                ai_analyzed_tags: str = None) -> dict:
        """
        Assembles the final style based on multiple input layers.
        
        Args:
            selected_style_id (str): ID from the global presets (styles.py).
            custom_user_input (str): Direct text input from the user chat.
            ai_analyzed_tags (str): Output from vision analyzer (image analysis).
            
        Returns:
            dict: The standardized style package for the video pipeline.
        """
        final_positive = []
        # Base negative tags to ensure stability in Wan 2.2
        final_negative = [
            "morphing", "distortion", "extra limbs", "bad anatomy", 
            "text", "watermark", "glitch", "low quality", "blurry"
        ]

        # 1. Preset Layer (If a predefined template is selected)
        if selected_style_id and selected_style_id in STYLE_PRESETS:
            preset = STYLE_PRESETS[selected_style_id]
            final_positive.append(preset["tags"])
            if "negative_tags" in preset:
                final_negative.append(preset["negative_tags"])
            logger.info(f"🎨 [STYLE ENGINE] Layer 1: Applied Preset '{selected_style_id}'")

        # 2. AI Vision Layer (Automatically extracted tags from reference images)
        if ai_analyzed_tags:
            final_positive.append(ai_analyzed_tags)
            logger.info("🎨 [STYLE ENGINE] Layer 2: Injected AI Vision Tags")

        # 3. User Intent Layer (Specific requests written in chat)
        if custom_user_input:
            final_positive.append(custom_user_input)
            logger.info("🎨 [STYLE ENGINE] Layer 3: Appended User Custom Intent")

        # 4. Standardization: Cleaning and joining everything for Wan 2.2
        positive_prompt = ", ".join([p.strip() for p in final_positive if p])
        negative_prompt = ", ".join([n.strip() for n in final_negative if n])

        return {
            "style_id": selected_style_id or "custom_assistant_build",
            "positive_tags": positive_prompt,
            "negative_tags": negative_prompt,
            "engine_signature": "Coozila-Studio-v4.1"
        }

    @staticmethod
    def get_exportable_style(style_package: dict, custom_name: str = "My Personalized Style") -> dict:
        """
        Prepares the style for export into the user's personalized database.
        """
        return {
            "name": custom_name,
            "tags": style_package.get("positive_tags", ""),
            "negative_tags": style_package.get("negative_tags", ""),
            "metadata": {
                "engine_version": "Wan 2.2 Compatible",
                "is_custom": True,
                "signature": style_package.get("engine_signature")
            }
        }