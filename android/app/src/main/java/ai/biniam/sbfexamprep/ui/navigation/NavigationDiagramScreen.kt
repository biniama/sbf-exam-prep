package ai.biniam.sbfexamprep.ui.navigation

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.VolumeOff
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.NavigationDiagram
import ai.biniam.sbfexamprep.data.NavigationTask
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.components.isGerman
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf
import java.util.Locale
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlin.coroutines.resume
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.sin
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine

private const val PREFS = "navigation_diagram"
private const val KEY_NARRATION = "narration"

/** Step-by-step solution diagram with optional narration (feature flag NAVIGATION_DIAGRAMS). */
@Composable
fun NavigationDiagramScreen(task: NavigationTask, diagram: NavigationDiagram, onBack: () -> Unit) {
    val context = LocalContext.current
    val german = isGerman()
    val prefs = remember { context.getSharedPreferences(PREFS, Context.MODE_PRIVATE) }
    var narration by remember { mutableStateOf(prefs.getBoolean(KEY_NARRATION, true)) }
    var frame by rememberSaveable { mutableIntStateOf(0) }
    var autoPlay by remember { mutableStateOf(false) }
    val narrator = remember(german) { Narrator(context, if (german) Locale.GERMANY else Locale.UK) }
    DisposableEffect(narrator) { onDispose { narrator.shutdown() } }

    val last = diagram.frames.lastIndex
    val current = diagram.frames[frame]
    val visible = diagram.frames.take(frame + 1).flatMap { it.show }.toSet()

    fun go(index: Int) {
        if (index !in diagram.frames.indices) return
        autoPlay = false
        frame = index
        if (narration) narrator.speak(diagram.frames[index].text(german)) else narrator.stop()
    }

    LaunchedEffect(autoPlay) {
        while (autoPlay) {
            val spoken = narration && narrator.speakAndAwait(diagram.frames[frame].text(german))
            delay(if (spoken) 800 else 4000)
            if (!autoPlay) break
            if (frame < last) frame++ else autoPlay = false
        }
    }

    val wide = LocalConfiguration.current.screenWidthDp >= 600
    NavScaffold(stringResource(R.string.diagram_title, task.number), onBack) {
        DiagramCanvas(diagram, visible, current.show.toSet(), german,
                      Modifier.fillMaxWidth().height(if (wide) 460.dp else 340.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(stringResource(R.string.diagram_step, frame + 1, diagram.frames.size),
                 style = MaterialTheme.typography.labelLarge, color = Sbf.colors.muted)
            current.step?.let {
                Spacer(Modifier.width(6.dp))
                Text(stringResource(R.string.diagram_question, it), style = MaterialTheme.typography.labelMedium,
                     color = Sbf.colors.muted)
            }
            Spacer(Modifier.weight(1f))
            TextButton(onClick = {
                narration = !narration
                prefs.edit().putBoolean(KEY_NARRATION, narration).apply()
                if (!narration) narrator.stop()
            }) {
                Icon(if (narration) Icons.AutoMirrored.Filled.VolumeUp else Icons.AutoMirrored.Filled.VolumeOff, null,
                     Modifier.size(18.dp))
                Spacer(Modifier.width(4.dp))
                Text(stringResource(R.string.diagram_read_aloud))
            }
        }
        // Controls above the caption so they stay in place while the text length changes.
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
            FilledTonalButton(onClick = { go(frame - 1) }, enabled = frame > 0, modifier = Modifier.weight(1f)) {
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, null)
                Text(stringResource(R.string.diagram_back))
            }
            val playLabel = stringResource(if (autoPlay) R.string.diagram_pause else R.string.diagram_play)
            Button(onClick = { autoPlay = !autoPlay; if (!autoPlay) narrator.stop() },
                   colors = ButtonDefaults.buttonColors(containerColor = Brand.gold),
                   modifier = Modifier.semantics { contentDescription = playLabel }) {
                Icon(if (autoPlay) Icons.Filled.Pause else Icons.Filled.PlayArrow, null)
            }
            FilledTonalButton(onClick = { go(frame + 1) }, enabled = frame < last, modifier = Modifier.weight(1f)) {
                Text(stringResource(R.string.diagram_next))
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null)
            }
        }
        Text(current.text(german), Modifier.fillMaxWidth().cardStyle().padding(14.dp),
             style = MaterialTheme.typography.bodyLarge, color = Sbf.colors.ink)
        Text(stringResource(R.string.diagram_disclaimer), style = MaterialTheme.typography.labelSmall, color = Sbf.colors.muted)
    }
}

