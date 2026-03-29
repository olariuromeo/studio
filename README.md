# 🎬 Coozila! Video Studio
### **The Ultimate AI Music Video Orchestrator with Visual Canvas**

Coozila! Studio nu este doar un backend, ci un mediu de editare hibrid integrat direct în ComfyUI. Prin apăsarea butonului dedicat din chat, deschizi un **Canvas interactiv** care îți permite să gestionezi vizual proiectul video.

---

## 📂 Documentația Fișierelor

### 🖥️ I. Interfață și UI (Web/JS)
Aceste fișiere "injectează" butonul în ComfyUI și deschid fereastra de Studio.

* **`studio_tab.js` (Interfața Studio)**
    * **Ce face:** Creează butonul "Coozila Studio" în chat-ul ComfyUI. La apăsare, deschide un **Canvas (fereastră modală)** care desenează vizual clipurile din timeline, formele de undă audio și previzualizările de stil.
* **`canvas_renderer.js` (Motorul de Vizualizare)**
    * **Ce face:** Transformă codul JSON din `master_schema.json` în elemente grafice. Îți permite să tragi de marginea clipurilor (trim) sau să schimbi ordinea scenelor direct pe ecran.

---

### 🧠 II. Componente de Logică (Python - Backend)
Acestea procesează cererile venite din Studio Canvas.

* **`orchestrator.py` (Comandantul Central)**
    * **Ce face:** Primește comenzile de la Canvas (ex: "aplică stilul Nolan"). Clonează template-urile, apelează restul modulelor și pregătește proiectul pentru randare.
* **`audio_sync.py` (Metronomul Ritmului)**
    * **Ce face:** Analizează BPM-ul și trimite către Canvas punctele exacte unde trebuie să apară "tăieturile" vizuale pe timeline.
* **`payload_builder.py` (Fabrica de Instrucțiuni)**
    * **Ce face:** Când apeși "Render" în Canvas, acest fișier scrie rețeta finală pentru Wan 2.2, gestionând setările de LoRA (Preview) sau randare finală.
* **`style_engine.py` și `style_analyzer.py` (Design & Vision)**
    * **Ce face:** Primul construiește prompturile, al doilea analizează imaginile urcate de tine în Canvas pentru a "fura" stilul vizual.
* **`comfy_client.py` și `media_processor.py` (Producție & FFmpeg)**
    * **Ce face:** Trimite jobul la ComfyUI și, la final, lipește toate bucățile randate într-un MP4 sincronizat.

---

### 💾 III. Librării de Date (JSON - Template-uri)
Sursa de informații pentru Canvas și Orchestrator.

* **`master_schema.json`**: Structura tehnică a Timeline-ului (standardul FCPXML).
* **`styles.json`**: Catalogul de preseturi vizuale care apar în meniul drop-down din Studio.
* **`shot_presets.json`**: Colecția de mișcări de cameră (Push, Orbit) pe care le poți alege pentru fiecare scenă.

---

### ⚙️ IV. Infrastructură și Setup

* **`memory_manager.py`**: Salvează automat starea Canvas-ului, astfel încât, dacă închizi fereastra, proiectul tău rămâne intact.
* **`setup_studio.py`**: Configurează folderele și instalează toate resursele necesare la prima rulare.
* **`requirements.txt`**: Conține librăriile Python necesare pentru analiza audio și procesarea video.

---

## 🚀 Cum funcționează noul flux vizual:

1.  **Activare:** Apese butonul din Chat. Se deschide **Studio Canvas**.
2.  **Import:** Urcă muzica. `audio_sync` desenează imediat waveform-ul pe Canvas.
3.  **Regie:** Alegi un Preset (ex: "Epic Romance"). Canvas-ul se populează cu 3-4 clipuri tăiate fix pe beat.
4.  **Preview:** Apese butonul "Preview" din Canvas. Se trimite un job rapid la ComfyUI folosind **Distill LoRA**.
5.  **Finalizare:** Dacă arată bine, apeși "Master Render" și obții fișierul 8K final.
