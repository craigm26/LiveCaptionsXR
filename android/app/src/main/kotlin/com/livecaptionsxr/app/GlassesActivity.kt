package com.livecaptionsxr.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.lifecycleScope
import androidx.xr.compose.spatial.Subspace
import androidx.xr.glimmer.GlimmerTheme
import androidx.xr.glimmer.components.Button
import androidx.xr.glimmer.components.Card
import androidx.xr.glimmer.components.Text
import androidx.xr.glimmer.surface
import androidx.xr.projected.ExperimentalProjectedApi
import androidx.xr.projected.ProjectedDeviceController
import androidx.xr.projected.ProjectedDeviceController.Companion.CAPABILITY_VISUAL_UI
import androidx.xr.projected.ProjectedDisplayController
import androidx.xr.projected.permissions.ProjectedPermissionsRequestParams
import androidx.xr.projected.permissions.ProjectedPermissionsResultContract
import kotlinx.coroutines.launch

/**
 * Native Android activity for Samsung XR AI Glasses, following the official
 * Jetpack XR SDK projected activity pattern.
 *
 * This activity:
 * - Uses ProjectedDisplayController/ProjectedDeviceController for glasses hardware
 * - Requests permissions via ProjectedPermissionsResultContract (not standard Android)
 * - Runs on-device ASR via SpeechRecognizer.createOnDeviceSpeechRecognizer()
 * - Displays captions using GlimmerTheme + Jetpack Compose
 * - Receives forwarded captions from Flutter via CaptionBridge
 * - Supports audio-only fallback for glasses without displays
 *
 * @see <a href="https://developer.android.com/develop/xr/jetpack-xr-sdk/ai-glasses/first-activity">Official docs</a>
 */
@OptIn(ExperimentalProjectedApi::class)
class GlassesActivity : ComponentActivity() {

    companion object {
        private const val TAG = "GlassesActivity"
    }

    private var displayController: ProjectedDisplayController? = null
    private var isVisualUiSupported by mutableStateOf(false)
    private var areVisualsOn by mutableStateOf(true)
    private var isPermissionDenied by mutableStateOf(false)

    // On-device ASR
    private var speechRecognizer: SpeechRecognizer? = null
    private var asrText by mutableStateOf("")
    private var isListening by mutableStateOf(false)

    // Register the permissions launcher using ProjectedPermissionsResultContract
    // per official docs — standard Android permission APIs do NOT work on glasses.
    private val requestPermissionLauncher: ActivityResultLauncher<List<ProjectedPermissionsRequestParams>> =
        registerForActivityResult(ProjectedPermissionsResultContract()) { results ->
            val cameraGranted = results[Manifest.permission.CAMERA] == true
            val audioGranted = results[Manifest.permission.RECORD_AUDIO] == true

            if (cameraGranted && audioGranted) {
                isPermissionDenied = false
                initializeGlassesFeatures()
            } else {
                isPermissionDenied = true
                Log.w(TAG, "Permissions denied: camera=$cameraGranted, audio=$audioGranted")
            }
        }

