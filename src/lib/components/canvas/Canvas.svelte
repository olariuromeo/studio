// ----------------------------------------------------------------------------------#
//                                                                                   //
//   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              //
//   Coozila! Team    lab@coozila.com                                                //
//                                                                                   //
// ----------------------------------------------------------------------------------#

<script lang="ts">
    /**
     * @file Canvas.svelte
     * @description Orchestration layer for the Coozila Visual Engine. 
     * Manages AI-generated scenarios, asset synchronization, and external JS engine mounting.
     */

    import { onMount, getContext } from 'svelte';
    import { settings, theme } from '$lib/stores';

    const i18n = getContext('i18n');

    /** @type {string} scenario - The written script or prompt sequence provided by the model. */
    export let scenario: string = "Awaiting input from text model...";

    /** @type {Array<Object>} assets - Collection of visual frames or generated media assets. */
    export let assets: any[] = []; 
    
    /** @type {string} activeTab - Internal state to manage view switching: 'canvas' | 'controls' | 'generate'. */
    let activeTab = 'canvas';

    /**
     * @lifecycle onMount
     * @description Handles dynamic injection of the Canvas JS Engine from the backend.
     * Prevents duplicate script loading and triggers the engine's internal rendering method.
     */
    onMount(() => {
        const ENGINE_ID = 'coozila-canvas-engine';
        const SCRIPT_SRC = '/static/canvas/canvas.js';

        console.log("[Coozila] Initializing JS Engine injection...");

        // Ensure the script is only injected once globally
        if (!document.getElementById(ENGINE_ID)) {
            const script = document.createElement('script');
            script.id = ENGINE_ID;
            script.src = SCRIPT_SRC;
            script.async = true;

            /** @callback onload - Executes after the engine's core logic is available in the window context. */
            script.onload = () => {
                console.log("[Coozila] Engine script loaded successfully.");
                if (window.__studioInstance) {
                    window.__studioInstance.renderInside('coozila-canvas-root');
                }
            };

            document.head.appendChild(script);
        } else {
            // Re-trigger render if the engine is already loaded but the component re-mounted
            if (window.__studioInstance) {
                window.__studioInstance.renderInside('coozila-canvas-root');
            }
        }
    });

    /**
     * @function tabClass
     * @description Generates dynamic Tailwind utility classes for tab navigation based on active state.
     * @param {string} id - The target tab ID.
     * @returns {string} Compiled CSS class string.
     */
    $: tabClass = (id: string) =>
        `flex-1 px-3 py-2 text-[10px] font-black tracking-widest uppercase transition-all duration-200 ${
            activeTab === id
                ? 'bg-white dark:bg-gray-800 text-black dark:text-white shadow-md rounded-lg scale-[1.02]'
                : 'text-gray-500 hover:text-gray-700 dark:hover:text-gray-400'
        }`;
</script>

<div class="flex flex-col h-full w-full bg-gray-50 dark:bg-black font-primary overflow-hidden select-none">
    
    <nav class="flex space-x-1 p-1 bg-gray-200/50 dark:bg-gray-900/50 rounded-xl mb-4 mx-4 mt-4 border border-gray-300 dark:border-gray-800">
        <button class={tabClass('canvas')} on:click={() => (activeTab = 'canvas')}>Canvas</button>
        <button class={tabClass('controls')} on:click={() => (activeTab = 'controls')}>Controls</button>
        <button class={tabClass('generate')} on:click={() => (activeTab = 'generate')}>Generate</button>
    </nav>

    <main class="flex-1 overflow-y-auto px-4 custom-scrollbar">
        {#if activeTab === 'canvas'}
            <div class="flex flex-col gap-6 pb-10">
                
                <section class="p-4 rounded-2xl bg-white dark:bg-gray-950 border border-gray-200 dark:border-gray-800 shadow-sm">
                    <header class="flex items-center gap-2 mb-3">
                        <div class="w-1.5 h-1.5 rounded-full bg-purple-600 animate-pulse"></div>
                        <h3 class="text-[10px] font-bold uppercase tracking-widest opacity-40">Active Scenario</h3>
                    </header>
                    <article class="text-sm leading-relaxed text-gray-700 dark:text-gray-300">
                        {scenario}
                    </article>
                </section>

                <section id="coozila-canvas-root" class="w-full min-h-[300px]">
                    <div class="grid grid-cols-2 gap-3">
                        {#each assets as asset}
                            <div class="aspect-video bg-gray-900 rounded-xl border border-gray-800 overflow-hidden shadow-inner">
                                <img src={asset.url} alt="Sequence Frame" class="w-full h-full object-cover" />
                            </div>
                        {/each}
                    </div>
                </section>
            </div>
            
        {:else if activeTab === 'controls'}
            <section class="p-5 rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-950 shadow-sm">
                <h3 class="text-xs font-black mb-4 uppercase tracking-[0.2em] text-purple-600">Engine Parameters</h3>
                <div class="space-y-4 opacity-50 text-[10px] italic">
                    <p>Node Status: Online / Wan 2.2 Active</p>
                    <p>Processing: FP8 Quantized VAE Enabled</p>
                </div>
            </section>
        {/if}
    </main>

    <footer class="p-4 border-t border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-black/50">
        <div class="flex justify-between items-center opacity-30 text-[9px] font-black uppercase tracking-widest">
            <span>Coozila Engine v4.1</span>
            <span>Status: Connected</span>
        </div>
    </footer>
</div>

<style>
    /* Sleek scrollbar for sidebar integration */
    .custom-scrollbar::-webkit-scrollbar {
        width: 3px;
    }
    .custom-scrollbar::-webkit-scrollbar-thumb {
        background: rgba(156, 163, 175, 0.2);
        border-radius: 10px;
    }
</style>