private class LabelRequest(val text: String, val anchor: Offset, val color: Color, val bold: Boolean, val gap: Float)

/** Lat/long grid, course and bearing lines and positions up to the current frame; its additions highlighted. */
@Composable
private fun DiagramCanvas(diagram: NavigationDiagram, visible: Set<String>, highlighted: Set<String>, german: Boolean,
                          modifier: Modifier) {
    val measurer = rememberTextMeasurer()
    val errorColor = Sbf.colors.error
    val successColor = Sbf.colors.success
    val a11y = stringResource(R.string.diagram_a11y)
    fun lineColor(style: String) = when (style) {
        "course" -> Brand.navy
        "bearing" -> Brand.oceanTeal
        "set_drift" -> errorColor
        else -> Color.Gray
    }
    Canvas(modifier.clip(RoundedCornerShape(14.dp)).background(Color(0xFFEDF5FA)).semantics { contentDescription = a11y }) {
        val margin = 46.dp.toPx()
        val scale = minOf((size.width - 2 * margin) / diagram.width.coerceAtLeast(1.0),
                          (size.height - 2 * margin) / diagram.height.coerceAtLeast(1.0)).toFloat()
        fun p(x: Double?, y: Double?) = Offset(size.width / 2 + (x ?: 0.0).toFloat() * scale,
                                               size.height / 2 - (y ?: 0.0).toFloat() * scale)
        drawGrid(diagram.grid, scale, measurer)

        val labels = mutableListOf<LabelRequest>()
        val occupied = mutableListOf(Rect(Offset(size.width - 36.dp.toPx(), 14.dp.toPx()), Size(28.dp.toPx(), 40.dp.toPx())))
        for (e in diagram.elements) {
            if (e.type != "line" || e.id !in visible) continue
            val a = p(e.x1, e.y1)
            val b = p(e.x2, e.y2)
            val hl = e.id in highlighted
            val color = lineColor(e.style)
            val effect = when (e.style) {
                "course", "set_drift" -> null
                "bearing" -> PathEffect.dashPathEffect(floatArrayOf(7.dp.toPx(), 5.dp.toPx()))
                else -> PathEffect.dashPathEffect(floatArrayOf(2.dp.toPx(), 4.dp.toPx()))
            }
            drawLine(color, a, b, (if (hl) 3.5f else 2.5f).dp.toPx(), StrokeCap.Round, effect)
            if (e.style == "course" || e.style == "set_drift" || e.style == "track") {
                val angle = atan2(b.y - a.y, b.x - a.x)
                val len = 11.dp.toPx()
                for (d in listOf(-0.4f, 0.4f)) {
                    drawLine(color, b, Offset(b.x - len * cos(angle + d), b.y - len * sin(angle + d)),
                             2.5f.dp.toPx(), StrokeCap.Round)
                }
            }
            e.label(german)?.let { labels += LabelRequest(it, (a + b) / 2f, color, hl, 6.dp.toPx()) }
        }
        for (e in diagram.elements) {
            if (e.type != "point" || e.id !in visible) continue
            val c = p(e.x, e.y)
            val hl = e.id in highlighted
            drawSymbol(e.style, c, (if (hl) 7.5f else 6f).dp.toPx(), errorColor, successColor)
            val r = 9.dp.toPx()
            occupied += Rect(c.x - r, c.y - r, c.x + r, c.y + r)
            val text = listOfNotNull(e.label(german), e.sub).joinToString(" ")
            if (text.isNotEmpty()) labels += LabelRequest(text, c, Brand.navy, hl, 10.dp.toPx())
        }
        drawNorthArrow(Offset(size.width - 22.dp.toPx(), 30.dp.toPx()), measurer)
        // Labels of the current step get the best spots and are drawn on top.
        val placed = (labels.filter { it.bold } + labels.filter { !it.bold }).map { placeLabel(it, measurer, occupied) }
        for ((box, layout) in placed.asReversed()) {
            drawRoundRect(Color.White.copy(alpha = 0.88f), box.topLeft, box.size,
                          androidx.compose.ui.geometry.CornerRadius(4.dp.toPx()))
            drawText(layout, topLeft = Offset(box.left + 3.dp.toPx(), box.top + 1.dp.toPx()))
        }
    }
}

