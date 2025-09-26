package com.livecaptionsxr.app

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class StereoAudioCapturePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: Activity? = null
    private var audioRecord: AudioRecord? = null
    private val isRecording = AtomicBoolean(false)
    private var eventSink: EventChannel.EventSink? = null
    private val sampleRate = 16000
    private val bufferSize = AudioRecord.getMinBufferSize(
        sampleRate,
        AudioFormat.CHANNEL_IN_STEREO,
        AudioFormat.ENCODING_PCM_FLOAT
    )
    private val RECORD_AUDIO_PERMISSION = 2001

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "live_captions_xr/audio_capture_methods")
        eventChannel = EventChannel(binding.binaryMessenger, "live_captions_xr/audio_capture_events")
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startRecording" -> {
                if (ContextCompat.checkSelfPermission(activity!!, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(activity!!, arrayOf(Manifest.permission.RECORD_AUDIO), RECORD_AUDIO_PERMISSION)
                    result.error("PERMISSION_DENIED", "Microphone permission denied", null)
                    return
                }
                startRecording()
                result.success(null)
            }
            "stopRecording" -> {
                stopRecording()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private val captureExecutor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "StereoAudioCapture").apply { priority = Thread.NORM_PRIORITY }
    }

    private fun startRecording() {
        val activityRef = activity ?: return

        if (!isRecording.compareAndSet(false, true)) return

        val minBuffer = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_STEREO,
            AudioFormat.ENCODING_PCM_FLOAT
        )
        val safeBufferSize = (minBuffer * 2).coerceAtLeast(sampleRate / 5)

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_STEREO,
            AudioFormat.ENCODING_PCM_FLOAT,
            safeBufferSize
        )

        val record = audioRecord
        if (record?.state != AudioRecord.STATE_INITIALIZED) {
            isRecording.set(false)
            record?.release()
            audioRecord = null
            return
        }

        record.startRecording()

        captureExecutor.execute {
            val floatBuffer = FloatArray(safeBufferSize)
            val byteBuffer = ByteBuffer.allocateDirect(safeBufferSize * Float.SIZE_BYTES)
                .order(ByteOrder.LITTLE_ENDIAN)

            while (isRecording.get() && record.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                val read = record.read(floatBuffer, 0, floatBuffer.size, AudioRecord.READ_BLOCKING)
                if (read <= 0) continue

                val evenSamples = if (read % 2 == 0) read else read - 1
                if (evenSamples <= 0) continue

                byteBuffer.clear()
                for (i in 0 until evenSamples) {
                    byteBuffer.putFloat(floatBuffer[i])
                }

                val payload = ByteArray(byteBuffer.position())
                byteBuffer.flip()
                byteBuffer.get(payload)

                postToMainThread(activityRef.mainLooper) {
                    eventSink?.success(payload)
                }
            }

            record.stop()
            record.release()
            audioRecord = null
            isRecording.set(false)
        }
    }

    private fun stopRecording() {
        if (isRecording.compareAndSet(true, false)) {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
        }
    }

    private inline fun postToMainThread(looper: Looper, crossinline block: () -> Unit) {
        if (Looper.myLooper() == looper) {
            block()
        } else {
            Handler(looper).post { block() }
        }
    }

} 