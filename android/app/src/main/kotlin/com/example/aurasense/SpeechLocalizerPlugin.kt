package com.example.aurasense

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.jtransforms.fft.FloatFFT_1D
import kotlin.math.*

class SpeechLocalizerPlugin : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "live_captions_xr/speech_localizer")
            channel.setMethodCallHandler(SpeechLocalizerPlugin())
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "estimateDirection" -> {
                val args = call.arguments as? Map<*, *> ?: run {
                    result.error("INVALID_ARGUMENT", "Missing arguments", null)
                    return
                }
                val left = (args["left"] as? ByteArray)?.toFloatArray()
                val right = (args["right"] as? ByteArray)?.toFloatArray()
                val sampleRate = (args["sampleRate"] as? Double) ?: 16000.0
                val micDistance = (args["micDistance"] as? Double) ?: 0.08
                val soundSpeed = (args["soundSpeed"] as? Double) ?: 343.0
                if (left == null || right == null) {
                    result.error("INVALID_ARGUMENT", "Missing left or right channel", null)
                    return
                }
                val angle = estimateDirectionGccPhat(left, right, sampleRate, micDistance, soundSpeed)
                result.success(angle)
            }
            else -> result.notImplemented()
        }
    }

    private fun ByteArray.toFloatArray(): FloatArray {
        val floats = FloatArray(this.size / 4)
        for (i in floats.indices) {
            val bits = (this[i * 4].toInt() and 0xFF) or
                    ((this[i * 4 + 1].toInt() and 0xFF) shl 8) or
                    ((this[i * 4 + 2].toInt() and 0xFF) shl 16) or
                    ((this[i * 4 + 3].toInt() and 0xFF) shl 24)
            floats[i] = Float.fromBits(bits)
        }
        return floats
    }

    private fun estimateDirectionGccPhat(
        left: FloatArray, right: FloatArray,
        sampleRate: Double, micDistance: Double, soundSpeed: Double
    ): Double {
        val n = min(left.size, right.size)
        val N = 1 shl (ceil(log2(n.toDouble())).toInt())
        val leftPadded = left.copyOf(N)
        val rightPadded = right.copyOf(N)
        val leftFFT = FloatArray(2 * N)
        val rightFFT = FloatArray(2 * N)
        for (i in 0 until N) {
            leftFFT[2 * i] = leftPadded[i]
            rightFFT[2 * i] = rightPadded[i]
        }
        val fft = FloatFFT_1D(N.toLong())
        fft.realForwardFull(leftFFT)
        fft.realForwardFull(rightFFT)
        val cross = FloatArray(2 * N)
        for (i in 0 until N) {
            val lr = leftFFT[2 * i] * rightFFT[2 * i] + leftFFT[2 * i + 1] * rightFFT[2 * i + 1]
            val li = leftFFT[2 * i + 1] * rightFFT[2 * i] - leftFFT[2 * i] * rightFFT[2 * i + 1]
            val mag = sqrt(lr * lr + li * li)
            if (mag > 1e-8) {
                cross[2 * i] = lr / mag
                cross[2 * i + 1] = li / mag
            }
        }
        fft.complexInverse(cross, true)
        var maxVal = cross[0]
        var maxIdx = 0
        for (i in 1 until N) {
            if (cross[2 * i] > maxVal) {
                maxVal = cross[2 * i]
                maxIdx = i
            }
        }
        var delay = maxIdx
        if (delay > N / 2) delay -= N
        val timeDelay = delay / sampleRate
        val maxDelay = micDistance / soundSpeed
        val clamped = timeDelay / maxDelay
        return asin(clamped.coerceIn(-1.0, 1.0))
    }
} 