    // On-device ASR recognition listener
    private val recognitionListener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            Log.d(TAG, "ASR ready for speech")
            isListening = true
        }

        override fun onBeginningOfSpeech() {
            Log.d(TAG, "ASR speech begun")
        }

        override fun onRmsChanged(rmsdB: Float) {
            // Audio level change — no action needed
        }

        override fun onBufferReceived(buffer: ByteArray?) {
            // Raw audio buffer — no action needed
        }

        override fun onEndOfSpeech() {
            Log.d(TAG, "ASR speech ended")
            isListening = false
        }

        override fun onError(error: Int) {
            Log.e(TAG, "ASR error: $error")
            isListening = false
            // Restart listening on transient errors
            if (error == SpeechRecognizer.ERROR_NO_MATCH ||
                error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT) {
                startAsrListening()
            }
        }

        override fun onResults(results: Bundle?) {
            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            val confidences = results?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)

            if (matches != null && confidences != null && confidences.isNotEmpty()) {
                val bestIndex = confidences.indices.maxByOrNull { confidences[it] }
                if (bestIndex != null) {
                    val spokenText = matches[bestIndex]
                    Log.d(TAG, "ASR result: $spokenText (confidence=${confidences[bestIndex]})")
                    asrText = spokenText
                }
            } else if (matches != null && matches.isNotEmpty()) {
                asrText = matches[0]
            }

            // Continue listening for next utterance
            startAsrListening()
        }

        override fun onPartialResults(partialResults: Bundle?) {
            val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            if (matches != null && matches.isNotEmpty()) {
                asrText = matches[0]
            }
        }

        override fun onEvent(eventType: Int, params: Bundle?) {
            Log.d(TAG, "ASR event: $eventType")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "GlassesActivity onCreate")

        CaptionBridge.setGlassesActivityActive(true)

        // Clean up display controller on destroy via lifecycle observer
        lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onDestroy(owner: LifecycleOwner) {
                displayController?.close()
                displayController = null
            }
        })

        // Check permissions and initialize
        if (hasRequiredPermissions()) {
            initializeGlassesFeatures()
        } else {
            requestHardwarePermissions()
        }

        // Set Compose content with GlimmerTheme
        setContent {
            GlimmerTheme {
                GlassesCaptionScreen(
                    areVisualsOn = areVisualsOn,
                    isVisualUiSupported = isVisualUiSupported,
                    isPermissionDenied = isPermissionDenied,
                    asrText = asrText,
                    isListening = isListening,
                    onRetryPermission = { requestHardwarePermissions() },
                    onClose = { finish() }
                )
            }
        }
    }

    override fun onStart() {
        super.onStart()
        // Start ASR listening per official docs
        startAsrListening()
    }

    override fun onStop() {
        super.onStop()
        speechRecognizer?.stopListening()
        isListening = false
    }

    override fun onDestroy() {
        CaptionBridge.setGlassesActivityActive(false)
        speechRecognizer?.destroy()
        speechRecognizer = null
        super.onDestroy()
    }

    private fun initializeGlassesFeatures() {
        lifecycleScope.launch {
            try {
                // Check device capabilities
                val projectedDeviceController = ProjectedDeviceController.create(this@GlassesActivity)
                isVisualUiSupported = projectedDeviceController.capabilities.contains(CAPABILITY_VISUAL_UI)
                Log.d(TAG, "Visual UI supported: $isVisualUiSupported")

                // Initialize display controller for visual output
                val controller = ProjectedDisplayController.create(this@GlassesActivity)
                displayController = controller
                Log.d(TAG, "ProjectedDisplayController created")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize glasses features", e)
                // Fall back to audio-only mode
                isVisualUiSupported = false
            }

            // Initialize on-device ASR
            initializeSpeechRecognizer()
        }
    }

    private fun initializeSpeechRecognizer() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "RECORD_AUDIO permission not granted, skipping ASR init")
            return
        }

        try {
            speechRecognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
            speechRecognizer?.setRecognitionListener(recognitionListener)
            Log.d(TAG, "On-device SpeechRecognizer initialized")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create on-device SpeechRecognizer", e)
        }
    }

    private fun startAsrListening() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }

        try {
            speechRecognizer?.startListening(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start ASR listening", e)
        }
    }

    private fun hasRequiredPermissions(): Boolean {
        val cameraGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED
        val audioGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED
        return cameraGranted && audioGranted
    }

    private fun requestHardwarePermissions() {
        val params = ProjectedPermissionsRequestParams(
            permissions = listOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO),
            rationale = "Camera and microphone access are required to provide live spatial captions on your glasses."
        )
        requestPermissionLauncher.launch(listOf(params))
    }
}

/**
 * Compose UI for displaying captions on AI glasses.
 * Uses GlimmerTheme components designed for the glasses form factor.
 */
@Composable
fun GlassesCaptionScreen(
    areVisualsOn: Boolean,
    isVisualUiSupported: Boolean,
    isPermissionDenied: Boolean,
    asrText: String,
    isListening: Boolean,
    onRetryPermission: () -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Collect forwarded captions from Flutter via CaptionBridge
    val bridgeCaption by CaptionBridge.captionFlow.collectAsState()

    // Show ASR text if available, otherwise show forwarded caption
    val displayText = if (asrText.isNotEmpty()) asrText else bridgeCaption

    Box(
        modifier = modifier
            .surface(focusable = false)
            .fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        if (isPermissionDenied) {
            Card(
                title = { Text("Permission Required") },
                action = { Button(onClick = onClose) { Text("Exit") } }
            ) {
                Text("Camera and microphone access are needed for live captions on glasses.")
                Spacer(modifier = Modifier.height(8.dp))
                Button(onClick = onRetryPermission) { Text("Retry") }
            }
        } else if (isVisualUiSupported && areVisualsOn) {
            Card(
                title = { Text("Live Captions") },
                action = {
                    Button(onClick = onClose) {
                        Text("Close")
                    }
                }
            ) {
                if (displayText.isNotEmpty()) {
                    Text(
                        text = displayText,
                        fontSize = 24.sp,
                        modifier = Modifier.padding(16.dp)
                    )
                } else if (isListening) {
                    Text("Listening...")
                } else {
                    Text("Waiting for speech...")
                }
            }
        } else if (!isVisualUiSupported) {
            // Audio-only mode — no visual display on these glasses
            Text("Audio guidance mode active. Captions are processed in the background.")
        } else {
            // Visuals off
            Text("Display is off. Audio guidance active.")
        }
    }
}
