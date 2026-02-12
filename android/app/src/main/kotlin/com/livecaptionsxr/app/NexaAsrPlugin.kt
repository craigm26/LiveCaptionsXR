package com.livecaptionsxr.app

import android.content.Context
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/**
 * Flutter plugin for Nexa SDK device detection and NPU availability.
 *
 * This plugin provides device information for determining optimal inference mode:
 * - NPU availability detection for Qualcomm Snapdragon devices
 * - Device hardware information for analytics
 *
 * The actual ASR inference is handled by the nexa_ai_flutter package.
 *
 * For the Qualcomm x Nexa On-Device AI Bounty Program.
 */
class NexaAsrPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        private const val TAG = "NexaAsrPlugin"
        private const val METHOD_CHANNEL = "live_captions_xr/nexa_asr"

        // Supported Snapdragon chipsets for NPU acceleration
        private val NPU_SUPPORTED_CHIPSETS = listOf(
            "SM8750",  // Snapdragon 8 Elite (aka 8 Gen 4)
            "SM8735",  // Snapdragon 8s Elite
            "SM8650",  // Snapdragon 8 Gen 3
            "SM8550",  // Snapdragon 8 Gen 2
            "SM8475",  // Snapdragon 8+ Gen 1
            "SM8450",  // Snapdragon 8 Gen 1
            "QRD8750", // Qualcomm Reference Design — 8 Elite
            "QRD8650", // Qualcomm Reference Design — 8 Gen 3
            "pineapple", // Codename for Snapdragon 8 Elite
            "kalama",    // Codename for Snapdragon 8 Gen 3
            "qcom",    // Generic Qualcomm identifier
            "Qualcomm", // Alternative Qualcomm identifier
            "elite"    // Snapdragon Elite series identifier
        )
    }

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        Log.d(TAG, "NexaAsrPlugin attached to Flutter engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        Log.d(TAG, "NexaAsrPlugin detached from Flutter engine")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isNpuAvailable" -> {
                result.success(isNpuAvailable())
            }
            "getDeviceInfo" -> {
                result.success(getDeviceInfo())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Check if NPU (Qualcomm Hexagon) is available on this device.
     */
    private fun isNpuAvailable(): Boolean {
        val chipset = getChipsetName()
        val hardware = Build.HARDWARE.lowercase()

        // Check if chipset matches known NPU-capable devices
        val chipsetSupported = NPU_SUPPORTED_CHIPSETS.any {
            chipset.contains(it, ignoreCase = true)
        }

        // Also check hardware string for Qualcomm indicators
        val hardwareSupported = hardware.contains("qcom") ||
                               hardware.contains("qualcomm") ||
                               hardware.contains("snapdragon") ||
                               hardware.contains("elite")

        val isSupported = chipsetSupported || hardwareSupported
        Log.d(TAG, "NPU availability check: chipset=$chipset, hardware=$hardware, supported=$isSupported")
        return isSupported
    }

    /**
     * Check if GPU acceleration is available.
     */
    private fun isGpuAvailable(): Boolean {
        // Most modern Android devices support GPU compute
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
    }

    /**
     * Get the chipset/SoC name from device info.
     */
    private fun getChipsetName(): String {
        return try {
            // Try to read from /proc/cpuinfo
            val cpuInfo = File("/proc/cpuinfo").readText()
            val hardwareLine = cpuInfo.lines().find { it.startsWith("Hardware") }
            hardwareLine?.substringAfter(":")?.trim() ?: Build.HARDWARE
        } catch (e: Exception) {
            Build.HARDWARE
        }
    }

    /**
     * Get device information for debugging and analytics.
     */
    private fun getDeviceInfo(): Map<String, Any> {
        val npuAvailable = isNpuAvailable()
        val gpuAvailable = isGpuAvailable()

        val currentInferenceMode = when {
            npuAvailable -> "NPU"
            gpuAvailable -> "GPU"
            else -> "CPU"
        }

        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "hardware" to Build.HARDWARE,
            "chipset" to getChipsetName(),
            "sdkVersion" to Build.VERSION.SDK_INT,
            "npuAvailable" to npuAvailable,
            "gpuAvailable" to gpuAvailable,
            "currentInferenceMode" to currentInferenceMode
        )
    }
}
