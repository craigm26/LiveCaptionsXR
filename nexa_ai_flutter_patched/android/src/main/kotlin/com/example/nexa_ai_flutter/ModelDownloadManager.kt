package com.example.nexa_ai_flutter

import android.content.Context
import android.content.SharedPreferences
import android.os.StatFs
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
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val downloadJobs = mutableMapOf<String, Job>()

    companion object {
        private const val SP_KEY_PREFIX = "model_downloaded_"
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

        // Calculate total size
        var totalBytes = 0L
        filesToDownload.forEach { (_, url) ->
            totalBytes += getFileSize(url)
        }

        var downloadedBytes = 0L
        val startTime = System.currentTimeMillis()

        // Download files sequentially
        try {
            for ((file, url) in filesToDownload) {
                if (!downloadJobs.containsKey(modelId)) {
                    // Download was cancelled
                    sendProgress(eventSink, modelId, downloadedBytes, totalBytes, "cancelled")
                    return
                }

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

                downloadedBytes += fileBytes
            }

            // Mark as downloaded
            prefs.edit().putBoolean(SP_KEY_PREFIX + modelId, true).apply()

            scope.launch(Dispatchers.Main) {
                sendProgress(eventSink, modelId, downloadedBytes, totalBytes, "completed", 0.0)
            }

        } catch (e: Exception) {
            scope.launch(Dispatchers.Main) {
                sendProgress(eventSink, modelId, downloadedBytes, totalBytes, "failed", 0.0)
            }
            throw e
        } finally {
            downloadJobs.remove(modelId)
        }
    }

    private fun getFileSize(url: String): Long {
        val request = Request.Builder().url(url).head().build()
        okHttpClient.newCall(request).execute().use { response ->
            return response.header("Content-Length")?.toLongOrNull() ?: 0L
        }
    }

    private fun downloadFile(url: String, destFile: File, onProgress: (Long) -> Unit): Long {
        val request = Request.Builder().url(url).build()

        okHttpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw Exception("Download failed: ${response.code}")
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
        speedMBps: Double = 0.0
    ) {
        val percentage = if (totalBytes > 0) {
            ((downloadedBytes * 100) / totalBytes).toInt()
        } else 0

        eventSink.success(mapOf(
            "modelId" to modelId,
            "downloadedBytes" to downloadedBytes,
            "totalBytes" to totalBytes,
            "percentage" to percentage,
            "speedMBps" to speedMBps,
            "status" to status
        ))
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
