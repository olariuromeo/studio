# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: coozila/video/styles.py
# Description: Global Style Library. Contains standardized visual presets 
#              used by the AI Assistant to guide Wan 2.2 generation.

STYLE_PRESETS = {
    "nolan_inspired": {
        "name": "Nolan Inspired",
        "tags": "Christopher Nolan style, IMAX 70mm, high contrast, practical effects look, cold blue and steel tones, cinematic realism, widescreen, realistic photography.",
        "negative_tags": "cartoon, saturated, flat lighting, amateur, drawing, anime"
    },
    "dark_gothic": {
        "name": "Dark Gothic Cinematic",
        "tags": "Guillermo del Toro style, dark fantasy, moody chiaroscuro, amber candlelight, deep shadows, ornate textures, gothic atmosphere, high fantasy epic.",
        "negative_tags": "bright, sunny, modern, minimalist, cheerful, neon"
    },
    "euphoria_neon": {
        "name": "Euphoria Style",
        "tags": "Euphoria style inspired, neon aesthetic, moody purple and blue lighting, glitter textures, hazy atmosphere, shallow depth of field, experimental cinematography.",
        "negative_tags": "natural light, vintage, black and white, earthy, realistic sunlight"
    },
    "makoto_shinkai": {
        "name": "Makoto Shinkai Inspired",
        "tags": "Makoto Shinkai Inspired, Anime Style, Digital Painting, Kimi no Na wa style, high saturation, lens flares, detailed sky, vibrant clouds, Visual Novel Style, scenery focused.",
        "negative_tags": "realistic, photograph, 3d render, grainy, dark, moody, horror"
    },
    "dreamcore": {
        "name": "Dreamcore / VHS",
        "tags": "Dreamcore style, lo-fi/VHS aesthetic, 90s nostalgia, liminal space aesthetic, hazy lighting, surreal composition, weirdcore photography, low resolution feel.",
        "negative_tags": "4k, 8k, high fidelity, sharp, modern, clear, realistic photography"
    },
    "generative_aesthetics": {
        "name": "Generative Aesthetics",
        "tags": "Generative Aesthetics, cinematic photography, digital overlay, HUD elements, glitch art, tech noir, experimental film, data visualization overlays.",
        "negative_tags": "vintage, organic, simple, natural, historical, rustic"
    },
    "love_actually": {
        "name": "Love Actually Inspired",
        "tags": "Love Actually style, commercial photography, narrative MV, early 2000s cinema, rom-com aesthetic, high key lighting, 35mm film, warm and cozy tones.",
        "negative_tags": "dark, moody, horror, gothic, neon, cold tones, sci-fi"
    },
    "gizem_akdag": {
        "name": "Gizem Akdag Inspired",
        "tags": "Gizem Akdag style, surrealist photography, liminal space aesthetic, polarized lens effect, harsh lighting, minimalist composition, eerie stillness.",
        "negative_tags": "cluttered, soft lighting, cozy, traditional, realistic textures, busy"
    },
    "corpse_bride": {
        "name": "Corpse Bride Inspired",
        "tags": "Corpse Bride Inspired, Tim Burton style, stop motion aesthetic, claymation, gothic fantasy, dark whimsy, 3D render, spindly character designs, muted colors.",
        "negative_tags": "realistic, bright, high-key, anime, flat, high saturation"
    }
}

def get_style(style_id: str) -> dict:
    """
    Retrieves a specific style preset by its ID. 
    Defaults to 'nolan_inspired' if the ID is not found.
    """
    return STYLE_PRESETS.get(style_id, STYLE_PRESETS["nolan_inspired"])