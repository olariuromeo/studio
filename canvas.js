// ----------------------------------------------------------------------------------#
//                                                                                   #
//   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
//   Coozila! Team    lab@coozila.com                                                #
//                                                                                   #
// ----------------------------------------------------------------------------------#

/**
 * Location: studio/canvas.js
 * Description: Hybrid Storyboard (FLUX.1) & Video Orchestrator (Wan 2.2).
 * Optimized for RTX 3080 / CUDA 12.5.
 */

import { AudioEngine } from './audio_engine.js';
import { StudioOrchestrator } from './orchestrator.js';

class CoozilaStudio {
    constructor() {
        this.audioData = null;
        this.actorRef = null; // Principal Actor for FaceID
        this.sceneryRefs = []; // Style/Environment references
        this.orchestrator = new StudioOrchestrator();

        this.initStyles();
        this.createDOM();
    }

    initStyles() {
        if (document.getElementById('coozila-studio-css')) return;
        const style = document.createElement('style');
        style.id = 'coozila-studio-css';
        style.textContent = `
            #studio-canvas-overlay {
                position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
                background: radial-gradient(circle at center, #0a0a0a 0%, #050505 100%);
                backdrop-filter: blur(30px); z-index: 100000; display: none; 
                flex-direction: column; color: #f0f0f0; font-family: 'Inter', sans-serif;
            }
            .studio-header { padding: 15px 40px; background: rgba(0,0,0,0.9); border-bottom: 1px solid #7e22ce44; display: flex; justify-content: space-between; align-items: center; }
            .studio-main { display: flex; flex: 1; padding: 25px; gap: 25px; overflow: hidden; }
            
            /* Storyboard Grid */
            .storyboard-container {
                flex: 3; background: #000; border: 1px solid #1a1a1a; 
                border-radius: 16px; display: flex; flex-direction: column; overflow: hidden;
                box-shadow: 0 0 40px rgba(0,0,0,0.5);
            }
            .storyboard-grid {
                flex: 1; display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
                gap: 20px; padding: 25px; overflow-y: auto;
            }
            .story-card {
                background: #080808; border: 1px solid #1a1a1a; border-radius: 12px; 
                aspect-ratio: 16/9; position: relative; overflow: hidden; transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
            }
            .story-card:hover { border-color: #a855f7; transform: translateY(-5px); box-shadow: 0 10px 20px rgba(126, 34, 206, 0.2); }
            .story-card img { width: 100%; height: 100%; object-fit: cover; }
            .story-card.empty { border: 1px dashed #222; display: flex; align-items: center; justify-content: center; color: #333; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; }

            /* Sidebar Controls */
            .sidebar { flex: 1; min-width: 320px; background: #080808; border: 1px solid #1a1a1a; border-radius: 16px; padding: 20px; display: flex; flex-direction: column; gap: 20px; }
            .drop-zone { border: 2px dashed #1a1a1a; border-radius: 12px; padding: 20px; text-align: center; cursor: pointer; transition: 0.3s; background: #050505; }
            .drop-zone:hover { border-color: #a855f7; background: #0a0a0a; }
            .drop-label { font-size: 11px; color: #666; font-weight: 600; text-transform: uppercase; margin-bottom: 8px; display: block; }
            
            .asset-preview-main { width: 100%; height: 120px; object-fit: cover; border-radius: 8px; border: 1px solid #222; margin-top: 10px; display: none; }
            .prompt-box { width: 100%; height: 120px; background: #000; border: 1px solid #222; color: #fff; padding: 15px; border-radius: 12px; resize: none; font-size: 13px; line-height: 1.5; }
            .prompt-box:focus { border-color: #a855f7; outline: none; }

            /* Action Buttons */
            .btn-group { display: flex; flex-direction: column; gap: 12px; }
            .btn { padding: 16px; border-radius: 10px; border: none; font-weight: 800; cursor: pointer; transition: 0.3s; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; }
            .btn-story { background: #7e22ce; color: white; box-shadow: 0 4px 15px rgba(126,34,206,0.3); }
            .btn-video { background: #22c55e; color: #000; box-shadow: 0 4px 15px rgba(34,197,94,0.2); }
            .btn:disabled { opacity: 0.2; cursor: not-allowed; filter: grayscale(1); }
            
            .status-badge { font-size: 10px; padding: 4px 10px; border-radius: 20px; background: #111; color: #a855f7; border: 1px solid #222; }
        `;
        document.head.appendChild(style);
    }

