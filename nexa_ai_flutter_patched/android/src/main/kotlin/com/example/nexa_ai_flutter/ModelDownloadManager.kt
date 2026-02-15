package com.example.nexa_ai_flutter

import android.content.Context
import android.content.SharedPreferences
import android.os.StatFs
import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.TimeUnit

data class ModelFile(
    val name: String,
    val path: String,
    val url: String
)

data class ModelData(
    val id: String,
    val displayName: String,
    val modelName: String,
    val mmprojOrTokenName: String,
    val sizeGb: Double,
    val params: String,
    val features: List<String>?,
    val type: String,
    val versionCode: Int = 0,
    val modelUrl: String? = null,
    val mmprojOrTokenUrl: String? = null,
    val files: List<ModelFile>?
)

class ModelDownloadManager(private val context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("nexa_downloads", Context.MODE_PRIVATE)

    private val gson = Gson()
    private val okHttpClient = OkHttpClient.Builder()
        .connectTimeout(60, TimeUnit.SECONDS)
        .readTimeout(5, TimeUnit.MINUTES)
        .writeTimeout(60, TimeUnit.SECONDS)
        .build()

    // Separate client for HEAD requests with short timeouts
    private val headClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .writeTimeout(10, TimeUnit.SECONDS)
        .build()

    private val downloadJobs = mutableMapOf<String, Job>()

    companion object {
        private const val TAG = "ModelDownloadManager"
        private const val SP_KEY_PREFIX = "model_downloaded_"
        private const val ONE_GB = 1_073_741_824L
    }

    fun getModelsDirectory(): File {
        val dir = File(context.filesDir, "models")
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }

    fun getModelDirectory(modelId: String, versionCode: Int): File {
        val baseDir = getModelsDirectory()
        val dir = if (versionCode == 1) {
            File(baseDir, modelId)
        } else {
            baseDir
        }
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }

    fun getAvailableModels(): List<Map<String, Any>> {
        val modelListJson = context.assets.open("model_list.json").bufferedReader().use { it.readText() }
        val listType = object : TypeToken<List<ModelData>>() {}.type
        val models = gson.fromJson<List<ModelData>>(modelListJson, listType)
        return models.map { model ->
            mapOf<String, Any>(
                "id" to model.id,
                "displayName" to model.displayName,
                "modelName" to model.modelName,
                "mmprojOrTokenName" to model.mmprojOrTokenName,
                "sizeGb" to model.sizeGb,
                "params" to model.params,
                "features" to (model.features ?: emptyList<String>()),
                "type" to model.type,
                "versionCode" to model.versionCode,
                "modelUrl" to (model.modelUrl ?: ""),
                "mmprojOrTokenUrl" to (model.mmprojOrTokenUrl ?: ""),
                "files" to (model.files ?: emptyList()).map { file ->
                    mapOf<String, Any>(
                        "name" to file.name,
                        "path" to file.path,
                        "url" to file.url
                    )
                }
            )
        }
    }

    fun isModelDownloaded(modelId: String): Boolean {
        return prefs.getBoolean(SP_KEY_PREFIX + modelId, false)
    }

    fun getModelPath(modelId: String): String? {
        if (!isModelDownloaded(modelId)) return null

        val modelListJson = context.assets.open("model_list.json").bufferedReader().use { it.readText() }
        val listType = object : TypeToken<List<ModelData>>() {}.type
        val models = gson.fromJson<List<ModelData>>(modelListJson, listType)
        val model = models.firstOrNull { it.id == modelId } ?: return null

        val modelDir = getModelDirectory(modelId, model.versionCode)
        val modelFile = File(modelDir, model.modelName)

        return if (modelFile.exists()) modelFile.absolutePath else null
    }

    suspend fun downloadModel(
        modelId: String,
        scope: CoroutineScope,
        eventSink: EventChannel.EventSink
    ) {
        val modelListJson = context.assets.open("model_list.json").bufferedReader().use { it.readText() }
        val listType = object : TypeToken<List<ModelData>>() {}.type
        val models = gson.fromJson<List<ModelData>>(modelListJson, listType)
        val model = models.firstOrNull { it.id == modelId }
            ?: throw Exception("Model not found: $modelId")

        Log.d(TAG, "Starting download for model: $modelId (${model.sizeGb} GB, ${model.type})")

        val modelDir = getModelDirectory(modelId, model.versionCode)

        // Get list of files to download
        val filesToDownload = mutableListOf<Pair<File, String>>()

        model.modelUrl?.takeIf { it.isNotEmpty() }?.let {
            filesToDownload.add(Pair(File(modelDir, model.modelName), it))
        }

        model.mmprojOrTokenUrl?.takeIf { it.isNotEmpty() }?.let {
            filesToDownload.add(Pair(File(modelDir, model.mmprojOrTokenName), it))
        }

        model.files?.forEach { fileData ->
            val filePath = if (fileData.path.isNotEmpty()) {
                File(modelDir, fileData.path + File.separator + fileData.name)
            } else {
                File(modelDir, fileData.name)
            }
            filePath.parentFile?.mkdirs()
            filesToDownload.add(Pair(filePath, fileData.url))
        }

        if (filesToDownload.isEmpty()) {
            throw Exception("No files to download for model: $modelId")
        }

        Log.d(TAG, "[$modelId] ${filesToDownload.size} files to download")

        // Calculate total size via HEAD requests
        var totalBytes = 0L
        for ((file, url) in filesToDownload) {
            val size = getFileSize(url)
            Log.d(TAG, "[$modelId] File size for ${file.name}: $size bytes")
            totalBytes += size
        }

        // Fallback: if HEAD requests all returned 0, estimate from sizeGb
        if (totalBytes == 0L && model.sizeGb > 0) {
            totalBytes = (model.sizeGb * ONE_GB).toLong()
            Log.w(TAG, "[$modelId] HEAD requests returned 0 total bytes, using estimated size: $totalBytes bytes (${model.sizeGb} GB)")
        }

        Log.d(TAG, "[$modelId] Total download size: $totalBytes bytes (${totalBytes / (1024 * 1024)} MB)")

        var downloadedBytes = 0L
        val startTime = System.currentTimeMillis()

        // Download files sequentially
        try {
            for ((index, pair) in filesToDownload.withIndex()) {
                val (file, url) = pair
                if (!downloadJobs.containsKey(modelId)) {
                    Log.d(TAG, "[$modelId] Download cancelled")
                    sendProgress(eventSink, modelId, downloadedBytes, totalBytes, "cancelled")
                    return
                }

                Log.d(TAG, "[$modelId] Downloading file ${index + 1}/${filesToDownload.size}: ${file.name}")

                val fileBytes = downloadFile(url, file) { currentBytes ->
                    val totalDownloaded = downloadedBytes + currentBytes
                    val elapsedMs = System.currentTimeMillis() - startTime
                    val speedMBps = if (elapsedMs > 0) {
                        (totalDownloaded / (1024.0 * 1024.0)) / (elapsedMs / 1000.0)
                    } else 0.0

                    scope.launch(Dispatchers.Main) {
                        sendProgress(eventSink, modelId, totalDownloaded, totalBytes, "downloading", speedMBps)
                    }
                }

                Log.d(TAG, "[$modelId] Completed file ${file.name}: $fileBytes bytes")
                downloadedBytes += fileBytes
            }

            // Verify all files exist and have non-zero size
            var allFilesValid = true
            for ((file, _) in filesToDownload) {
                if (!file.exists() || file.length() == 0L) {
                    Log.e(TAG, "[$modelId] Verification failed: ${file.name} (exists=${file.exists()}, size=${if (file.exists()) file.length() else 0})")
                    allFilesValid = false
                }
            }

            if (!allFilesValid) {
                Log.e(TAG, "[$modelId] Download verification failed - not all files are valid")
                scope.launch(Dispatchers.Main) {
                    sendProgress(eventSink, modelId, downloadedBytes, totalBytes, "failed", 0.0, "Download verification failed: some files are missing or empty")
                }
                return
            }

            // Mark as downloaded
            prefs.edit().putBoolean(SP_KEY_PREFIX + modelId, true).apply()
            val elapsedSec = (System.currentTimeMillis() - startTime) / 1000.0
            Log.d(TAG, "[$modelId] Download completed successfully: $downloadedBytes bytes in ${String.format("%.1f", elapsedSec)}s")

            scope.launch(Dispatchers.Main) {
                sendProgress(eventSink, modelId, downloadedBytes, totalBytes, "completed", 0.0)
            }

        } catch (e: Exception) {
            Log.e(TAG, "[$modelId] Download failed: ${e.message}", e)
            scope.launch(Dispatchers.Main) {
                sendProgress(eventSink, modelId, downloadedBytes, totalBytes, "failed", 0.0, e.message ?: "Unknown error")
            }
            throw e
        } finally {
            downloadJobs.remove(modelId)
        }
    }

    private fun getFileSize(url: String): Long {
        return try {
            val request = Request.Builder().url(url).head().build()
            headClient.newCall(request).execute().use { response ->
                val size = response.header("Content-Length")?.toLongOrNull() ?: 0L
                if (size == 0L) {
                    Log.w(TAG, "HEAD request returned 0 for: $url (HTTP ${response.code})")
                }
                size
            }
        } catch (e: Exception) {
            Log.w(TAG, "HEAD request failed for $url: ${e.message}")
            0L
        }
    }

    private fun downloadFile(url: String, destFile: File, onProgress: (Long) -> Unit): Long {
        val request = Request.Builder().url(url).build()

        okHttpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw Exception("Download failed: HTTP ${response.code} for ${destFile.name}")
            }

            val totalBytes = response.header("Content-Length")?.toLongOrNull() ?: 0L
            var downloadedBytes = 0L

            response.body?.byteStream()?.use { input ->
                FileOutputStream(destFile).use { output ->
                    val buffer = ByteArray(8192)
                    var read: Int

                    while (input.read(buffer).also { read = it } != -1) {
                        output.write(buffer, 0, read)
                        downloadedBytes += read
                        onProgress(downloadedBytes)
                    }
                }
            }

            return downloadedBytes
        }
    }

    private fun sendProgress(
        eventSink: EventChannel.EventSink,
        modelId: String,
        downloadedBytes: Long,
        totalBytes: Long,
        status: String,
        speedMBps: Double = 0.0,
        errorMessage: String? = null
    ) {
        val percentage = if (totalBytes > 0) {
            ((downloadedBytes * 100) / totalBytes).toInt()
        } else 0

        val progressMap = mutableMapOf<String, Any>(
            "modelId" to modelId,
            "downloadedBytes" to downloadedBytes,
            "totalBytes" to totalBytes,
            "percentage" to percentage,
            "speedMBps" to speedMBps,
            "status" to status
        )

        if (errorMessage != null) {
            progressMap["errorMessage"] = errorMessage
        }

        eventSink.success(progressMap)
    }

    fun cancelDownload(modelId: String) {
        downloadJobs[modelId]?.cancel()
        downloadJobs.remove(modelId)
    }

    fun deleteModel(modelId: String) {
        val modelListJson = context.assets.open("model_list.json").bufferedReader().use { it.readText() }
        val listType = object : TypeToken<List<ModelData>>() {}.type
        val models = gson.fromJson<List<ModelData>>(modelListJson, listType)
        val model = models.firstOrNull { it.id == modelId } ?: return

        val modelDir = getModelDirectory(modelId, model.versionCode)

        if (model.versionCode == 1) {
            // Delete entire model directory
            modelDir.deleteRecursively()
        } else {
            // Delete individual files
            File(modelDir, model.modelName).delete()
            model.mmprojOrTokenName.takeIf { it.isNotEmpty() }?.let {
                File(modelDir, it).delete()
            }
            model.files?.forEach { fileData ->
                File(modelDir, fileData.name).delete()
            }
        }

        prefs.edit().remove(SP_KEY_PREFIX + modelId).apply()
    }

    fun getStorageInfo(): Map<String, Any> {
        val modelsDir = getModelsDirectory()
        val stat = StatFs(modelsDir.path)

        val totalSpace = stat.totalBytes
        val freeSpace = stat.availableBytes
        val usedByModels = calculateDirectorySize(modelsDir)

        val downloadedModels = prefs.all.keys
            .filter { it.startsWith(SP_KEY_PREFIX) && prefs.getBoolean(it, false) }
            .map { it.removePrefix(SP_KEY_PREFIX) }
            .toList()

        return mapOf(
            "totalSpace" to totalSpace,
            "freeSpace" to freeSpace,
            "usedByModels" to usedByModels,
            "downloadedModels" to downloadedModels
        )
    }

    private fun calculateDirectorySize(directory: File): Long {
        var size = 0L
        directory.walkTopDown().forEach { file ->
            if (file.isFile) {
                size += file.length()
            }
        }
        return size
    }

    fun cleanupIncompleteDownloads() {
        // Currently, incomplete downloads don't leave partial files
        // This could be extended to clean up any temporary files
    }

    fun getDownloadedModels(): List<String> {
        return prefs.all.keys
            .filter { it.startsWith(SP_KEY_PREFIX) && prefs.getBoolean(it, false) }
            .map { it.removePrefix(SP_KEY_PREFIX) }
            .toList()
    }

    fun registerDownloadJob(modelId: String, job: Job) {
        downloadJobs[modelId] = job
    }
}
