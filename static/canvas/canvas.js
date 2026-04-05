// ----------------------------------------------------------------------------------#
//                                                                                   #
//   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
//   Coozila! Team    lab@coozila.com                                                #
//                                                                                   #
// ----------------------------------------------------------------------------------#

/**
 * Location: studio/canvas.js
 * Description: Main Studio Interface. Handles API Sync, OTIO Rendering, 
 * and Artifact-style auto-triggering.
 */

class CoozilaStudio {
    constructor() {
        // Configuration & State
        this.apiUrl = '/api/v1/coozila/studio';
        this.isInitialized = false;
        this.activeProjectId = null;
        
        // Start Initialization with DOM Guard
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.boot());
        } else {
            this.boot();
        }
    }

    boot() {
        if (this.isInitialized) return;
        
        console.log("🚀 [STUDIO] Initializing Coozila! Canvas Engine...");
        this.initStyles();
        this.createDOM();
        this.bindEvents();
        this.bindResizer();
        this.setupTriggerObserver();
        
        // Global Access for manual debugging
        window.openStudioCanvas = this.openCanvas.bind(this);
        this.isInitialized = true;
    }

    initStyles() {
        if (document.getElementById('coozila-studio-css')) return;
        const style = document.createElement('style');
        style.id = 'coozila-studio-css';
        style.textContent = `
            :root { --canvas-width: 65vw; --studio-purple: #7e22ce; --studio-bg: #050505; }
            
            #studio-canvas-overlay {
                position: fixed; top: 0; left: 0; 
                width: var(--canvas-width); height: 100vh;
                background: radial-gradient(circle at center, #0a0a0a 0%, var(--studio-bg) 100%);
                z-index: 2147483647;
                display: none; flex-direction: column; 
                color: #f0f0f0; font-family: 'Inter', sans-serif;
                border-right: 2px solid var(--studio-purple);
                box-shadow: 10px 0 30px rgba(0,0,0,0.5);
            }

            #studio-resizer {
                position: absolute; top: 0; right: -5px; 
                width: 10px; height: 100%; cursor: col-resize; z-index: 2147483647;
            }

            body.studio-active { 
                padding-left: var(--canvas-width) !important; 
                overflow-x: hidden !important; 
                transition: padding 0.3s ease;
            }

            .studio-header { 
                padding: 15px 30px; background: #000; 
                border-bottom: 1px solid #222; 
                display: flex; justify-content: space-between; align-items: center; 
            }

            .studio-main { display: flex; flex: 1; padding: 20px; gap: 20px; overflow: hidden; }

            .storyboard-container { 
                flex: 3; background: #080808; border-radius: 12px; 
                border: 1px solid #1a1a1a; display: flex; flex-direction: column; 
                overflow-y: auto;
            }

            .sidebar { 
                flex: 1; min-width: 280px; background: #0a0a0a; 
                border-radius: 12px; padding: 20px; display: flex; 
                flex-direction: column; gap: 15px; border: 1px solid #1a1a1a;
            }

            .btn { 
                background: var(--studio-purple); color: white; padding: 12px; 
                border: none; border-radius: 8px; font-weight: bold; cursor: pointer; 
                transition: all 0.2s; text-transform: uppercase; font-size: 11px;
            }
            .btn:hover { background: #9333ea; transform: translateY(-1px); }
            .btn-secondary { background: #222; color: #ccc; }

            #sync-status { font-size: 10px; letter-spacing: 1px; color: #444; }
            .grid-item { 
                background: #111; aspect-ratio: 16/9; border-radius: 8px; 
                border: 1px solid #222; display: flex; align-items: center; 
                justify-content: center; color: #333; font-size: 10px;
            }
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
                <div>
                    <h2 style="margin:0; color:#a855f7; font-size: 12px; letter-spacing:3px;">COOZILA STUDIO v4.1</h2>
                    <div id="sync-status">OFFLINE</div>
                </div>
                <button id="close-studio" style="background:none; border:none; color:#555; font-size:28px; cursor:pointer;">&times;</button>
            </div>
            <div class="studio-main">
                <div class="storyboard-container">
                    <div id="waveform-wrap" style="height:80px; background:#000; border-bottom:1px solid #111; padding:10px;">
                        <canvas id="waveform-canvas" style="width:100%; height:100%;"></canvas>
                    </div>
                    <div id="story-grid" style="display:grid; grid-template-columns: repeat(2, 1fr); gap:15px; padding:20px;">
                        <div class="grid-item">AWAITING PROJECT DATA...</div>
                    </div>
                </div>
                <div class="sidebar">
                    <div style="color:#555; font-size:10px; margin-bottom:5px;">CONTROL PANEL</div>
                    <button class="btn" id="btn-fetch">SYNC FROM BACKEND</button>
                    <button class="btn btn-secondary" id="btn-otio">OPEN OTIO VIEW</button>
                    <hr style="border:0; border-top:1px solid #222; margin:10px 0;">
                    <button class="btn" style="background:#222; border:1px solid #333;" id="btn-render">START MASTER RENDER</button>
                    <div id="vram-info" style="margin-top:auto; font-size:10px; color:var(--studio-purple); text-align:center;">VRAM: --</div>
                </div>
            </div>
        `;
        document.body.appendChild(overlay);
    }

    bindEvents() {
        document.getElementById('close-studio').onclick = () => this.closeCanvas();
        document.getElementById('btn-fetch').onclick = () => this.loadProject('latest');
        
        // Manual Toggle Logic
        window.addEventListener('keydown', (e) => {
            if (e.ctrlKey && e.key === 'b') this.toggleCanvas();
        });
    }

    bindResizer() {
        const resizer = document.getElementById('studio-resizer');
        let isDragging = false;

        resizer.onmousedown = (e) => { 
            isDragging = true; 
            document.body.style.cursor = 'col-resize';
            e.preventDefault();
        };

        window.onmousemove = (e) => {
            if (!isDragging) return;
            let vw = (e.clientX / window.innerWidth) * 100;
            if (vw > 25 && vw < 85) {
                document.documentElement.style.setProperty('--canvas-width', `${vw}vw`);
            }
        };

        window.onmouseup = () => { 
            isDragging = false; 
            document.body.style.cursor = 'default'; 
        };
    }

    async loadProject(projectId) {
        this.updateSyncStatus("SYNCING...", "#a855f7");
        try {
            const token = localStorage.getItem('token');
            const response = await fetch(`${this.apiUrl}/project/${projectId}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            
            if (!response.ok) throw new Error("Backend Unreachable");
            
            const data = await response.json();
            this.renderTimeline(data);
            this.updateSyncStatus("TIMELINE ACTIVE", "#a855f7");
            this.activeProjectId = projectId;
        } catch (err) {
            this.updateSyncStatus("CONNECTION ERROR", "red");
            console.error("Studio Sync Error:", err);
        }
    }

    renderTimeline(data) {
        const grid = document.getElementById('story-grid');
        grid.innerHTML = ''; // Clear placeholders

        if (data.clips) {
            data.clips.forEach(clip => {
                const item = document.createElement('div');
                item.className = 'grid-item';
                item.style.background = '#111 url(/static/studio/placeholder.png) center/cover';
                item.innerHTML = `<div style="background:rgba(0,0,0,0.7); padding:5px; border-radius:4px;">${clip.name}</div>`;
                grid.appendChild(item);
            });
        }
    }

    setupTriggerObserver() {
        const observer = new MutationObserver(() => {
            const bodyText = document.body.innerText || "";
            
            // Artifacts Auto-Trigger Logic
            const triggerTag = "[OPEN_COOZILA_CANVAS]";
            const projectTag = bodyText.match(/\[STUDIO_ID:\s*([a-zA-Z0-9_-]+)\]/);

            if (bodyText.includes(triggerTag)) {
                this.openCanvas();
                document.body.innerHTML = document.body.innerHTML.replace(triggerTag, "");
            }

            if (projectTag) {
                this.openCanvas();
                this.loadProject(projectTag[1]);
                document.body.innerHTML = document.body.innerHTML.replace(projectTag[0], "");
            }
        });
        observer.observe(document.body, { childList: true, subtree: true });
    }

    openCanvas() {
        const el = document.getElementById('studio-canvas-overlay');
        el.style.display = 'flex';
        document.body.classList.add('studio-active');
        this.updateSyncStatus("CONNECTED", "#a855f7");
    }

    closeCanvas() {
        document.getElementById('studio-canvas-overlay').style.display = 'none';
        document.body.classList.remove('studio-active');
    }

    toggleCanvas() {
        const el = document.getElementById('studio-canvas-overlay');
        if (el.style.display === 'flex') this.closeCanvas();
        else this.openCanvas();
    }

    updateSyncStatus(text, color) {
        const el = document.getElementById('sync-status');
        if (el) {
            el.innerText = text;
            el.style.color = color;
        }
    }
}

// 🛡️ Single Instance Protection
if (!window.__coozilaStudioInstance) {
    window.__coozilaStudioInstance = new CoozilaStudio();
}