    createDOM() {
        const overlay = document.createElement('div');
        overlay.id = 'studio-canvas-overlay';
        overlay.innerHTML = `
            <div class="studio-header">
                <div>
                    <h2 style="margin:0; color:#a855f7; font-size: 16px; letter-spacing:3px;">COOZILA! STUDIO <span style="font-weight:100; color:#444;">v4.0</span></h2>
                    <div style="display:flex; gap:10px; margin-top:5px;">
                        <span class="status-badge">HYBRID: FLUX + WAN 2.2</span>
                        <span class="status-badge" id="vram-status">VRAM: CHECKING...</span>
                    </div>
                </div>
                <button id="close-studio" style="background:none; border:none; color:#444; font-size:32px; cursor:pointer;">&times;</button>
            </div>
            
            <div class="studio-main">
                <div class="storyboard-container">
                    <div id="waveform-wrap" style="height:100px; background:#000; border-bottom:1px solid #111; position:relative;">
                        <canvas id="waveform-canvas" style="width:100%; height:100%;"></canvas>
                    </div>
                    <div class="storyboard-grid" id="story-grid">
                        <p style="grid-column: 1/-1; text-align:center; color:#222; margin-top:150px; font-size:12px; letter-spacing:2px;">UPLOAD AUDIO TO INITIALIZE TIMELINE</p>
                    </div>
                </div>

                <div class="sidebar">
                    <div id="audio-drop" class="drop-zone">
                        <span class="drop-label">1. Rhythmic Engine</span>
                        <span style="color:#444; font-size:10px;">DROP .WAV FOR BEAT-SYNC</span>
                    </div>

                    <div id="actor-drop" class="drop-zone">
                        <span class="drop-label">2. FaceID Anchor</span>
                        <span style="color:#444; font-size:10px;">DROP ACTOR PHOTO (PERSISTENCE)</span>
                        <img id="actor-preview" class="asset-preview-main">
                    </div>

                    <div class="control-unit">
                        <span class="drop-label">3. Cinematic Scenography</span>
                        <textarea class="prompt-box" id="main-prompt" placeholder="Describe the scene, lighting, and camera behavior..."></textarea>
                    </div>
                    
                    <div class="btn-group">
                        <button class="btn btn-story" id="gen-story-btn">🎨 Generate FLUX Storyboard</button>
                        <button class="btn btn-video" id="gen-video-btn" disabled>🎬 Render 720p Video (Wan 2.2)</button>
                    </div>
                    <div id="status-log" style="font-size:10px; color:#444; text-align:center; text-transform:uppercase; letter-spacing:1px;">System Ready</div>
                </div>
            </div>
        `;
        document.body.appendChild(overlay);
        this.bindEvents();
        this.updateVRAM();
    }

    async updateVRAM() {
        const stats = await this.orchestrator.checkConnection();
        if (stats.online) {
            document.getElementById('vram-status').innerText = `VRAM FREE: ${stats.vram.toFixed(2)} GB`;
        }
    }

    bindEvents() {
        window.openStudioCanvas = () => { document.getElementById('studio-canvas-overlay').style.display = 'flex'; this.updateVRAM(); };
        document.getElementById('close-studio').onclick = () => { document.getElementById('studio-canvas-overlay').style.display = 'none'; };

        this.setupDrop('audio-drop', 'audio', (f) => this.handleAudio(f));
        this.setupDrop('actor-drop', 'image', (f) => this.handleActor(f));

        document.getElementById('gen-story-btn').onclick = () => this.generatePhase1();
        document.getElementById('gen-video-btn').onclick = () => this.generatePhase2();
    }

