package com.livecaptionsxr.engine.diarization

import com.livecaptionsxr.engine.common.AudioFrame
import com.livecaptionsxr.engine.common.SpeakerId
import kotlin.math.sqrt

interface DiarizationEngine {
    fun onSpeechFrame(frame: AudioFrame): SpeakerId
}

interface SpeakerEmbedder {
    fun embed(frame: AudioFrame): FloatArray
}

class OnlineDiarizationEngine(
    private val embedder: SpeakerEmbedder,
    private val threshold: Float = 0.25f
) : DiarizationEngine {

    private val clusters = linkedMapOf<SpeakerId, FloatArray>()

    override fun onSpeechFrame(frame: AudioFrame): SpeakerId {
        val embedding = embedder.embed(frame)
        val (bestId, bestDistance) = clusters
            .map { it.key to cosineDistance(it.value, embedding) }
            .minByOrNull { it.second } ?: (null to Float.MAX_VALUE)

        return if (bestId == null || bestDistance > threshold) {
            val newId = SpeakerId("spk_${clusters.size + 1}")
            clusters[newId] = embedding
            newId
        } else {
            val updated = blend(clusters.getValue(bestId), embedding)
            clusters[bestId] = updated
            bestId
        }
    }

    private fun cosineDistance(a: FloatArray, b: FloatArray): Float {
        val dot = a.indices.fold(0.0) { acc, i -> acc + a[i] * b[i] }
        val magA = sqrt(a.fold(0.0) { acc, value -> acc + value * value })
        val magB = sqrt(b.fold(0.0) { acc, value -> acc + value * value })
        if (magA == 0.0 || magB == 0.0) return 1f
        val similarity = (dot / (magA * magB)).toFloat().coerceIn(-1f, 1f)
        return 1f - similarity
    }

    private fun blend(current: FloatArray, incoming: FloatArray, alpha: Float = 0.2f): FloatArray {
        val result = FloatArray(current.size)
        for (i in current.indices) {
            result[i] = (1 - alpha) * current[i] + alpha * incoming[i]
        }
        return result
    }
}
