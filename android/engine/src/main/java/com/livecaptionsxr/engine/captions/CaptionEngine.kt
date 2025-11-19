package com.livecaptionsxr.engine.captions

import com.livecaptionsxr.engine.audio.AudioInput
import com.livecaptionsxr.engine.asr.AsrEngine
import com.livecaptionsxr.engine.bus.EngineEvent
import com.livecaptionsxr.engine.bus.EngineEventBus
import com.livecaptionsxr.engine.common.CaptionDelta
import com.livecaptionsxr.engine.common.SpeakerId
import com.livecaptionsxr.engine.common.SpeakerState
import com.livecaptionsxr.engine.diarization.DiarizationEngine
import com.livecaptionsxr.engine.localization.LocalizationEngine
import com.livecaptionsxr.engine.vad.VadEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.util.concurrent.atomic.AtomicBoolean

class CaptionEngine(
    private val audioInput: AudioInput,
    private val vad: VadEngine,
    private val diarization: DiarizationEngine,
    private val localization: LocalizationEngine,
    private val asr: AsrEngine,
    private val bus: EngineEventBus
) {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val isRunning = AtomicBoolean(false)
    private val speakerStates = mutableMapOf<SpeakerId, SpeakerState>()
    private val stateMutex = Mutex()
    private var pipeline: Job? = null

    fun start() {
        if (!isRunning.compareAndSet(false, true)) return
        pipeline = scope.launch {
            try {
                audioInput.start()
                coroutineScope {
                    launchAudioLoop()
                    launchCaptionLoop()
                }
            } finally {
                audioInput.stop()
                isRunning.set(false)
            }
        }
    }

    suspend fun awaitStop() {
        pipeline?.cancelAndJoin()
    }

    fun stop() {
        pipeline?.cancel()
        pipeline = null
    }

    private fun CoroutineScope.launchAudioLoop() = launch {
        audioInput.frames.collect { frame ->
            if (!vad.isSpeech(frame)) return@collect

            val speakerId = diarization.onSpeechFrame(frame)
            val dir = localization.estimateDirection(frame)

            val updated = stateMutex.withLock {
                val previous = speakerStates[speakerId]
                val next = (previous ?: SpeakerState(
                    id = speakerId,
                    direction = dir,
                    lastText = "",
                    isSpeaking = true,
                    lastUpdatedUs = frame.timestampUs
                )).copy(
                    direction = dir ?: previous?.direction,
                    isSpeaking = true,
                    lastUpdatedUs = frame.timestampUs
                )
                speakerStates[speakerId] = next
                next
            }

            bus.emit(EngineEvent.SpeakerUpdate(updated))
            asr.pushAudio(frame)
        }
    }

    private fun CoroutineScope.launchCaptionLoop() = launch {
        asr.captions.collectLatest { delta ->
            val speaker = delta.speaker ?: inferSpeakerFromLastActivity()
            val updated = stateMutex.withLock {
                val previous = speakerStates[speaker]
                val mergedText = if (delta.isFinal) {
                    listOfNotNull(previous?.lastText, delta.text).joinToString(" ").trim()
                } else {
                    delta.text
                }
                val next = (previous ?: SpeakerState(
                    id = speaker,
                    direction = previous?.direction,
                    lastText = "",
                    isSpeaking = true,
                    lastUpdatedUs = delta.timestampUs
                )).copy(
                    lastText = mergedText,
                    lastUpdatedUs = delta.timestampUs
                )
                speakerStates[speaker] = next
                next
            }

            bus.emit(EngineEvent.SpeakerUpdate(updated))
            val emittedDelta = if (delta.speaker == null) {
                delta.copy(speaker = speaker)
            } else delta
            bus.emit(EngineEvent.CaptionUpdate(emittedDelta))
        }
    }

    private suspend fun inferSpeakerFromLastActivity(): SpeakerId {
        return stateMutex.withLock {
            speakerStates.maxByOrNull { it.value.lastUpdatedUs }?.key
                ?: SpeakerId("unknown")
        }
    }
}
