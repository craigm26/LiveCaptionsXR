package com.livecaptionsxr.spatialcaptions

import android.app.Activity
import android.util.Log
import com.google.ar.sceneform.math.Vector3
import java.util.concurrent.ConcurrentHashMap

/**
 * Lightweight manager that keeps track of captions that should be rendered in the AR view.
 *
 * The implementation deliberately keeps things simple so that the Android plugin compiles even
 * before the full renderer is ready. Captions are tracked in-memory and operations are logged so we
 * can verify the control flow from Dart.
 */
class ARCaptionManager(private val hostActivity: Activity) {

    private val captions = ConcurrentHashMap<String, CaptionEntry>()
    private var defaultDurationSeconds: Long = 6L
    private var lockLandscape: Boolean = false

    fun addCaption(id: String, text: String, position: Vector3, type: String, speakerId: String?) {
        val captionType = CaptionType.fromWireName(type)
        val entry = CaptionEntry(id, text, position, captionType, speakerId)
        captions[id] = entry
        Log.d(TAG, "addCaption id=$id type=$captionType position=$position speakerId=$speakerId")
    }

    fun updateCaption(id: String, text: String?, position: Vector3?, type: String?) {
        val existing = captions[id]
        if (existing == null) {
            Log.w(TAG, "updateCaption skipping; caption=$id not found")
            return
        }

        val updated = existing.copy(
            text = text ?: existing.text,
            position = position ?: existing.position,
            type = type?.let { CaptionType.fromWireName(it) } ?: existing.type
        )
        captions[id] = updated
        Log.d(TAG, "updateCaption id=$id type=${updated.type} position=${updated.position}")
    }

    fun replaceCaption(oldId: String, newId: String, text: String, type: String) {
        val captionType = CaptionType.fromWireName(type)
        val oldEntry = captions.remove(oldId)
        val newEntry = CaptionEntry(
            id = newId,
            text = text,
            position = oldEntry?.position ?: DEFAULT_POSITION,
            type = captionType,
            speakerId = oldEntry?.speakerId
        )
        captions[newId] = newEntry
        Log.d(TAG, "replaceCaption old=$oldId new=$newId type=$captionType")
    }

    fun removeCaption(id: String) {
        captions.remove(id)
        Log.d(TAG, "removeCaption id=$id")
    }

    fun clearCaptions() {
        captions.clear()
        Log.d(TAG, "clearCaptions")
    }

    fun setCaptionDuration(seconds: Long) {
        defaultDurationSeconds = seconds
        Log.d(TAG, "setCaptionDuration seconds=$seconds")
    }

    fun setOrientationLock(lock: Boolean) {
        lockLandscape = lock
        Log.d(TAG, "setOrientationLock lockLandscape=$lock" )
    }

    fun getActiveCaptions(): List<CaptionEntry> = captions.values.toList()

    fun getDefaultDurationSeconds(): Long = defaultDurationSeconds

    fun isLandscapeLocked(): Boolean = lockLandscape

    data class CaptionEntry(
        val id: String,
        val text: String,
        val position: Vector3,
        val type: CaptionType,
        val speakerId: String?
    )

    companion object {
        private const val TAG = "ARCaptionManager"
        private val DEFAULT_POSITION = Vector3(0f, 0f, -1f)
    }
}

