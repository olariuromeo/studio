// ----------------------------------------------------------------------------------#
//                                                                                   #
//   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
//   Coozila! Team    lab@coozila.com                                                #
//                                                                                   #
// ----------------------------------------------------------------------------------#

/**
 * Location: studio/canvas.js
 * Description: Storyboard & Video Orchestrator UI. 
 * Supports reference assets for actors/scenery and batch image generation.
 */

import { AudioEngine } from './audio_engine.js';
import { StudioOrchestrator } from './orchestrator.js';

class CoozilaStudio {
    constructor() {
        this.audioData = null;
        this.referenceAssets = []; // Stores Base64 of actors/scenery
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
                background: rgba(8, 8, 8, 0.98); backdrop-filter: blur(20px);
                z-index: 100000; display: none; flex-direction: column; color: #e0e0e0;
                font-family: 'Inter', sans-serif;
            }
            .studio-header { padding: 15px 40px; background: #000; border-bottom: 1px solid #222; display: flex; justify-content: space-between; align-items: center; }
            .studio-main { display: flex; flex: 1; padding: 20px; gap: 20px; overflow: hidden; }
            
            /* Storyboard Area */
            .storyboard-container {
                flex: 3; background: #050505; border: 1px solid #1a1a1a; 
                border-radius: 12px; display: flex; flex-direction: column; overflow: hidden;
            }
            .storyboard-grid {
                flex: 1; display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
                gap: 15px; padding: 20px; overflow-y: auto; background: #000;
            }
            .story-card {
                background: #0a0a0a; border: 1px solid #222; border-radius: 8px; 
                aspect-ratio: 16/9; position: relative; overflow: hidden; display: flex; 
                align-items: center; justify-content: center; transition: 0.3s;
            }
            .story-card img { width: 100%; height: 100%; object-fit: cover; }
            .story-card.empty { border: 1px dashed #333; color: #222; font-size: 10px; }
            .card-meta { position: absolute; bottom: 0; width: 100%; background: rgba(0,0,0,0.8); padding: 5px 10px; font-size: 10px; color: #666; }

            /* Sidebar */
            .sidebar { flex: 1; background: #0a0a0a; border: 1px solid #1a1a1a; border-radius: 12px; padding: 20px; display: flex; flex-direction: column; gap: 15px; }
            .drop-zone { border: 2px dashed #222; border-radius: 8px; padding: 15px; text-align: center; cursor: pointer; font-size: 11px; color: #444; }
            .drop-zone:hover { border-color: #a855f7; color: #a855f7; }
            .asset-strip { display: flex; gap: 5px; overflow-x: auto; height: 50px; margin-top: 5px; }
            .asset-thumb { height: 100%; aspect-ratio: 1; object-fit: cover; border-radius: 4px; border: 1px solid #222; }
            
            .prompt-box { width: 100%; height: 100px; background: #000; border: 1px solid #222; color: #fff; padding: 12px; border-radius: 8px; resize: none; font-size: 12px; }
            .btn-group { display: flex; flex-direction: column; gap: 10px; }
            .btn { padding: 12px; border-radius: 8px; border: none; font-weight: bold; cursor: pointer; transition: 0.2s; font-size: 11px; text-transform: uppercase; }
            .btn-story { background: #7e22ce; color: white; }
            .btn-video { background: #22c55e; color: black; }
            .btn:disabled { opacity: 0.3; cursor: not-allowed; }
        `;
        document.head.appendChild(style);
    }

    createDOM() {
        const overlay = document.createElement('div');
        overlay.id = 'studio-canvas-overlay';
        overlay.innerHTML = `
            <div class="studio-header">
                <div>
                    <h2 style="margin:0; color:#a855f7; font-size: 18px; letter-spacing:2px;">STORYBOARD STUDIO</h2>
                    <span style="font-size:9px; color:#444;">PHASE 1: CHARACTER & SCENE SYNC</span>
                </div>
                <button id="close-studio" style="background:none; border:none; color:#444; font-size:30px; cursor:pointer;">&times;</button>
            </div>
            
            <div class="studio-main">
                <div class="storyboard-container">
                    <div id="waveform-wrap" style="height:80px; background:#000; border-bottom:1px solid #111; position:relative;">
                        <canvas id="waveform-canvas" style="width:100%; height:100%;"></canvas>
                    </div>
                    <div class="storyboard-grid" id="story-grid">
                        <p style="grid-column: 1/-1; text-align:center; color:#222; margin-top:100px;">LOAD WAV TO GENERATE STORY SLOTS</p>
                    </div>
                </div>

                <div class="sidebar">
                    <div id="audio-drop" class="drop-zone">📥 DROP WAV (BEAT SYNC)</div>
                    <div id="asset-drop" class="drop-zone">👤 DROP ACTOR/SCENE REFS
                        <div class="asset-strip" id="asset-previews"></div>
                    </div>

                    <textarea class="prompt-box" id="main-prompt" placeholder="Master Visual Prompt (Scenography details)..."></textarea>
                    
                    <div class="btn-group">
                        <button class="btn btn-story" id="gen-story-btn">🎨 1. Generate Storyboard</button>
                        <button class="btn btn-video" id="gen-video-btn" disabled>🎬 2. Render Video (Wan 2.2)</button>
                    </div>
                    <div id="status-log" style="font-size:10px; color:#444; text-align:center;">READY</div>
                </div>
            </div>
        `;
        document.body.appendChild(overlay);
        this.bindEvents();
    }

    bindEvents() {
        window.openStudioCanvas = () => { document.getElementById('studio-canvas-overlay').style.display = 'flex'; };
        document.getElementById('close-studio').onclick = () => { document.getElementById('studio-canvas-overlay').style.display = 'none'; };

        this.setupDrop('audio-drop', 'audio', (f) => this.handleAudio(f));
        this.setupDrop('asset-drop', 'image', (f) => this.handleAsset(f));

        document.getElementById('gen-story-btn').onclick = () => this.generateStory();
    }

    setupDrop(id, type, callback) {
        const el = document.getElementById(id);
        el.ondragover = (e) => { e.preventDefault(); el.style.borderColor = "#a855f7"; };
        el.ondragleave = () => { el.style.borderColor = "#222"; };
        el.ondrop = (e) => {
            e.preventDefault();
            const file = e.dataTransfer.files[0];
            if (file && file.type.includes(type)) callback(file);
        };
    }

    async handleAudio(file) {
        const engine = new AudioEngine();
        const analysis = await engine.analyze(file);
        this.audioData = { peaks: analysis.peaks, duration: analysis.duration };
        
        // Draw Waveform
        const canvas = document.getElementById('waveform-canvas');
        const ctx = canvas.getContext('2d');
        canvas.width = canvas.offsetWidth;
        ctx.fillStyle = "#a855f7";
        analysis.peaks.forEach(p => {
            const x = (p / analysis.duration) * canvas.width;
            ctx.fillRect(x, 0, 1, canvas.height);
        });

        // Create Grid Slots
        const grid = document.getElementById('story-grid');
        grid.innerHTML = analysis.peaks.map((p, i) => `
            <div class="story-card empty" id="slot-${i}">
                SHOT ${i+1}
                <div class="card-meta">${p.toFixed(2)}s</div>
            </div>
        `).join('');
    }

    handleAsset(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            this.referenceAssets.push(e.target.result);
            document.getElementById('asset-previews').innerHTML += `<img src="${e.target.result}" class="asset-thumb">`;
        };
        reader.readAsDataURL(file);
    }

    async generateStory() {
        const prompt = document.getElementById('main-prompt').value;
        const btn = document.getElementById('gen-story-btn');
        if (!this.audioData || this.referenceAssets.length === 0) return alert("Upload WAV and Reference Images!");

        btn.disabled = true;
        btn.innerText = "GENERATING STORYBOARD...";

        const res = await this.orchestrator.dispatchStoryboard({
            prompt: prompt,
            assets: this.referenceAssets,
            shotCount: this.audioData.peaks.length
        });

        if (res.prompt_id) this.pollStory(res.prompt_id);
    }

    async pollStory(id) {
        const res = await this.orchestrator.checkJobStatus(id);
        if (res.status === "done") {
            const images = res.data.outputs[Object.keys(res.data.outputs)[0]].images;
            images.forEach((img, i) => {
                const url = `${this.orchestrator.comfyUrl}/view?filename=${img.filename}`;
                const slot = document.getElementById(`slot-${i}`);
                if (slot) slot.innerHTML = `<img src="${url}"><div class="card-meta">SHOT ${i+1} - SYNC OK</div>`;
            });
            document.getElementById('gen-story-btn').innerText = "🎨 REGENERATE STORYBOARD";
            document.getElementById('gen-story-btn').disabled = false;
            document.getElementById('gen-video-btn').disabled = false;
        } else {
            setTimeout(() => this.pollStory(id), 3000);
        }
    }
}

new CoozilaStudio();