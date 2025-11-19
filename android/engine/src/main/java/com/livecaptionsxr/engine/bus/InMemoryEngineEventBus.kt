package com.livecaptionsxr.engine.bus

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

class InMemoryEngineEventBus(
    replay: Int = 0,
    extraBuffer: Int = 64
) : EngineEventBus {

    private val _events = MutableSharedFlow<EngineEvent>(
        replay = replay,
        extraBufferCapacity = extraBuffer
    )
    override val events: SharedFlow<EngineEvent> = _events.asSharedFlow()

    override fun emit(event: EngineEvent) {
        _events.tryEmit(event)
    }
}
