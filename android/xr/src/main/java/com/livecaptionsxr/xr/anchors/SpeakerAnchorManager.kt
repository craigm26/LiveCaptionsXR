package com.livecaptionsxr.xr.anchors

import com.google.ar.core.Pose
import com.livecaptionsxr.engine.bus.EngineEvent
import com.livecaptionsxr.engine.common.Direction
import com.livecaptionsxr.xr.model.XrSpeakerAnchor
import kotlin.math.cos
import kotlin.math.sin

interface HeadPoseProvider {
    fun currentHeadPose(): Pose
}

interface WorldRaycaster {
    fun raycast(targetPose: Pose): Pose?
}

class SpeakerAnchorManager(
    private val headPoseProvider: HeadPoseProvider,
    private val raycaster: WorldRaycaster,
    private val smoothingFactor: Float = 0.2f
) {

    private val anchors = linkedMapOf<String, XrSpeakerAnchor>()

    fun onSpeakerUpdate(event: EngineEvent.SpeakerUpdate) {
        val direction = event.state.direction ?: return
        val headPose = headPoseProvider.currentHeadPose()
        val targetPose = computeWorldPoseFromDirection(headPose, direction)
        val hitPose = raycaster.raycast(targetPose) ?: targetPose

        val existing = anchors[event.state.id.value]
        val updatedPose = smoothPose(existing?.worldPose, hitPose)
        anchors[event.state.id.value] = XrSpeakerAnchor(
            speakerId = event.state.id,
            worldPose = updatedPose,
            lastDirection = direction,
            lastText = event.state.lastText
        )
    }

    fun getAnchors(): Collection<XrSpeakerAnchor> = anchors.values.toList()

    private fun computeWorldPoseFromDirection(headPose: Pose, direction: Direction): Pose {
        val radiusMeters = 2f
        val azimuthRad = Math.toRadians(direction.azimuthDeg.toDouble())
        val elevationRad = Math.toRadians(direction.elevationDeg.toDouble())

        val forwardX = (cos(elevationRad) * sin(azimuthRad)).toFloat()
        val forwardY = sin(elevationRad).toFloat()
        val forwardZ = (cos(elevationRad) * cos(azimuthRad)).toFloat()

        val translation = floatArrayOf(
            forwardX * radiusMeters,
            forwardY * radiusMeters,
            forwardZ * radiusMeters
        )

        val worldTranslation = headPose.transformPoint(translation)
        return Pose(worldTranslation, headPose.rotationQuaternion)
    }

    private fun smoothPose(oldPose: Pose?, newPose: Pose): Pose {
        if (oldPose == null) return newPose
        val lerp = smoothingFactor.coerceIn(0f, 1f)
        val smoothedTranslation = FloatArray(3) { i ->
            (1 - lerp) * oldPose.translation[i] + lerp * newPose.translation[i]
        }
        val smoothedRotation = FloatArray(4) { i ->
            (1 - lerp) * oldPose.rotationQuaternion[i] + lerp * newPose.rotationQuaternion[i]
        }
        return Pose(smoothedTranslation, smoothedRotation)
    }
}
