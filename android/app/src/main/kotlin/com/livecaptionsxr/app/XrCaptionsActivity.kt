package com.livecaptionsxr.app

import android.app.Activity
import android.os.Bundle
import android.widget.TextView
import com.google.ar.core.Pose
import com.livecaptionsxr.engine.bus.EngineEvent
import com.livecaptionsxr.xr.anchors.HeadPoseProvider
import com.livecaptionsxr.xr.anchors.SpeakerAnchorManager
import com.livecaptionsxr.xr.anchors.WorldRaycaster
import com.livecaptionsxr.xr.ui.SimpleCaptionBubbleRenderer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

class XrCaptionsActivity : Activity() {

    private val app: LiveCaptionsApplication by lazy { application as LiveCaptionsApplication }
    private val headPoseProvider = object : HeadPoseProvider {
        override fun currentHeadPose(): Pose {
            return Pose(floatArrayOf(0f, 0f, 0f), floatArrayOf(0f, 0f, 0f, 1f))
        }
    }
    private val raycaster = object : WorldRaycaster {
        override fun raycast(targetPose: Pose): Pose? = null
    }

    private val anchorManager = SpeakerAnchorManager(headPoseProvider, raycaster)
    private val renderer = SimpleCaptionBubbleRenderer()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var job: Job? = null
    private lateinit var anchorSummary: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_xr_placeholder)
        anchorSummary = findViewById(R.id.anchor_summary)
        app.warmupEngine()
        observeAnchors()
    }

    private fun observeAnchors() {
        job?.cancel()
        job = scope.launch {
            app.eventBus.events.collect { event ->
                if (event is EngineEvent.SpeakerUpdate) {
                    anchorManager.onSpeakerUpdate(event)
                    updateUi()
                }
            }
        }
    }

    private fun updateUi() {
        val models = renderer.render(anchorManager.getAnchors())
        val summaryText = if (models.isEmpty()) {
            "Awaiting anchors..."
        } else {
            models.joinToString(separator = "\n") { model ->
                val distance = String.format("%.2f", model.distanceMeters)
                "${model.speakerLabel}: ${model.text} (${distance}m)"
            }
        }
        anchorSummary.text = summaryText
    }

    override fun onDestroy() {
        job?.cancel()
        scope.cancel()
        super.onDestroy()
    }
}
