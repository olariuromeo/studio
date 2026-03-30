import os

def patch_file(file_path, search_str, insert_str, mode='after'):
    if not os.path.exists(file_path):
        print(f"⚠️  File not found: {file_path}")
        return

    with open(file_path, "r") as f:
        content = f.read()

    if insert_str in content:
        print(f"✅ Patch already applied to {os.path.basename(file_path)}")
        return

    if mode == 'after':
        new_content = content.replace(search_str, search_str + "\n" + insert_str)
    else: # prepend or specific logic
        new_content = insert_str + "\n" + content

    with open(file_path, "w") as f:
        f.write(new_content)
    print(f"🚀 Patched {os.path.basename(file_path)} successfully.")

if __name__ == "__main__":
    # --- PATCH 1: MAIN API ROUTER ---
    patch_file(
        "/app/backend/open_webui/main.py",
        "app = FastAPI(",
        "from open_webui.studio.api import router as studio_router"
    )
    patch_file(
        "/app/backend/open_webui/main.py",
        "app.include_router(chat_router", 
        "app.include_router(studio_router, prefix='/api/v1/studio', tags=['studio'])"
    )

    # --- PATCH 2: CONTROLS UI (Dacă nu folosim volume mount pe build direct) ---
    # Notă: Dacă facem mount pe /app/build, Svelte-ul e deja "pre-patched" de noi local.