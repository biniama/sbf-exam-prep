package ai.biniam.sbfexamprep.audio

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.PI
import kotlin.math.min
import kotlin.math.sin

/**
 * Sound-signal timing. Pattern syntax: "." short blast, "-" prolonged blast,
 * " " pause between groups. Short ≈ 1 s, prolonged ≈ 4 s (KVR / SeeSchStrO).
 */
object SoundSignal {
    const val SHORT_SECONDS = 1.0
    const val LONG_SECONDS = 4.0
    const val GAP_SECONDS = 1.0
    const val PAUSE_SECONDS = 2.5

    data class Segment(val index: Int, val start: Double, val duration: Double)

    /** Timeline of the blasts in a pattern and its total length in seconds. */
    fun timeline(pattern: String): Pair<List<Segment>, Double> {
        var t = 0.0
        val segments = mutableListOf<Segment>()
        pattern.forEachIndexed { i, ch ->
            when (ch) {
                '.' -> { segments += Segment(i, t, SHORT_SECONDS); t += SHORT_SECONDS + GAP_SECONDS }
                '-' -> { segments += Segment(i, t, LONG_SECONDS); t += LONG_SECONDS + GAP_SECONDS }
                ' ' -> t += PAUSE_SECONDS - GAP_SECONDS
            }
        }
        return segments to maxOf(0.0, t - GAP_SECONDS)
    }
}

/** Plays sound signals with a synthesised ship's horn. */
class SoundSignalPlayer(private val scope: CoroutineScope) {
    data class Playback(val pattern: String, val activeIndex: Int?)

    private val _state = MutableStateFlow<Playback?>(null)
    val state: StateFlow<Playback?> = _state.asStateFlow()

    private var job: Job? = null
    private var track: AudioTrack? = null

    fun toggle(pattern: String) = if (_state.value?.pattern == pattern) stop() else play(pattern)

    fun play(pattern: String) {
        stop()
        val (segments, total) = SoundSignal.timeline(pattern)
        if (total <= 0) return
        _state.value = Playback(pattern, null)
        job = scope.launch {
            val samples = withContext(Dispatchers.Default) { synthesize(segments, total) }
            val audio = AudioTrack.Builder()
                .setAudioAttributes(AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build())
                .setAudioFormat(AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(SAMPLE_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build())
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(samples.size * 2)
                .build()
            track = audio
            audio.write(samples, 0, samples.size)
            audio.play()
            val started = System.nanoTime()
            while (isActive) {
                val elapsed = (System.nanoTime() - started) / 1e9
                if (elapsed >= total + 0.1) break
                val active = segments.firstOrNull { elapsed >= it.start && elapsed < it.start + it.duration }?.index
                _state.value = Playback(pattern, active)
                delay(50)
            }
            stop()
        }
    }

    fun stop() {
        val running = job
        job = null
        track?.let { runCatching { it.stop() }; it.release() }
        track = null
        _state.value = null
        running?.cancel()
    }

    private fun synthesize(segments: List<SoundSignal.Segment>, total: Double): ShortArray {
        val frames = (total * SAMPLE_RATE).toInt()
        val data = ShortArray(frames)
        // Ship's horn: low fundamental with a few harmonics, soft attack/release.
        val f0 = 220.0
        val ramp = 0.04
        for (seg in segments) {
            val start = (seg.start * SAMPLE_RATE).toInt()
            val count = (seg.duration * SAMPLE_RATE).toInt()
            for (n in 0 until count) {
                if (start + n >= frames) break
                val t = n.toDouble() / SAMPLE_RATE
                val env = min(1.0, min(t / ramp, (seg.duration - t) / ramp))
                val s = sin(2 * PI * f0 * t) + 0.5 * sin(4 * PI * f0 * t) +
                    0.3 * sin(6 * PI * f0 * t) + 0.15 * sin(8 * PI * f0 * t)
                data[start + n] = (0.28 * env * s * Short.MAX_VALUE).toInt().coerceIn(-32768, 32767).toShort()
            }
        }
        return data
    }

    private companion object {
        const val SAMPLE_RATE = 44_100
    }
}
