package com.livecaptionsxr.engine.common

data class AudioFrame(
    val data: ShortArray,
    val channels: Int,
    val sampleRateHz: Int,
    val timestampUs: Long
)

@JvmInline
value class SpeakerId(val value: String)

data class Direction(
    val azimuthDeg: Float,
    val elevationDeg: Float,
    val confidence: Float
)

data class CaptionDelta(
    val speaker: SpeakerId?,
    val text: String,
    val isFinal: Boolean,
    val timestampUs: Long
)

data class SpeakerState(
    val id: SpeakerId,
    val direction: Direction?,
    val lastText: String,
    val isSpeaking: Boolean,
    val lastUpdatedUs: Long
)
