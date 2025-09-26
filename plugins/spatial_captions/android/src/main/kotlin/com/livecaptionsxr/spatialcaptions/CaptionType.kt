package com.livecaptionsxr.spatialcaptions

/**
 * The available caption types for AR captions.
 *
 * The string representation of each enum matches what is sent from Dart via
 * `CaptionType.toString()` (for example `CaptionType.partial`).
 */
enum class CaptionType(val wireName: String) {
    PARTIAL("CaptionType.partial"),
    FINAL("CaptionType.final_"),
    ENHANCED("CaptionType.enhanced"),
    UNKNOWN("unknown");

    companion object {
        fun fromWireName(value: String?): CaptionType {
            if (value == null) return UNKNOWN
            return entries.firstOrNull { it.wireName == value } ?: UNKNOWN
        }
    }
}
 