package com.livecaptionsxr.xr.ui

import com.livecaptionsxr.xr.model.XrSpeakerAnchor
import kotlin.math.sqrt

data class CaptionBubbleUiModel(
    val speakerLabel: String,
    val text: String,
    val distanceMeters: Float
)

interface CaptionBubbleRenderer {
    fun render(anchors: Collection<XrSpeakerAnchor>): List<CaptionBubbleUiModel>
}

class SimpleCaptionBubbleRenderer : CaptionBubbleRenderer {
    override fun render(anchors: Collection<XrSpeakerAnchor>): List<CaptionBubbleUiModel> {
        return anchors.map { anchor ->
            val translation = anchor.worldPose.translation
            val x = translation[0].toDouble()
            val y = translation[1].toDouble()
            val z = translation[2].toDouble()
            val distance = sqrt(x * x + y * y + z * z).toFloat()
            CaptionBubbleUiModel(
                speakerLabel = anchor.speakerId.value,
                text = anchor.lastText.takeLast(200),
                distanceMeters = distance
            )
        }.sortedBy { it.distanceMeters }
    }
}
