// ----------------------------------------------------------------------------------#
//                                                                                   //
//   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              //
//   Coozila! Team    lab@coozila.com                                                //
//                                                                                   //
// ----------------------------------------------------------------------------------#

/**
 * @class StudioCanvas
 * @description Core JS Engine for the Coozila Canvas. 
 * Handles DOM construction inside Svelte, API communication, and timeline rendering.
 */
class StudioCanvas {
    constructor() {
        this.apiUrl = '/api/v1/studio';
        this.activeSessionId = null;
        this.isInitialized = false;
        
        console.log("[Coozila Engine] System initialized. Waiting for mount...");
    }

    /**
     * @function renderInside
     * @description Mounts the Canvas interface into a specific DOM element.
     * @param {string} targetId - The ID of the container (from Canvas.svelte).
     */
    renderInside(targetId) {
        const container = document.getElementById(targetId);
        if (!container) {
            console.error(`[Coozila] Target element #${targetId} not found.`);
            return;
        }

        // Clean up any previous instance
        container.innerHTML = '';
        
        this.initStyles();
        this.createDOM(container);
        this.bindEvents();
        
        this.isInitialized = true;
        console.log(`[Coozila] Engine successfully mounted to #${targetId}`);
    }

    /** @private @description Injects core CSS specifically for embedded mode. */
    initStyles() {
        if (document.getElementById('studio-core-css')) return;
        const style = document.createElement('style');
        style.id = 'studio-core-css';
        style.textContent = `
            .canvas-embedded-wrapper {
                display: flex; flex-direction: column; height: 100%; width: 100%;
                background: #000; color: #f0f0f0; font-family: 'Inter', sans-serif;
            }
            .canvas-visual-area {
                flex: 1; overflow-y: auto; padding: 15px; display: flex; flex-direction: column; gap: 15px;
            }
            #waveform-wrap {
                height: 60px; background: #050505; border: 1px solid #1a1a1a; border-radius: 8px; overflow: hidden;
            }
            #timeline-grid {
                display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px;
            }
            .grid-item { 
                background: #111; aspect-ratio: 16/9; border-radius: 8px; 
                border: 1px solid #222; display: flex; align-items: flex-end;
                font-size: 9px; text-transform: uppercase; font-weight: bold;
                background-size: cover; background-position: center;
            }
            .item-label { background: rgba(0,0,0,0.8); width: 100%; padding: 4px; text-align: center; }
            .canvas-footer-actions {
                padding: 15px; background: #0a0a0a; border-top: 1px solid #1a1a1a;
                display: flex; flex-direction: column; gap: 8px;
            }
            .btn-engine {
                background: #7e22ce; color: white; padding: 10px; border: none;
                border-radius: 6px; font-size: 10px; font-weight: 900;
                cursor: pointer; transition: background 0.2s; text-transform: uppercase;
            }
            .btn-engine:hover { background: #9333ea; }
        `;
        document.head.appendChild(style);
    }

    /** @private @description Builds the UI structure inside the provided container. */
    createDOM(container) {
        const wrapper = document.createElement('div');
        wrapper.className = 'canvas-embedded-wrapper';
        wrapper.innerHTML = `
            <div class="canvas-visual-area">
                <div id="waveform-wrap">
                    <canvas id="waveform-canvas" style="width:100%; height:100%;"></canvas>
                </div>
                <div id="timeline-grid">
                    <div class="grid-item"><div class="item-label">Awaiting Sequence...</div></div>
                </div>
            </div>
            <div class="canvas-footer-actions">
                <button class="btn-engine" id="btn-sync-state">Sync Project</button>
                <button class="btn-engine" id="btn-trigger-render" style="background:#111; border:1px solid #7e22ce;">Trigger Master Render</button>
                <div id="sync-status" style="font-size:8px; opacity:0.4; text-align:center; margin-top:5px;">STATUS: STANDBY</div>
            </div>
        `;
        container.appendChild(wrapper);
    }

    /** @private @description Binds API actions to the UI buttons. */
    bindEvents() {
        document.getElementById('btn-sync-state').onclick = () => {
            const sid = prompt("Enter Session ID:");
            if (sid) this.callAction('get_schema', sid);
        };

        document.getElementById('btn-trigger-render').onclick = () => this.executeRender();
    }

    /** @description Communicates with the Python Studio API. */
    async callAction(action, sessionId, payload = {}) {
        this.updateStatus("SYNCING...", "orange");
        try {
            const response = await fetch(`${this.apiUrl}/action`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ session_id: sessionId, action, payload })
            });
            const result = await response.json();
            if (result.status === "success") {
                this.renderTimeline(result.schema);
                this.updateStatus("CONNECTED", "#a855f7");
            }
        } catch (err) {
            this.updateStatus("SYNC ERROR", "red");
        }
    }

    /** @description Triggers the final video rendering pipeline in the backend. */
    async executeRender() {
        this.updateStatus("RENDERING...", "cyan");
        // Logic for triggering /render endpoint...
    }

    /** @description Updates the visual grid with data from the API. */
    renderTimeline(schema) {
        const grid = document.getElementById('timeline-grid');
        grid.innerHTML = '';
        const clips = schema.clips || [];
        clips.forEach((clip, index) => {
            const item = document.createElement('div');
            item.className = 'grid-item';
            if (clip.thumb) item.style.backgroundImage = `url(${clip.thumb})`;
            item.innerHTML = `<div class="item-label">Shot ${index + 1}</div>`;
            grid.appendChild(item);
        });
    }

    /** @private */
    updateStatus(text, color) {
        const el = document.getElementById('sync-status');
        if (el) { el.innerText = text; el.style.color = color; }
    }
}

// Singleton initialization for Svelte access
if (!window.__studioInstance) {
    window.__studioInstance = new StudioCanvas();
}