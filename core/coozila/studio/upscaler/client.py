import httpx

async def trigger_upscale(path: str):
    # Această funcție știe singură unde e serverul și cum să vorbească cu el
    async with httpx.AsyncClient() as client:
        r = await client.post("http://upscaler-node:8189/upscale", json={"path": path})
        return r.json()