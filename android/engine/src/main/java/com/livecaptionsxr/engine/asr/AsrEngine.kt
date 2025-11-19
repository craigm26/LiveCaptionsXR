package com.livecaptionsxr.engine.asr

import com.livecaptionsxr.engine.common.AudioFrame
import com.livecaptionsxr.engine.common.CaptionDelta
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

interface AsrEngine {
    fun pushAudio(frame: AudioFrame)
    val captions: SharedFlow<CaptionDelta>
}

interface AsrBackend {
    fun feed(frame: AudioFrame, onResult: (CaptionDelta) -> Unit)
}

class StreamingAsrEngine(
    private val backend: AsrBackend
) : AsrEngine {

    private val _captions = MutableSharedFlow<CaptionDelta>(extraBufferCapacity = 32)
    override val captions: SharedFlow<CaptionDelta> = _captions.asSharedFlow()

    override fun pushAudio(frame: AudioFrame) {
        backend.feed(frame) { delta ->
            _captions.tryEmit(delta)
        }
    }
}
