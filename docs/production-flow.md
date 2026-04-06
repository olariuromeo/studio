# 🎬 Coozila! Studio: The Cinematic Pipeline (v4.2)

Producția nu începe cu randarea, ci cu **Arhitectura Narativă**. Sistemul Coozila transformă o piesă audio într-un scenariu tehnic divizat pe capitole, scene și clipuri, toate aliniate pe un timeline OTIO.



## 1. Context Ingestion & Character Casting
Înainte de orice beat, AI-ul analizează intrările utilizatorului pentru a construi „Biblia Producției”.
* **Character Profiling:** Fiecare imagine încărcată este scanată. AI-ul generează o descriere textuală densă (ex: *"Elara: coif de bronz corintic, ochi verzi, cicatrice pe obrazul stâng"*). Această descriere devine **Anchor Prompt** pentru consistență.
* **Audio Description:** Piesa audio este segmentată emoțional (ex: *00:00-00:30 - Tensiune joasă, recitativ; 00:30-01:00 - Techno drop, bătălie*).

## 2. The Scripting Dialogue (The Consensus Phase)
AI-ul nu presupune, ci **colaborează**. Începe un dialog tehnic până la stabilirea scenariului final:
* **Prompt Relay System:** Utilizatorul și AI-ul editează iterativ un tabel de tip Timeline.
* **Structura Ierarhică:** * **Chapter:** Tema generală (ex: *Canto I - Mânia lui Ahile*).
    * **Scene:** Locația și atmosfera (ex: *Tabăra Aheenilor, Noapte, Foc de tabără*).
    * **Clip:** Unitatea de randare (ex: *Clip 1: Close-up Ahile strângând pumnul, 3 secunde*).
* **User/AI Consensus:** Datele pot fi modificate manual în Canvas sau prin comenzi chat. Doar când statusul este `READY`, se deblochează randarea.

## 3. Prompt Relay & Motion Control
Fiecare clip de pe timeline are propriul set de instrucțiuni dinamice care controlează motorul Wan 2.2:
* **Visual Prompt:** Descrierea acțiunii (bazată pe "Biblia Personajelor").
* **Motion Prompt:** Instrucțiuni de cameră (ex: *Dolly Zoom, Pan Right, Static Shot*).
* **Seed Management:** Păstrarea seed-ului între clipuri din aceeași scenă pentru a evita "flicker-ul" de personaj.

## 4. Resolution & 64-bit Alignment Matrix
Toate randările respectă strictețea matematică pentru eficiența GPU (RTX 3080).

| Profile | Resolution (W x H) | Ratio | Role |
| :--- | :--- | :--- | :--- |
| **PREVIEW** | **896 x 512** | 1.75 | Validare Scenariu & Mișcare |
| **FULL HD** | **1920 x 1088** | 1.76 | Master Broadcast |
| **MASTER 4K**| **4096 x 2304** | 1.77 | Cinematic DCI 4K |

## 5. The Multi-Phase Rendering Pipeline

### Phase A: The Storyboard Sketch (Instant)
* Generarea de cadre statice (thumbnails) pentru fiecare clip de pe timeline pentru a vizualiza compoziția înainte de a consuma VRAM pe video.

### Phase B: Motion Preview (The Sketch)
* Randare la 16 FPS, rezoluție PREVIEW, cu Distill LoRA ($8 \dots 10$ steps).
* **Scop:** Verificarea sincronizării cu beat-ul audio.

### Phase C: Master Generation & Finishing
1.  **High-Fi Render:** Randare la 30-40 steps, fără LoRA.
2.  **Temporal Interpolation (RIFE):** Scalare FPS de la 16 la 64 FPS ("Buttery Smooth").
3.  **Spatial Upscale (Tiled):** Trecerea de la 896px la 4K/8K prin asamblare "brick-by-brick" (64-pixel aligned tiles).

---

## 6. Final Mastering & Export
* **FFmpeg Integration:** Mixajul final între clipurile video procesate și track-ul audio original.
* **OTIO Metadata:** Exportul unui fișier `.otio` care permite deschiderea întregului proiect în DaVinci Resolve sau Premiere Pro pentru ajustări fine de montaj.

---