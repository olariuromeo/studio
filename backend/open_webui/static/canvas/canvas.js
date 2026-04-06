/**
 * @class StudioCanvas
 * @description Core JS Engine for the Coozila! Canvas. 
 * Location: static/canvas/canvas.js
 * Handles DOM construction inside Svelte, API communication, and timeline rendering.
 */
import { StudioOrchestrator } from './orchestrator.js';

class StudioCanvas {
    constructor() {
        this.apiUrl = '/api/v1/studio';
        this.activeSessionId = null;
        this.isInitialized = false;
        this.currentSchema = null;
        this.orchestrator = new StudioOrchestrator();
        
        console.log("[Coozila Engine] System initialized. Waiting for mount...");
    }

    /**
     * @function renderInside
     * @description Mounts the Canvas interface into a specific DOM element.
     * @param {string} targetId - The ID of the container (from Canvas.svelte).
     */
    async renderInside(targetId) {
        const container = document.getElementById(targetId);
        if (!container) {
            console.error(`[Coozila] Target element #${targetId} not found.`);
            return;
        }

        // Clean up any previous instance
        container.innerHTML = '';
        
        this.initStyles();
        await this.syncWithBackend(); // Fetch schema first
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
                padding: 5px;
                flex-direction: column;
                justify-content: space-between;
            }
            .item-label { background: rgba(0,0,0,0.8); width: 100%; padding: 4px; text-align: center; }
            .item-prompt { font-size: 8px; color: #ccc; word-wrap: break-word; overflow: hidden; max-height: 40px; }
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
            
            /* Preview Window Styles */
            .preview-container {
                display: flex; justify-content: center; align-items: center;
                background: #050505; border-radius: 8px; margin-bottom: 10px;
                overflow: hidden; border: 1px solid #1a1a1a;
            }
        `;
        document.head.appendChild(style);
    }
    
    async syncWithBackend() {
        // Fetch the initial/current schema from the backend
        try {
            const resp = await fetch(`${this.apiUrl}/action`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action: 'get_schema' })
            });
            const result = await resp.json();
            if (result.status === "success" && result.schema) {
                this.currentSchema = result.schema;
                console.log("📥 Canvas: Schema Loaded from Backend", this.currentSchema);
            } else {
                 // Fallback if no schema is returned yet
                 console.warn("⚠️ Canvas: No schema returned from backend, waiting for sync.");
            }
        } catch (error) {
             console.error("❌ Canvas: Failed to fetch initial schema:", error);
        }
    }

    /** @private @description Builds the UI structure inside the provided container. */
    createDOM(container) {
        const wrapper = document.createElement('div');
        wrapper.className = 'canvas-embedded-wrapper';
        
        // Define preview dimensions based on schema (fallback to 896x512)
        const previewWidth = this.currentSchema?.engine_config?.resolution?.width || 896;
        const previewHeight = this.currentSchema?.engine_config?.resolution?.height || 512;
        
        // Use aspect ratio for responsive scaling within the container
        const aspectRatio = previewWidth / previewHeight;

        wrapper.innerHTML = `
            <div class="canvas-visual-area">
                <div class="preview-container" style="aspect-ratio: ${aspectRatio}; width: 100%;">
                    <div id="preview-window" style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; color: #555;">
                        Awaiting Render...
                    </div>
                </div>
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
                <button class="btn-engine" id="btn-draw-preview" style="background:#111; border:1px solid #a855f7;">Paint Preview (Turbo)</button>
                <div id="sync-status" style="font-size:8px; opacity:0.4; text-align:center; margin-top:5px;">STATUS: STANDBY</div>
            </div>
        `;
        container.appendChild(wrapper);
        
        // Initial render of timeline if schema exists
        if (this.currentSchema) {
            this.renderTimeline(this.currentSchema);
        }
    }

    /** @private @description Binds API actions to the UI buttons. */
    bindEvents() {
        document.getElementById('btn-sync-state').onclick = () => {
            const sid = prompt("Enter Session ID:");
            if (sid) {
                this.activeSessionId = sid;
                this.callAction('get_schema', sid);
            }
        };

        document.getElementById('btn-trigger-render').onclick = () => this.executeRender();
        
        document.getElementById('btn-draw-preview').onclick = async () => {
            if (!this.currentSchema) {
                alert("No schema loaded. Sync project first.");
                return;
            }
            this.updateStatus("PAINTING PREVIEW...", "orange");
            try {
                 // Call orchestrator.js to handle the ComfyUI logic
                 const result = await this.orchestrator.dispatchJob(this.currentSchema);
                 console.log("Render Result:", result);
                 this.updateStatus("PREVIEW COMPLETE", "#a855f7");
                 // Here you would typically update the preview window with the generated image/video URL
            } catch (error) {
                 this.updateStatus("PAINT ERROR", "red");
                 console.error(error);
            }
        };
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
                this.currentSchema = result.schema; // Update local schema
                this.renderTimeline(result.schema);
                this.updateStatus("CONNECTED", "#a855f7");
            } else {
                 this.updateStatus("SYNC FAILED", "red");
            }
        } catch (err) {
            this.updateStatus("SYNC ERROR", "red");
        }
    }

    /** @description Triggers the final video rendering pipeline in the backend. */
    async executeRender() {
        this.updateStatus("RENDERING FULL SEQUENCE...", "cyan");
        // Logic for triggering /render endpoint...
    }

    /** @description Updates the visual grid with data from the Schema. */
    renderTimeline(schema) {
        const grid = document.getElementById('timeline-grid');
        grid.innerHTML = '';
        
        // Extract clips from the new nested schema structure
        let clips = [];
        try {
            if (schema.timeline_structure && schema.timeline_structure.tracks && schema.timeline_structure.tracks.length > 0) {
                 clips = schema.timeline_structure.tracks[0].clips || [];
            }
        } catch (e) {
            console.warn("Could not parse timeline structure:", e);
        }

        if (clips.length === 0) {
             grid.innerHTML = '<div class="grid-item"><div class="item-label">No Clips Found</div></div>';
             return;
        }

        clips.forEach((clip, index) => {
            const item = document.createElement('div');
            item.className = 'grid-item';
            
            // If the schema defines a thumbnail, use it
            if (clip.thumb) {
                item.style.backgroundImage = `url(${clip.thumb})`;
            } else {
                item.style.backgroundColor = '#1a1a1a'; // Fallback color
            }
            
            const promptPreview = clip.prompt ? clip.prompt.substring(0, 40) + '...' : 'No prompt';
            
            item.innerHTML = `
                <div class="item-prompt" title="${clip.prompt || ''}">${promptPreview}</div>
                <div class="item-label">Shot ${index + 1} (${clip.duration_sec || 0}s)</div>
            `;
            grid.appendChild(item);
        });
        
        // Update Preview Area dimensions if schema changed
        const previewContainer = document.querySelector('.preview-container');
        if (previewContainer && schema.engine_config && schema.engine_config.resolution) {
             const aspectRatio = schema.engine_config.resolution.width / schema.engine_config.resolution.height;
             previewContainer.style.aspectRatio = aspectRatio;
        }
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

/**
 * GLOBAL BRIDGE FOR THE AI TOOL
 * This must be the LAST block in the file.
 * It allows the JSON Tool to trigger the Canvas via window.openStudioCanvas().
 */
window.openStudioCanvas = (sessionId = null) => {
    console.log("[Coozila] AI Tool invoked window.openStudioCanvas");

    // We check if the Svelte container exists in the DOM
    const root = document.getElementById('coozila-canvas-root');
    
    if (root) {
        // Force the engine to render the UI inside the Svelte tab
        window.__studioInstance.renderInside('coozila-canvas-root');
        
        // If the AI provided a Session ID, sync the data immediately
        if (sessionId && typeof sessionId === 'string') {
            window.__studioInstance.callAction('get_schema', sessionId);
        }
    } else {
        console.warn("[Coozila] Canvas root not found. Please open the Controls sidebar.");
    }
};