package com.livecaptionsxr.engine.bus

import com.livecaptionsxr.engine.common.CaptionDelta
import com.livecaptionsxr.engine.common.SpeakerState
import kotlinx.coroutines.flow.Flow

sealed interface EngineEvent {
    data class SpeakerUpdate(val state: SpeakerState) : EngineEvent
    data class CaptionUpdate(val delta: CaptionDelta) : EngineEvent
}

interface EngineEventBus {
    val events: Flow<EngineEvent>
    fun emit(event: EngineEvent)
}
