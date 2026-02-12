package com.example.nexa_ai_flutter

import android.os.Build

class DeviceCapabilityChecker {

    companion object {
        // Chipsets with NPU support (Hexagon)
        private val NPU_SUPPORTED_CHIPSETS = setOf(
            "SM8650",  // Snapdragon 8 Gen 3
            "SM8750",  // Snapdragon 8 Gen 4
            "SM8850",  // Snapdragon 8 Gen 5 (future)
        )

        // Map model IDs to their required capabilities
        private val MODEL_REQUIREMENTS = mapOf(
            "OmniNeural-4B" to "npu",
            "paddleocr-npu" to "npu",
            "parakeet-tdt-0.6b-v3-npu" to "npu",
            "embeddinggemma-300m-npu" to "npu",
            "jina-v2-rerank-npu" to "npu",
            "LFM2-1.2B-npu" to "npu",
            "SmolVLM-256M-Instruct-f16" to "cpu_gpu",
            "LFM2-1.2B-GGUF-GGUF" to "cpu_gpu"
        )

        // Performance ratings for different chipsets
        private val CHIPSET_PERFORMANCE = mapOf(
            // Flagship (Fast)
            "SM8650" to "fast",  // Snapdragon 8 Gen 3
            "SM8750" to "fast",  // Snapdragon 8 Gen 4
            "SM8550" to "fast",  // Snapdragon 8 Gen 2

            // High-end (Medium-Fast)
            "SM8450" to "medium",  // Snapdragon 8 Gen 1
            "SM8350" to "medium",  // Snapdragon 888
            "SM8250" to "medium",  // Snapdragon 865
            "SM7550" to "medium",  // Snapdragon 7 Gen 3

            // Mid-range (Medium)
            "SM7450" to "medium",  // Snapdragon 7+ Gen 2
            "SM7325" to "medium",  // Snapdragon 778G
            "SM7350" to "medium",  // Snapdragon 780G
            "SM8150" to "medium",  // Snapdragon 855
            "SM7250" to "slow",    // Snapdragon 765

            // Older/Lower-end (Slow)
            "SM6375" to "slow",    // Snapdragon 695
            "SM6350" to "slow",    // Snapdragon 690
            "SM7125" to "slow",    // Snapdragon 720G
        )
    }

    fun getDeviceInfo(): Map<String, Any> {
        val chipset = getChipset()
        val hasNpu = hasNpuSupport(chipset)
        val hasGpu = true  // All modern Android devices have GPU
        val hasCpu = true

        return mapOf(
            "deviceModel" to Build.MODEL,
            "deviceManufacturer" to Build.MANUFACTURER,
            "chipset" to chipset,
            "androidVersion" to Build.VERSION.SDK_INT,
            "hasNpu" to hasNpu,
            "hasGpu" to hasGpu,
            "hasCpu" to hasCpu,
            "supportedPlugins" to getSupportedPlugins(hasNpu),
            "performanceLevel" to getPerformanceLevel(chipset)
        )
    }

    fun checkModelCompatibility(modelId: String): Map<String, Any> {
        val chipset = getChipset()
        val hasNpu = hasNpuSupport(chipset)
        val requiredPlugin = MODEL_REQUIREMENTS[modelId] ?: "cpu_gpu"
        val performanceLevel = getPerformanceLevel(chipset)

        val isCompatible = when (requiredPlugin) {
            "npu" -> hasNpu
            "cpu_gpu" -> true  // CPU/GPU always available
            else -> false
        }

        val expectedSpeed = when {
            !isCompatible -> "not_supported"
            requiredPlugin == "npu" && hasNpu -> "fast"
            requiredPlugin == "cpu_gpu" -> performanceLevel
            else -> "slow"
        }

        val recommendation = when {
            !isCompatible -> "This model requires NPU support. Your device doesn't have NPU. Try CPU/GPU models instead."
            expectedSpeed == "fast" -> "Recommended - Will run smoothly on your device"
            expectedSpeed == "medium" -> "Compatible - Will run with acceptable performance"
            expectedSpeed == "slow" -> "Compatible but may be slow - Consider using a smaller model"
            else -> "Not supported on your device"
        }

        return mapOf(
            "modelId" to modelId,
            "isCompatible" to isCompatible,
            "requiredPlugin" to requiredPlugin,
            "availablePlugin" to if (hasNpu) "npu" else "cpu_gpu",
            "expectedSpeed" to expectedSpeed,
            "recommendation" to recommendation,
            "chipset" to chipset,
            "hasNpu" to hasNpu
        )
    }

    private fun getChipset(): String {
        // Try to get chipset from system properties
        return try {
            val process = Runtime.getRuntime().exec("getprop ro.board.platform")
            val chipset = process.inputStream.bufferedReader().readText().trim()
            if (chipset.isNotEmpty()) chipset else Build.HARDWARE
        } catch (e: Exception) {
            Build.HARDWARE
        }
    }

    private fun hasNpuSupport(chipset: String): Boolean {
        return NPU_SUPPORTED_CHIPSETS.contains(chipset)
    }

    private fun getSupportedPlugins(hasNpu: Boolean): List<String> {
        return if (hasNpu) {
            listOf("npu", "cpu_gpu")
        } else {
            listOf("cpu_gpu")
        }
    }

    private fun getPerformanceLevel(chipset: String): String {
        return CHIPSET_PERFORMANCE[chipset] ?: "medium"
    }
}