    setupDrop(id, type, callback) {
        const el = document.getElementById(id);
        el.ondragover = (e) => { e.preventDefault(); el.style.borderColor = "#a855f7"; };
        el.ondragleave = () => { el.style.borderColor = "#1a1a1a"; };
        el.ondrop = (e) => {
            e.preventDefault();
            const file = e.dataTransfer.files[0];
            if (file && file.type.includes(type)) callback(file);
        };
    }

    async handleAudio(file) {
        const engine = new AudioEngine();
        const analysis = await engine.analyze(file);
        this.audioData = { peaks: analysis.peaks, duration: analysis.duration, url: URL.createObjectURL(file) };
        
        // Draw Waveform
        const canvas = document.getElementById('waveform-canvas');
        const ctx = canvas.getContext('2d');
        canvas.width = canvas.offsetWidth;
        ctx.clearRect(0,0, canvas.width, canvas.height);
        ctx.fillStyle = "#a855f7";
        analysis.peaks.forEach(p => {
            const x = (p / analysis.duration) * canvas.width;
            ctx.fillRect(x, 20, 1, canvas.height - 40);
        });

        // Create Grid Slots
        const grid = document.getElementById('story-grid');
        grid.innerHTML = analysis.peaks.map((p, i) => `
            <div class="story-card empty" id="slot-${i}">
                SHOT ${i+1}
                <div style="position:absolute; bottom:8px; right:8px; font-size:9px; color:#444;">${p.toFixed(2)}s</div>
            </div>
        `).join('');
        document.getElementById('status-log').innerText = "Timeline Initialized via BPM Sync";
    }

    handleActor(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            this.actorRef = e.target.result;
            const preview = document.getElementById('actor-preview');
            preview.src = e.target.result;
            preview.style.display = 'block';
        };
        reader.readAsDataURL(file);
    }

    async generatePhase1() {
        if (!this.audioData || !this.actorRef) return alert("Missing Audio or Actor Reference!");
        
        const btn = document.getElementById('gen-story-btn');
        btn.disabled = true;
        btn.innerText = "FLUX SAMPLING...";

        const payload = {
            prompt: document.getElementById('main-prompt').value,
            actor: this.actorRef,
            shotCount: this.audioData.peaks.length
        };

        const res = await this.orchestrator.dispatchStoryboard(payload);
        if (res.prompt_id) this.pollStatus(res.prompt_id, "STORYBOARD");
    }

    async generatePhase2() {
        const btn = document.getElementById('gen-video-btn');
        btn.disabled = true;
        btn.innerText = "WAN 2.2 ORCHESTRATION...";

        const res = await this.orchestrator.dispatchVideoRender({
            audio: this.audioData.url,
            style: document.getElementById('main-prompt').value
        });

        if (res.prompt_id) this.pollStatus(res.prompt_id, "VIDEO");
    }

    async pollStatus(id, type) {
        const res = await this.orchestrator.checkJobStatus(id);
        if (res.status === "done") {
            if (type === "STORYBOARD") {
                this.updateGrid(res.data);
                document.getElementById('gen-story-btn').disabled = false;
                document.getElementById('gen-story-btn').innerText = "🎨 REGENERATE STORYBOARD";
                document.getElementById('gen-video-btn').disabled = false;
            } else {
                alert("Master Render Complete (720p)!");
                document.getElementById('gen-video-btn').disabled = false;
                document.getElementById('gen-video-btn').innerText = "🎬 RENDER 720p VIDEO";
            }
        } else {
            document.getElementById('status-log').innerText = `Processing ${type}... ${res.progress || ''}`;
            setTimeout(() => this.pollStatus(id, type), 3000);
        }
    }

    updateGrid(data) {
        const images = data.outputs[Object.keys(data.outputs)[0]].images;
        images.forEach((img, i) => {
            const url = `${this.orchestrator.comfyUrl}/view?filename=${img.filename}`;
            const slot = document.getElementById(`slot-${i}`);
            if (slot) {
                slot.classList.remove('empty');
                slot.innerHTML = `<img src="${url}"><div style="position:absolute; top:8px; left:8px; background:#a855f7; color:#000; font-size:9px; font-weight:bold; padding:2px 6px; border-radius:4px;">FLUX READY</div>`;
            }
        });
    }
}

new CoozilaStudio();