private fun DrawScope.drawGrid(g: NavigationDiagram.Grid, scale: Float, measurer: TextMeasurer) {
    val gridColor = Color(0xFFC7D9E8)
    val labelStyle = TextStyle(fontSize = 9.sp, color = Color(0xFF6B859E))
    val halfW = size.width / 2 / scale
    val halfH = size.height / 2 / scale
    val pxPerDp = 1.dp.toPx()
    // One line per minute of latitude / longitude; labels only as often as they fit.
    val step = if (scale > 30 * pxPerDp) 1 else 2
    val latEvery = labelInterval(scale / pxPerDp, 22f)
    val lonEvery = labelInterval(scale * g.k.toFloat() / pxPerDp, 46f)
    val lat0 = floor(g.lat * 60)
    for (i in -40..40 step step) {
        val latMin = lat0 + i
        val y = (latMin - g.lat * 60).toFloat()
        if (kotlin.math.abs(y) >= halfH) continue
        val py = size.height / 2 - y * scale
        drawLine(gridColor, Offset(0f, py), Offset(size.width, py), 0.7f * pxPerDp)
        if (latMin.toInt() % latEvery != 0 || py <= 16 * pxPerDp || py >= size.height - 20 * pxPerDp) continue
        val text = measurer.measure(minutesLabel(latMin), labelStyle)
        drawText(text, topLeft = Offset(4 * pxPerDp, py - 6 * pxPerDp - text.size.height / 2))
    }
    val lon0 = floor(g.lon * 60)
    for (i in -60..60 step step) {
        val lonMin = lon0 + i
        val x = ((lonMin - g.lon * 60) * g.k).toFloat()
        if (kotlin.math.abs(x) >= halfW) continue
        val px = size.width / 2 + x * scale
        drawLine(gridColor, Offset(px, 0f), Offset(px, size.height), 0.7f * pxPerDp)
        if (lonMin.toInt() % lonEvery != 0 || px >= size.width - 40 * pxPerDp) continue
        val text = measurer.measure(minutesLabel(lonMin), labelStyle)
        drawText(text, topLeft = Offset(px + 2 * pxPerDp, size.height - 8 * pxPerDp - text.size.height / 2))
    }
}

/** Smallest of 1, 2, 5, 10 minutes whose labels are at least [needed] dp apart. */
private fun labelInterval(spacingDp: Float, needed: Float) = listOf(1, 2, 5, 10).firstOrNull { it * spacingDp >= needed } ?: 10

private fun minutesLabel(totalMinutes: Double): String {
    val deg = (totalMinutes / 60).toInt()
    return "%d°%02d'".format(deg, totalMinutes.toInt() - deg * 60)
}

private fun DrawScope.drawSymbol(style: String, c: Offset, r: Float, errorColor: Color, successColor: Color) {
    when (style) {
        "mark" -> {
            val diamond = Path().apply {
                moveTo(c.x, c.y - r - 1); lineTo(c.x + r, c.y); lineTo(c.x, c.y + r + 1); lineTo(c.x - r, c.y); close()
            }
            drawPath(diamond, Brand.gold)
            drawPath(diamond, Brand.navy, style = Stroke(1.dp.toPx()))
        }
        "dr" -> {
            drawRect(Color.White, Offset(c.x - r, c.y - r), Size(2 * r, 2 * r))
            drawRect(Brand.navy, Offset(c.x - r, c.y - r), Size(2 * r, 2 * r), style = Stroke(2.dp.toPx()))
        }
        "fix" -> {
            drawCircle(errorColor, r, c, style = Stroke(2.5f.dp.toPx()))
            drawCircle(errorColor, r * 0.4f, c)
        }
        else -> drawPath(Path().apply { moveTo(c.x, c.y - r - 1); lineTo(c.x + r, c.y + r); lineTo(c.x - r, c.y + r); close() },
                         successColor)
    }
}

private fun DrawScope.drawNorthArrow(c: Offset, measurer: TextMeasurer) {
    val u = 1.dp.toPx()
    drawPath(Path().apply {
        moveTo(c.x, c.y - 12 * u); lineTo(c.x + 6 * u, c.y + 6 * u); lineTo(c.x, c.y + 2 * u); lineTo(c.x - 6 * u, c.y + 6 * u); close()
    }, Brand.navy)
    val n = measurer.measure("N", TextStyle(fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Brand.navy))
    drawText(n, topLeft = Offset(c.x - n.size.width / 2, c.y + 16 * u - n.size.height / 2))
}

