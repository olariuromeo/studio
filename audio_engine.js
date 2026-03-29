// ----------------------------------------------------------------------------------#
//                                                                                   #
//   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
//   Coozila! Team    lab@coozila.com                                                #
//                                                                                   #
// ----------------------------------------------------------------------------------#

/**
 * Location: studio/audio_engine.js
 * Description: Advanced Rhythmic Analysis. Filters frequencies and detects 
 * normalized peaks for precise Wan 2.2 video synchronization.
 */

export class AudioEngine {
    constructor() {
        // We use a standard context for decoding, but OfflineContext for processing
        this.audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }

    /**
     * Main analysis pipeline
     */
    async analyze(file) {
        const arrayBuffer = await file.arrayBuffer();
        const decodedBuffer = await this.audioCtx.decodeAudioData(arrayBuffer);
        
        // 1. Process audio through a Low-Pass filter to find the "Beat" (Bass/Kick)
        const rhythmicBuffer = await this.filterRhythm(decodedBuffer);
        
        // 2. Extract peaks from the filtered data
        const peaks = this.extractPeaks(rhythmicBuffer);
        
        return {
            buffer: decodedBuffer, // Original for visualization
            peaks: peaks,          // Timestamps for sync
            duration: decodedBuffer.duration
        };
    }

    /**
     * Filters the audio to isolate frequencies below 150Hz (The Rhythm)
     */
    async filterRhythm(buffer) {
        const offlineCtx = new OfflineAudioContext(
            buffer.numberOfChannels,
            buffer.length,
            buffer.sampleRate
        );

        const source = offlineCtx.createBufferSource();
        source.buffer = buffer;

        // Low-pass filter to keep only the bass/drums
        const filter = offlineCtx.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = 150; 

        source.connect(filter);
        filter.connect(offlineCtx.destination);
        
        source.start();
        return await offlineCtx.startRendering();
    }

    /**
     * Detects normalized peaks to handle different volume levels
     */
    extractPeaks(buffer) {
        const rawData = buffer.getChannelData(0);
        const sampleRate = buffer.sampleRate;
        const peaks = [];
        
        // Find the maximum amplitude to calculate a relative threshold
        let maxAmp = 0;
        for (let i = 0; i < rawData.length; i++) {
            if (Math.abs(rawData[i]) > maxAmp) maxAmp = rawData[i];
        }

        // Set threshold at 85% of peak volume
        const threshold = maxAmp * 0.85;
        const minDistance = 0.25; // 250ms minimum between beats (prevents double-triggering)
        const step = Math.floor(sampleRate * 0.01); // 10ms resolution

        for (let i = 0; i < rawData.length; i += step) {
            const val = Math.abs(rawData[i]);
            if (val > threshold) {
                const timestamp = i / sampleRate;
                if (peaks.length === 0 || timestamp - peaks[peaks.length - 1] > minDistance) {
                    peaks.push(timestamp);
                }
            }
        }
        return peaks;
    }
}