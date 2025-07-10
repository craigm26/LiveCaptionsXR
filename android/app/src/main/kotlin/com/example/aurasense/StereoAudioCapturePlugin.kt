package com.example.aurasense

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.atomic.AtomicBoolean

class StereoAudioCapturePlugin(private val activity: Activity) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private var audioRecord: AudioRecord? = null
    private var recordingThread: Thread? = null
    private val isRecording = AtomicBoolean(false)
    private var eventSink: EventChannel.EventSink? = null
    private val sampleRate = 16000
    private val bufferSize = AudioRecord.getMinBufferSize(
        sampleRate,
        AudioFormat.CHANNEL_IN_STEREO,
        AudioFormat.ENCODING_PCM_16BIT
    )

    companion object {
        fun registerWith(registrar: Registrar) {
            val methodChannel = MethodChannel(registrar.messenger(), "live_captions_xr/audio_capture_methods")
            val eventChannel = EventChannel(registrar.messenger(), "live_captions_xr/audio_capture_events")
            val plugin = StereoAudioCapturePlugin(registrar.activity())
            methodChannel.setMethodCallHandler(plugin)
            eventChannel.setStreamHandler(plugin)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startRecording" -> startRecording(result)
            "stopRecording" -> stopRecording(result)
            else -> result.notImplemented()
        }
    }

    private fun startRecording(result: MethodChannel.Result) {
        if (isRecording.get()) {
            result.success(null)
            return
        }
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.RECORD_AUDIO), 1234)
            result.error("PERMISSION_DENIED", "Microphone permission denied", null)
            return
        }
        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_STEREO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize
        )
        audioRecord?.startRecording()
        isRecording.set(true)
        recordingThread = Thread {
            val buffer = ShortArray(bufferSize)
            while (isRecording.get()) {
                val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                if (read > 0) {
                    // Convert PCM16 stereo to float32 interleaved
                    val floatBuffer = FloatArray(read)
                    for (i in 0 until read) {
                        floatBuffer[i] = buffer[i] / 32768.0f
                    }
                    // Convert to byte array for Dart
                    val byteBuffer = ByteBuffer.allocate(floatBuffer.size * 4).order(ByteOrder.LITTLE_ENDIAN)
                    for (f in floatBuffer) byteBuffer.putFloat(f)
                    eventSink?.success(byteBuffer.array())
                }
            }
        }
        recordingThread?.start()
        result.success(null)
    }

    private fun stopRecording(result: MethodChannel.Result) {
        if (!isRecording.get()) {
            result.success(null)
            return
        }
        isRecording.set(false)
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        recordingThread = null
        result.success(null)
    }
} 