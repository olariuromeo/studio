# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Location: studio/apply_patches.py
# Description: Studio Automated Patcher. Injects Studio API routes and UI 
#              components into the Open WebUI source before the Svelte build.
# ----------------------------------------------------------------------------------#

import os
import sys

def studio_log(msg):
    print(f"--- [COOZILA STUDIO PATCHER] {msg} ---")

def apply_patch(file_path, search_str, insert_str):
    if not os.path.exists(file_path):
        studio_log(f"⚠️  MISSING FILE: {file_path}")
        return

    with open(file_path, "r") as f:
        content = f.read()

    if insert_str in content:
        studio_log(f"✅ ALREADY PATCHED: {os.path.basename(file_path)}")
        return

    # Realizăm injecția codului Studio
    new_content = content.replace(search_str, f"{search_str}\n{insert_str}")
    
    with open(file_path, "w") as f:
        f.write(new_content)
    studio_log(f"🚀 INJECTED SUCCESSFULLY: {os.path.basename(file_path)}")

if __name__ == "__main__":
    studio_log("Starting Studio Source Injection...")

    # --- 1. BACKEND PATCH (main.py) ---
    # Injectăm rutele API pentru a activa comunicarea cu Orchestratorul
    apply_patch(
        "backend/open_webui/main.py",
        "app = FastAPI(",
        "from open_webui.studio.api import router as studio_router"
    )
    apply_patch(
        "backend/open_webui/main.py",
        "app.include_router(chat_router,",
        "app.include_router(studio_router, prefix='/api/v1/studio', tags=['studio'])"
    )

    # --- 2. FRONTEND PATCH (Controls.svelte) ---
    # Inserăm componenta Canvas în interfața originală
    apply_patch(
        "src/lib/components/chat/Controls/Controls.svelte",
        "import { user, settings } from '$lib/stores';",
        "import StudioCanvas from '$lib/studio/StudioCanvas.svelte';"
    )

    studio_log("All source patches applied. Ready for 'npm run build'.")