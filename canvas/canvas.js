// ----------------------------------------------------------------------------------#
//                                                                                   #
//   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
//   Coozila! Team    lab@coozila.com                                                #
//                                                                                   #
// ----------------------------------------------------------------------------------#

/**
 * Location: studio/canvas.js
 * Version: 9.0.0
 * Fixes: Cross-Origin Security Errors, scrollHeight null, and Singleton collisions.
 */

import { AudioEngine } from './audio_engine.js';
import { StudioOrchestrator } from './orchestrator.js';

class CoozilaStudio {
    constructor() {
        this.audioData = null;
        this.actorRef = null;
        this.orchestrator = new StudioOrchestrator();

        // Folosim un delay mic pentru inițializare ca să lăsăm DOM-ul OpenWebUI să se așeze
        setTimeout(() => {
            this.initStyles();
            this.createDOM();
            this.setupTriggerObserver();
        }, 100);
    }

    initStyles() {
        if (document.getElementById('coozila-studio-css')) return;
        const style = document.createElement('style');
        style.id = 'coozila-studio-css';
        style.textContent = `
            :root { --canvas-width: 65vw; }
            #studio-canvas-overlay {
                position: fixed; top: 0; left: 0; 
                width: var(--canvas-width); height: 100vh;
                background: radial-gradient(circle at center, #0a0a0a 0%, #050505 100%);
                z-index: 2147483647; /* Maximum z-index posibil */
                display: none; flex-direction: column; 
                color: #f0f0f0; font-family: 'Inter', sans-serif;
                border-right: 2px solid #7e22ce;
            }
            #studio-resizer {
                position: absolute; top: 0; right: -5px; 
                width: 10px; height: 100%; cursor: col-resize; z-index: 2147483647;
            }
            body.studio-active { 
                padding-left: var(--canvas-width) !important; 
                overflow-x: hidden !important; 
            }
            .studio-header { padding: 15px 30px; background: #000; border-bottom: 1px solid #222; display: flex; justify-content: space-between; align-items: center; }
            .studio-main { display: flex; flex: 1; padding: 20px; gap: 20px; overflow: hidden; }
            .storyboard-container { flex: 3; background: #050505; border-radius: 12px; border: 1px solid #1a1a1a; display: flex; flex-direction: column; }
            .sidebar { flex: 1; min-width: 280px; background: #080808; border-radius: 12px; padding: 15px; display: flex; flex-direction: column; gap: 15px; }
            .btn { background: #7e22ce; color: white; padding: 12px; border: none; border-radius: 8px; font-weight: bold; cursor: pointer; }
        `;
        document.head.appendChild(style);
    }

    createDOM() {
        if (document.getElementById('studio-canvas-overlay')) return;

        const overlay = document.createElement('div');
        overlay.id = 'studio-canvas-overlay';
        overlay.innerHTML = `
            <div id="studio-resizer"></div>
            <div class="studio-header">
                <h2 style="margin:0; color:#a855f7; font-size: 14px; letter-spacing:2px;">COOZILA STUDIO</h2>
                <button id="close-studio" style="background:none; border:none; color:#555; font-size:24px; cursor:pointer;">&times;</button>
            </div>
            <div class="studio-main">
                <div class="storyboard-container">
                    <div id="waveform-wrap" style="height:60px; background:#000;">
                        <canvas id="waveform-canvas" style="width:100%; height:100%;"></canvas>
                    </div>
                    <div id="story-grid" style="padding:40px; text-align:center; color:#222; font-size:12px;">ASSET PIPELINE READY</div>
                </div>
                <div class="sidebar">
                    <button class="btn" id="gen-story-btn">GENERATE STORYBOARD</button>
                    <div id="vram-status" style="font-size:10px; color:#444; text-align:center;">VRAM: --</div>
                </div>
            </div>
        `;
        document.body.appendChild(overlay);
        this.bindEvents();
        this.bindResizer();
    }

    bindEvents() {
        window.openStudioCanvas = () => {
            const el = document.getElementById('studio-canvas-overlay');
            if (el) {
                el.style.setProperty('display', 'flex', 'important');
                document.body.classList.add('studio-active');
                this.updateVRAM();
            }
        };

        const closeBtn = document.getElementById('close-studio');
        if (closeBtn) {
            closeBtn.onclick = () => {
                document.getElementById('studio-canvas-overlay').style.display = 'none';
                document.body.classList.remove('studio-active');
            };
        }
    }

    bindResizer() {
        const resizer = document.getElementById('studio-resizer');
        let isDragging = false;
        if (!resizer) return;

        resizer.onmousedown = () => { isDragging = true; document.body.style.cursor = 'col-resize'; };
        window.onmousemove = (e) => {
            if (!isDragging) return;
            let vw = (e.clientX / window.innerWidth) * 100;
            if (vw > 20 && vw < 80) document.documentElement.style.setProperty('--canvas-width', `${vw}vw`);
        };
        window.onmouseup = () => { isDragging = false; document.body.style.cursor = 'default'; };
    }

    setupTriggerObserver() {
        if (window.__coozilaTriggerObserved) return;
        window.__coozilaTriggerObserved = true;

        const observer = new MutationObserver(() => {
            // Căutăm direct în document body pentru a evita problemele de cross-origin din frame-uri
            const bodyText = document.body.innerText || "";
            if (bodyText.includes('[OPEN_COOZILA_CANVAS]')) {
                window.openStudioCanvas();
                // Curățăm textul pentru a nu declanșa infinit
                document.body.innerHTML = document.body.innerHTML.replace('[OPEN_COOZILA_CANVAS]', '');
            }
        });
        observer.observe(document.body, { childList: true, subtree: true });
    }

    async updateVRAM() {
        try {
            const stats = await this.orchestrator.checkConnection();
            const el = document.getElementById('vram-status');
            if (el && stats.online) el.innerText = `VRAM: ${stats.vram.toFixed(2)} GB FREE`;
        } catch (e) { /* Silent fail pentru a evita erori în consolă */ }
    }
}

// 🛡️ Safe Execution Guard
if (!window.__coozilaStudioLoaded) {
    window.__coozilaStudioLoaded = true;
    try {
        window.__coozilaStudioInstance = new CoozilaStudio();
    } catch (e) {
        console.error("Studio Init Failed:", e);
    }
}