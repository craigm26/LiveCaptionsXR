package com.livecaptionsxr.xr.model

import com.google.ar.core.Pose
import com.livecaptionsxr.engine.common.Direction
import com.livecaptionsxr.engine.common.SpeakerId

data class XrSpeakerAnchor(
    val speakerId: SpeakerId,
    val worldPose: Pose,
    val lastDirection: Direction?,
    val lastText: String
)
