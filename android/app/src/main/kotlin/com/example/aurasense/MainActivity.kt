package com.example.livecaptionsxr

import android.Manifest
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.craig.livecaptions/visual"
    private lateinit var channel: MethodChannel
    private lateinit var visualSpeakerIdentifier: VisualSpeakerIdentifier

    private val CAMERA_PERMISSION_REQUEST_CODE = 100

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        visualSpeakerIdentifier = VisualSpeakerIdentifier(this, channel, this)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startDetection" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                        == PackageManager.PERMISSION_GRANTED) {
                        visualSpeakerIdentifier.startDetection()
                        result.success(null)
                    } else {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.CAMERA),
                            CAMERA_PERMISSION_REQUEST_CODE
                        )
                        result.error("CAMERA_PERMISSION_DENIED", "Camera permission is required.", null)
                    }
                }
                "stopDetection" -> {
                    visualSpeakerIdentifier.stopDetection()
                    result.success(null)
                }
                "captureFrame" -> {
                    // The captureFrame method is not implemented in the new VisualSpeakerIdentifier
                    // as the analysis is now done in a stream.
                    // This will need to be re-implemented if still required.
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                visualSpeakerIdentifier.startDetection()
            }
        }
    }
}
