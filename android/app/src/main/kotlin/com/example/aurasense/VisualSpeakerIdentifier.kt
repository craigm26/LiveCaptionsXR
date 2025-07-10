package com.example.livecaptionsxr

import android.annotation.SuppressLint
import android.content.Context
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class VisualSpeakerIdentifier(
    private val context: Context,
    private val channel: MethodChannel,
    private val lifecycleOwner: LifecycleOwner
) {

    private lateinit var cameraExecutor: ExecutorService
    private lateinit var faceDetector: FaceDetector
    private var cameraProvider: ProcessCameraProvider? = null

    fun startDetection() {
        cameraExecutor = Executors.newSingleThreadExecutor()
        val faceDetectorOptions = FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_NONE)
            .build()
        faceDetector = FaceDetection.getClient(faceDetectorOptions)

        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            bindCameraUseCases()
        }, ContextCompat.getMainExecutor(context))
    }

    fun stopDetection() {
        cameraExecutor.shutdown()
        cameraProvider?.unbindAll()
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun bindCameraUseCases() {
        val cameraSelector = CameraSelector.Builder()
            .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
            .build()

        val preview = Preview.Builder().build()

        val imageAnalyzer = ImageAnalysis.Builder()
            .build()
            .also {
                it.setAnalyzer(cameraExecutor, { imageProxy ->
                    val mediaImage = imageProxy.image
                    if (mediaImage != null) {
                        val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
                        detectFaces(image)
                    }
                    imageProxy.close()
                })
            }

        try {
            cameraProvider?.unbindAll()
            cameraProvider?.bindToLifecycle(
                lifecycleOwner,
                cameraSelector,
                preview,
                imageAnalyzer
            )
        } catch (exc: Exception) {
            // Log the error
        }
    }

    private fun detectFaces(image: InputImage) {
        faceDetector.process(image)
            .addOnSuccessListener { faces ->
                var activeSpeaker: Face? = null
                var maxMouthMovement = 0.0f

                for (face in faces) {
                    val mouthMovement = calculateMouthMovement(face)
                    if (mouthMovement > maxMouthMovement) {
                        maxMouthMovement = mouthMovement
                        activeSpeaker = face
                    }
                }

                if (maxMouthMovement > 0.1) {
                    reportSpeakerUpdate(activeSpeaker)
                } else {
                    reportSpeakerUpdate(null)
                }
            }
            .addOnFailureListener { e ->
                // Log the error
            }
    }

    private fun calculateMouthMovement(face: Face): Float {
        val upperLipBottom = face.getLandmark(com.google.mlkit.vision.face.FaceLandmark.MOUTH_UPPER_LIP_BOTTOM)?.position
        val lowerLipTop = face.getLandmark(com.google.mlkit.vision.face.FaceLandmark.MOUTH_LOWER_LIP_TOP)?.position

        if (upperLipBottom != null && lowerLipTop != null) {
            return Math.abs(upperLipBottom.y - lowerLipTop.y)
        }
        return 0.0f
    }

    private fun reportSpeakerUpdate(speaker: Face?) {
        if (speaker == null) {
            channel.invokeMethod("onSpeakerUpdated", null)
            return
        }

        val boundingBox = speaker.boundingBox
        val arguments: Map<String, Any> = mapOf(
            "x" to boundingBox.left.toDouble(),
            "y" to boundingBox.top.toDouble(),
            "width" to boundingBox.width().toDouble(),
            "height" to boundingBox.height().toDouble(),
            "confidence" to 1.0 // ML Kit doesn't provide a confidence score for faces
        )
        channel.invokeMethod("onSpeakerUpdated", arguments)
    }
}
