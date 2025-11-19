package com.livecaptionsxr.engine.vad

import com.livecaptionsxr.engine.common.AudioFrame

interface VadEngine {
    fun isSpeech(frame: AudioFrame): Boolean
}

interface TfliteModel {
    fun predict(frame: AudioFrame): Float
}

class TfliteVadEngine(
    private val model: TfliteModel
) : VadEngine {
    override fun isSpeech(frame: AudioFrame): Boolean {
        return model.predict(frame) > 0.5f
    }
}
