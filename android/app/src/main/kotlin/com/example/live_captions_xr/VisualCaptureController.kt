package com.example.live_captions_xr

import android.app.Activity
import android.content.Context
import android.graphics.ImageFormat
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class VisualCaptureController(private val context: Context) {
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var imageReader: ImageReader? = null
    private val cameraManager: CameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    private val cameraThread = HandlerThread("CameraThread").apply { start() }
    private val cameraHandler = Handler(cameraThread.looper)
    private var isCameraInitialized = false

    fun initialize(callback: (Boolean, String?) -> Unit) {
        if (isCameraInitialized) {
            callback(true, "Camera already initialized.")
            return
        }
        try {
            val cameraId = cameraManager.cameraIdList.firstOrNull() ?: "No camera found"
            if (cameraId.isEmpty()) {
                callback(false, "No camera available.")
                return
            }

            imageReader = ImageReader.newInstance(640, 480, ImageFormat.JPEG, 1)

            val stateCallback = object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    cameraDevice = camera
                    createCaptureSession { success, error ->
                        if (success) {
                            isCameraInitialized = true
                            callback(true, "Camera initialized successfully.")
                        } else {
                            callback(false, error ?: "Failed to create capture session.")
                        }
                    }
                }

                override fun onDisconnected(camera: CameraDevice) {
                    release()
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    release()
                    callback(false, "Camera error: $error")
                }
            }

            cameraManager.openCamera(cameraId, stateCallback, cameraHandler)
        } catch (e: CameraAccessException) {
            callback(false, "Camera access error: ${e.message}")
        } catch (e: SecurityException) {
            callback(false, "Camera permission not granted: ${e.message}")
        }
    }

    fun captureSnapshot(result: MethodChannel.Result) {
        if (!isCameraInitialized || cameraDevice == null || captureSession == null) {
            result.error("CAMERA_NOT_INITIALIZED", "Camera is not ready.", null)
            return
        }

        try {
            val readerListener = object : ImageReader.OnImageAvailableListener {
                override fun onImageAvailable(reader: ImageReader) {
                    val image = reader.acquireLatestImage()
                    val buffer = image.planes[0].buffer
                    val bytes = ByteArray(buffer.remaining())
                    buffer.get(bytes)
                    val outputStream = ByteArrayOutputStream()
                    outputStream.write(bytes)
                    result.success(outputStream.toByteArray())
                    image.close()
                }
            }

            imageReader?.setOnImageAvailableListener(readerListener, cameraHandler)

            val captureBuilder = cameraDevice!!.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
            captureBuilder.addTarget(imageReader!!.surface)

            captureSession?.capture(captureBuilder.build(), null, cameraHandler)
        } catch (e: CameraAccessException) {
            result.error("CAPTURE_ERROR", "Failed to capture image: ${e.message}", null)
        }
    }

    private fun createCaptureSession(callback: (Boolean, String?) -> Unit) {
        try {
            val surfaces = listOf(imageReader?.surface)
            cameraDevice?.createCaptureSession(surfaces, object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    captureSession = session
                    callback(true, null)
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    callback(false, "Failed to configure camera session.")
                }
            }, cameraHandler)
        } catch (e: CameraAccessException) {
            callback(false, "Error creating capture session: ${e.message}")
        }
    }

    fun release() {
        isCameraInitialized = false
        captureSession?.close()
        captureSession = null
        cameraDevice?.close()
        cameraDevice = null
        imageReader?.close()
        imageReader = null
    }

    fun close() {
        release()
        cameraThread.quitSafely()
    }
}