/**
 * Finds the first spot around the label's anchor that stays on the canvas and is free,
 * moving further away step by step when the close spots are taken.
 */
private fun DrawScope.placeLabel(label: LabelRequest, measurer: TextMeasurer, occupied: MutableList<Rect>) =
    measurer.measure(label.text, TextStyle(fontSize = 11.sp, fontWeight = if (label.bold) FontWeight.Bold else FontWeight.Medium,
                                           color = label.color),
                     constraints = Constraints(maxWidth = 220.dp.roundToPx())).let { layout ->
        val u = 1.dp.toPx()
        val w = layout.size.width + 6 * u
        val h = layout.size.height + 2 * u
        val a = label.anchor
        val g = label.gap
        val near = listOf(
            Offset(a.x + g, a.y - h - 3 * u), Offset(a.x - g - w, a.y - h - 3 * u),
            Offset(a.x + g, a.y + 3 * u), Offset(a.x - g - w, a.y + 3 * u),
            Offset(a.x - w / 2, a.y - h - g), Offset(a.x - w / 2, a.y + g),
        )
        val farther = (1..4).flatMap { k ->
            near.take(4).flatMap { o -> listOf(Offset(o.x, o.y - k * (h + 2 * u)), Offset(o.x, o.y + k * (h + 2 * u))) }
        }
        val bounds = Rect(3 * u, 3 * u, size.width - 3 * u, size.height - 3 * u)
        val candidates = (near + farther).map { Rect(it, Size(w, h)) }
        val inside = candidates.filter { it.left >= bounds.left && it.top >= bounds.top && it.right <= bounds.right && it.bottom <= bounds.bottom }
        val chosen = inside.firstOrNull { r -> occupied.none { it.overlaps(r) } } ?: inside.firstOrNull() ?: candidates[0]
        val box = Rect(Offset(chosen.left.coerceIn(bounds.left, (bounds.right - w).coerceAtLeast(bounds.left)),
                              chosen.top.coerceIn(bounds.top, (bounds.bottom - h).coerceAtLeast(bounds.top))), Size(w, h))
        occupied += box
        box to layout
    }

/** Speaks the frame texts with the system text-to-speech engine in the app language. */
private class Narrator(context: Context, private val locale: Locale) : TextToSpeech.OnInitListener {
    private val tts = TextToSpeech(context.applicationContext, this)
    private val main = Handler(Looper.getMainLooper())
    private val callbacks = ConcurrentHashMap<String, () -> Unit>()
    private var ready = false
    private var failed = false
    private var pending: Pair<String, String>? = null

    override fun onInit(status: Int) {
        ready = status == TextToSpeech.SUCCESS && tts.setLanguage(locale) >= TextToSpeech.LANG_AVAILABLE
        failed = !ready
        if (ready) {
            tts.setSpeechRate(0.95f)
            tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String) {}
                override fun onDone(utteranceId: String) = finish(utteranceId)
                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String) = finish(utteranceId)
                override fun onStop(utteranceId: String, interrupted: Boolean) = finish(utteranceId)
            })
        }
        pending?.let { (text, id) -> if (ready) tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, id) else finish(id) }
        pending = null
    }

    private fun finish(id: String) {
        main.post { callbacks.remove(id)?.invoke() }
    }

    /** [onDone] also runs when speech is interrupted or unavailable. Returns false when there is no voice. */
    fun speak(text: String, onDone: () -> Unit = {}): Boolean {
        val id = UUID.randomUUID().toString()
        callbacks[id] = onDone
        when {
            ready -> tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, id)
            failed -> { finish(id); return false }
            else -> pending = text to id
        }
        return true
    }

    /** Returns false right away when no voice is available. */
    suspend fun speakAndAwait(text: String): Boolean = suspendCancellableCoroutine { cont ->
        val started = speak(text) { if (cont.isActive) cont.resume(true) }
        if (!started && cont.isActive) cont.resume(false)
    }

    fun stop() {
        tts.stop()
    }

    fun shutdown() {
        tts.stop()
        tts.shutdown()
    }
}
