<script lang="ts">
    // ////////////////////////////////////////////////////////////
    // // START COOZILA - STUDIO HEADER                          //
    // ////////////////////////////////////////////////////////////
    
    import { onMount, getContext } from 'svelte';
    const i18n = getContext('i18n');

    // Importăm stările globale din WebUI pentru a respecta tema (Dark/Light)
    import { settings, theme } from '$lib/stores';

    let activeTab = 'canvas';

    // Funcție pentru stilizarea tab-urilor folosind design-ul nativ WebUI
    $: tabClass = (id: string) =>
        `flex-1 px-2 py-2 text-xs font-semibold transition-all rounded-lg ${
            activeTab === id
                ? 'bg-white dark:bg-gray-800 text-black dark:text-white shadow-sm ring-1 ring-gray-200 dark:ring-gray-700'
                : 'text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'
        }`;

    onMount(() => {
        console.log("Coozila Studio: Componentă montată cu succes.");
    });
</script>

<div class="flex flex-col h-full w-full text-gray-900 dark:text-gray-100 font-primary">
    
    <div class="flex space-x-1 p-1 bg-gray-100/50 dark:bg-gray-900/50 rounded-xl mb-4 border border-gray-200 dark:border-gray-800">
        <button class={tabClass('canvas')} on:click={() => (activeTab = 'canvas')}>
            Canvas
        </button>
        <button class={tabClass('controls')} on:click={() => (activeTab = 'controls')}>
            Controale
        </button>
        <button class={tabClass('files')} on:click={() => (activeTab = 'files')}>
            Fișiere
        </button>
        <button class={tabClass('overview')} on:click={() => (activeTab = 'overview')}>
            Overview
        </button>
    </div>

    <div class="flex-1 overflow-y-auto custom-scrollbar">
        {#if activeTab === 'canvas'}
            <div class="w-full min-h-[400px] rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-950 p-4 shadow-inner">
                <div class="flex items-center justify-center h-full opacity-40 italic text-sm">
                    <p>Motorul Canvas este activ. Așteptare date...</p>
                </div>
            </div>
            
        {:else if activeTab === 'controls'}
            <div class="space-y-3 p-1">
                <div class="p-4 rounded-xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
                    <h3 class="text-sm font-bold mb-2">Parametri Studio</h3>
                    <p class="text-xs text-gray-500">Aici poți adăuga butoane sau slidere native.</p>
                </div>
            </div>

        {:else if activeTab === 'files'}
            <div class="p-4 text-center rounded-xl border border-dashed border-gray-300 dark:border-gray-700">
                <p class="text-xs text-gray-500 italic">Niciun fișier mapat în Studio încă.</p>
            </div>

        {:else if activeTab === 'overview'}
            <div class="p-4 bg-blue-500/5 border border-blue-500/20 rounded-xl">
                <h4 class="text-xs font-bold text-blue-600 dark:text-blue-400 mb-1">Status Proiect</h4>
                <p class="text-xs opacity-80">Studio-ul monitorizează fluxul de date din chat.</p>
            </div>
        {/if}
    </div>

    <div class="mt-4 pt-2 border-t border-gray-100 dark:border-gray-800 text-[10px] text-center opacity-30 tracking-widest uppercase">
        Coozila Engine v1.0
    </div>
</div>

<style>
    /* Scrollbar finuț pentru a se potrivi cu restul interfeței */
    .custom-scrollbar::-webkit-scrollbar {
        width: 4px;
    }
    .custom-scrollbar::-webkit-scrollbar-thumb {
        background: rgba(156, 163, 175, 0.2);
        border-radius: 10px;
    }
</style>