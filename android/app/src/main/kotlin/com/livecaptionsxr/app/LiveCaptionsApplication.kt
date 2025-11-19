package com.livecaptionsxr.app

import android.app.Application
import com.livecaptionsxr.engine.audio.HeadsetMicInput
import com.livecaptionsxr.engine.asr.AsrBackend
import com.livecaptionsxr.engine.asr.StreamingAsrEngine
import com.livecaptionsxr.engine.bus.EngineEventBus
import com.livecaptionsxr.engine.bus.InMemoryEngineEventBus
import com.livecaptionsxr.engine.captions.CaptionEngine
import com.livecaptionsxr.engine.common.AudioFrame
import com.livecaptionsxr.engine.common.CaptionDelta
import com.livecaptionsxr.engine.common.SpeakerId
import com.livecaptionsxr.engine.diarization.OnlineDiarizationEngine
import com.livecaptionsxr.engine.diarization.SpeakerEmbedder
import com.livecaptionsxr.engine.localization.LocalizationEngine
import com.livecaptionsxr.engine.localization.NativeLocalizationEngine
import com.livecaptionsxr.engine.vad.TfliteModel
import com.livecaptionsxr.engine.vad.TfliteVadEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.random.Random

class LiveCaptionsApplication : Application() {

    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    val eventBus: EngineEventBus by lazy {
        InMemoryEngineEventBus()
    }

    private val localizationEngine: LocalizationEngine by lazy {
        NativeLocalizationEngine()
    }

    private val diarizationEngine by lazy {
        OnlineDiarizationEngine(StubSpeakerEmbedder())
    }

    private val asrEngine by lazy {
        StreamingAsrEngine(StubAsrBackend())
    }

    val captionEngine: CaptionEngine by lazy {
        CaptionEngine(
            audioInput = HeadsetMicInput(),
            vad = TfliteVadEngine(StubTfliteModel()),
            diarization = diarizationEngine,
            localization = localizationEngine,
            asr = asrEngine,
            bus = eventBus
        )
    }

    fun warmupEngine() {
        applicationScope.launch {
            captionEngine.start()
        }
    }

    fun shutdownEngine() {
        captionEngine.stop()
    }

    private class StubTfliteModel : TfliteModel {
        override fun predict(frame: AudioFrame): Float {
            return Random(frame.timestampUs).nextFloat()
        }
    }

    private class StubSpeakerEmbedder : SpeakerEmbedder {
        override fun embed(frame: AudioFrame): FloatArray {
            val random = Random(frame.timestampUs)
            return FloatArray(64) { random.nextFloat() }
        }
    }

    private inner class StubAsrBackend : AsrBackend {
        private val backendScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

        override fun feed(frame: AudioFrame, onResult: (CaptionDelta) -> Unit) {
            backendScope.launch {
                delay(50)
                val seed = frame.timestampUs
                val text = "frame@$seed"
                val delta = CaptionDelta(
                    speaker = SpeakerId("spk_stub"),
                    text = text,
                    isFinal = false,
                    timestampUs = frame.timestampUs
                )
                onResult(delta)
            }
        }
    }
}
