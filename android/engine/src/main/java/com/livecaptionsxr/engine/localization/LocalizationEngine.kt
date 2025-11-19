package com.livecaptionsxr.engine.localization

import android.util.Log
import com.livecaptionsxr.engine.common.AudioFrame
import com.livecaptionsxr.engine.common.Direction

interface LocalizationEngine {
    fun estimateDirection(frame: AudioFrame): Direction?
}

class NativeLocalizationEngine : LocalizationEngine {

    private val nativeReady = runCatching {
        System.loadLibrary("loc_native")
        true
    }.getOrElse {
        Log.w("NativeLocalization", "loc_native unavailable: ${it.message}")
        false
    }

    external fun nativeEstimateDirection(
        pcm: ShortArray,
        channels: Int,
        sampleRateHz: Int
    ): FloatArray?

    override fun estimateDirection(frame: AudioFrame): Direction? {
        if (!nativeReady) return null
        val result = nativeEstimateDirection(frame.data, frame.channels, frame.sampleRateHz) ?: return null
        return Direction(
            azimuthDeg = result.getOrElse(0) { 0f },
            elevationDeg = result.getOrElse(1) { 0f },
            confidence = result.getOrElse(2) { 0f }
        )
    }
}
