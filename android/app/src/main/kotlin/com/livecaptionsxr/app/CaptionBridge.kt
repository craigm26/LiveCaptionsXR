package com.livecaptionsxr.app

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Singleton bridge for sharing caption text between the Flutter engine
 * (via GlassesPlugin) and the native GlassesActivity.
 *
 * Both run in the same process, so a shared in-memory StateFlow is
 * the simplest and most efficient communication mechanism.
 */
object CaptionBridge {
    private val _captionFlow = MutableStateFlow("")
    val captionFlow: StateFlow<String> = _captionFlow.asStateFlow()

    private val _isGlassesActivityActive = MutableStateFlow(false)
    val isGlassesActivityActive: StateFlow<Boolean> = _isGlassesActivityActive.asStateFlow()

    fun updateCaption(text: String) {
        _captionFlow.value = text
    }

    fun setGlassesActivityActive(active: Boolean) {
        _isGlassesActivityActive.value = active
    }
}
