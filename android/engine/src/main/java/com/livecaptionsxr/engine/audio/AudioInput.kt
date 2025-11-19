package com.livecaptionsxr.engine.audio

import com.livecaptionsxr.engine.common.AudioFrame
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import java.util.concurrent.atomic.AtomicBoolean

interface AudioInput {
    suspend fun start()
    suspend fun stop()
    val frames: SharedFlow<AudioFrame>
}

class HeadsetMicInput(
    private val sampleRateHz: Int = 16_000,
    private val channels: Int = 4
) : AudioInput {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val _frames = MutableSharedFlow<AudioFrame>(extraBufferCapacity = 32)
    override val frames: SharedFlow<AudioFrame> = _frames.asSharedFlow()
    private val running = AtomicBoolean(false)

    override suspend fun start() {
        running.compareAndSet(false, true)
    }

    override suspend fun stop() {
        if (running.compareAndSet(true, false)) {
            scope.cancel()
        }
    }

    @Suppress("unused")
    fun emitSyntheticFrame(data: ShortArray, timestampUs: Long) {
        val frame = AudioFrame(
            data = data,
            channels = channels,
            sampleRateHz = sampleRateHz,
            timestampUs = timestampUs
        )
        _frames.tryEmit(frame)
    }
}
