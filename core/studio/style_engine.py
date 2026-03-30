# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#

# Location: coozila/video/studio/style_engine.py
# Description: The "Creative Director" logic. Interprets AI-generated tags and 
#              user intent to build a standardized style package for Wan 2.2.
#              Ensures consistent visual identity across the entire project.

from open_webui.coozila.video.studio.styles import STYLE_PRESETS

class StyleEngine:
    """
    Engine-ul care asamblează 'ADN-ul' vizual al proiectului.
    Asistentul (AI-ul) folosește această logică pentru a pregăti inputul 
    pe care Wan 2.2 îl va executa orbește.
    """

    @staticmethod
    def construct_style_package(selected_style_id=None, custom_user_input=None, ai_analyzed_tags=None):
        """
        Asamblează stilul final bazat pe straturile de input.
        
        Args:
            selected_style_id (str): ID-ul dintr-un preset (styles.py).
            custom_user_input (str): Textul liber introdus de user în chat.
            ai_analyzed_tags (str): Rezultatul din style_analyzer.py (analiza imaginii).
            
        Returns:
            dict: Pachetul de stil standardizat.
        """
        final_positive = []
        final_negative = ["morphing", "distortion", "extra limbs", "bad anatomy", "text", "watermark"]

        # 1. Stratul de Preset (Dacă există un șablon selectat)
        if selected_style_id in STYLE_PRESETS:
            preset = STYLE_PRESETS[selected_style_id]
            final_positive.append(preset["tags"])
            if "negative_tags" in preset:
                final_negative.append(preset["negative_tags"])

        # 2. Stratul de AI Analysis (Tags extrase automat din poze de referință)
        if ai_analyzed_tags:
            final_positive.append(ai_analyzed_tags)

        # 3. Stratul de User Custom Input (Cerințele scrise direct în fereastra de chat)
        if custom_user_input:
            # Asistentul adaugă cerința userului ca un modificator final
            final_positive.append(custom_user_input)

        # 4. Standardizarea: Curățăm și unim totul într-un format digerabil pentru Wan
        positive_prompt = ", ".join([p.strip() for p in final_positive if p])
        negative_prompt = ", ".join([n.strip() for n in final_negative if n])

        return {
            "style_id": selected_style_id or "custom_assistant_build",
            "positive_tags": positive_prompt,
            "negative_tags": negative_prompt,
            "version": "1.0-Coozila-Studio"
        }

    @staticmethod
    def get_exportable_style(style_package, custom_name="My Personalized Style"):
        """
        Pregătește stilul pentru a fi exportat în baza de date personalizată a userului.
        """
        return {
            "name": custom_name,
            "tags": style_package["positive_tags"],
            "negative_tags": style_package["negative_tags"],
            "metadata": {
                "engine_version": "Wan 2.2 Compatible",
                "custom": True
            }
        }