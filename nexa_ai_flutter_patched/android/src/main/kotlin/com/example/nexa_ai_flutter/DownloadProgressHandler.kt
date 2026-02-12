package com.example.nexa_ai_flutter

import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

class DownloadProgressHandler(
    private val downloadManager: ModelDownloadManager,
    private val scope: CoroutineScope
) : EventChannel.StreamHandler {
    private var downloadJob: Job? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (arguments !is Map<*, *> || events == null) return

        val modelId = arguments["modelId"] as? String ?: return

        downloadJob = scope.launch(Dispatchers.IO) {
            try {
                downloadManager.downloadModel(modelId, scope, events)
            } catch (e: Exception) {
                launch(Dispatchers.Main) {
                    events.error("DOWNLOAD_ERROR", e.message, null)
                }
            }
        }

        // Register the job for cancellation
        downloadManager.registerDownloadJob(modelId, downloadJob!!)
    }

    override fun onCancel(arguments: Any?) {
        downloadJob?.cancel()
        downloadJob = null
    }
}
