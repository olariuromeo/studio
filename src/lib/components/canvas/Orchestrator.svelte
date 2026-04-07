<script lang="ts">
    /**
     * @file Orchestrator.svelte
     * @location src/lib/components/canvas/Orchestrator.svelte
     * @description Mission Control UI for Coozila! Studio. 
     * Interfaces with orchestrator.js to manage Wan 2.2 render phases.
     */
    import { orchestratorStatus, StudioOrchestrator } from '$lib/canvas/orchestrator.js';
    import { fade, slide } from 'svelte/transition';

    // The current project schema passed from the parent Canvas
    export let schema: any = null;

    // Initialize the engine logic
    const engine = new StudioOrchestrator();

    /** * PHASE A: STORYBOARD 
     * Generates 64-bit aligned static stills for scene validation.
     */
    async function triggerPhaseA() {
        if (!schema) return;
        try {
            await engine.dispatchStoryboard(schema);
        } catch (e) {
            console.error("Phase A Dispatch Error:", e);
        }
    }

    /** * PHASE B: MASTER RENDER 
     * Executes the full temporal Wan 2.2 sequence + RIFE interpolation.
     */
    async function triggerPhaseB() {
        if (!schema) return;
        try {
            await engine.dispatchJob(schema);
        } catch (e) {
            console.error("Phase B Dispatch Error:", e);
        }
    }

    // Reactive status mapping
    $: statusMap = {
        'IDLE': { color: 'bg-gray-500', label: 'Engine Standby' },
        'SENDING': { color: 'bg-blue-400 animate-pulse', label: 'Injecting Latents' },
        'RENDERING': { color: 'bg-orange-500 animate-bounce', label: 'Wan 2.2 Processing' },
        'DONE': { color: 'bg-purple-600', label: 'Master Ready' },
        'ERROR': { color: 'bg-red-500', label: 'Pipeline Failure' }
    };

    $: currentStatus = statusMap[$orchestratorStatus.state] || statusMap['IDLE'];
</script>

<div class="flex flex-col gap-5 p-6 rounded-[2rem] bg-white dark:bg-[#0a0a0a] border border-gray-200 dark:border-white/5 shadow-2xl font-primary relative overflow-hidden">
    
    <header class="flex justify-between items-center z-10">
        <div class="flex items-center gap-3">
            <div class="w-2.5 h-2.5 rounded-full {currentStatus.color} shadow-[0_0_15px_rgba(126,34,206,0.4)]"></div>
            <div class="flex flex-col">
                <h2 class="text-[10px] font-black uppercase tracking-[0.2em] leading-none text-gray-900 dark:text-white">
                    {currentStatus.label}
                </h2>
                <span class="text-[8px] opacity-30 font-bold uppercase mt-1 tracking-widest">
                    Worker: http://localhost:8188
                </span>
            </div>
        </div>
        
        {#if $orchestratorStatus.lastPromptId}
            <div class="px-2 py-1 bg-gray-100 dark:bg-white/5 rounded-md text-[7px] font-mono opacity-40 uppercase">
                ID: {$orchestratorStatus.lastPromptId.split('-')[0]}
            </div>
        {/if}
    </header>

    <section class="space-y-3 z-10">
        <div class="flex justify-between items-end px-1">
            <span class="text-[8px] font-black uppercase opacity-20 tracking-tighter">GPU VRAM Pipeline Load</span>
            <span class="text-[12px] font-mono font-black italic">{$orchestratorStatus.progress}%</span>
        </div>
        
        <div class="h-2 w-full bg-gray-100 dark:bg-white/5 rounded-full overflow-hidden p-[2px]">
            <div 
                class="h-full bg-gradient-to-r from-purple-600 via-fuchsia-500 to-purple-400 rounded-full transition-all duration-1000 ease-in-out"
                style="width: {$orchestratorStatus.progress}%"
            ></div>
        </div>
    </section>

    <div class="grid grid-cols-2 gap-3 z-10">
        <button 
            on:click={triggerPhaseA}
            disabled={$orchestratorStatus.state === 'RENDERING'}
            class="group flex flex-col items-center justify-center p-5 rounded-2xl border border-gray-200 dark:border-white/10 bg-gray-50 dark:bg-white/[0.02] hover:bg-white/[0.05] transition-all disabled:opacity-20"
        >
            <span class="text-[10px] font-black uppercase tracking-widest group-hover:text-purple-500 transition-colors">Phase A</span>
            <span class="text-[7px] opacity-30 font-bold mt-1 uppercase">Storyboard Stills</span>
        </button>

        <button 
            on:click={triggerPhaseB}
            disabled={$orchestratorStatus.state === 'RENDERING'}
            class="relative flex flex-col items-center justify-center p-5 rounded-2xl bg-purple-600 text-white shadow-xl shadow-purple-500/20 hover:bg-purple-500 transition-all disabled:opacity-10 overflow-hidden"
        >
            <span class="text-[10px] font-black uppercase tracking-widest relative z-10">Phase B</span>
            <span class="text-[7px] text-purple-200 font-bold mt-1 uppercase relative z-10">Master Render</span>
            {#if $orchestratorStatus.state === 'RENDERING'}
                <div class="absolute inset-0 bg-white/20 animate-[pulse_1s_infinite]"></div>
            {/if}
        </button>
    </div>

    {#if $orchestratorStatus.error}
        <div transition:slide class="p-3 rounded-xl bg-red-500/10 border border-red-500/20">
            <p class="text-[9px] font-bold text-red-500 uppercase tracking-tighter leading-tight">
                Critical Exception: {$orchestratorStatus.error}
            </p>
        </div>
    {/if}

    <div class="absolute -right-10 -bottom-10 w-32 h-32 bg-purple-600/5 blur-[50px] rounded-full pointer-events-none"></div>
</div>

<style>
    button {
        cursor: pointer;
        outline: none;
    }
    button:active:not(:disabled) {
        transform: scale(0.95);
    }
</style>