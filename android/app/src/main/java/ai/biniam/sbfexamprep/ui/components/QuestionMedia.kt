package ai.biniam.sbfexamprep.ui.components

import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.OpenInFull
import androidx.compose.material.icons.filled.StopCircle
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.SbfApplication
import ai.biniam.sbfexamprep.data.Question
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Loads an illustration from the bundled assets off the main thread. */
@Composable
fun rememberAssetBitmap(path: String): ImageBitmap? {
    val context = LocalContext.current
    val bitmap by produceState<ImageBitmap?>(null, path) {
        value = withContext(Dispatchers.IO) {
            runCatching { context.assets.open(path).use { BitmapFactory.decodeStream(it)?.asImageBitmap() } }.getOrNull()
        }
    }
    return bitmap
}

/** Illustration(s) of a question with tap-to-enlarge, plus a play button for sound signals. */
@Composable
fun QuestionMedia(question: Question, maxHeight: Dp = 260.dp) {
    val pattern = question.soundPattern
    val label = if (pattern != null) stringResource(R.string.sound_signal_label, spokenDescription(pattern))
                else stringResource(R.string.illustration_for, question.questionNumber)
    var preview by remember(question.uniqueId) { mutableStateOf<ImageBitmap?>(null) }
    val enlarge = stringResource(R.string.tap_to_enlarge)

    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        question.imagePaths.forEach { path ->
            val bitmap = rememberAssetBitmap(path)
            Box(
                Modifier.fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color.White) // illustrations are drawn on white
                    .border(1.dp, Brand.navyLight.copy(alpha = 0.25f), RoundedCornerShape(12.dp))
                    .clickable(enabled = bitmap != null, onClickLabel = enlarge, role = Role.Image) { preview = bitmap }
                    .semantics { contentDescription = label },
                contentAlignment = Alignment.Center,
            ) {
                if (bitmap != null) {
                    Image(bitmap, null, Modifier.fillMaxWidth().heightIn(max = maxHeight).padding(12.dp),
                          contentScale = ContentScale.Fit)
                } else {
                    Spacer(Modifier.fillMaxWidth().heightIn(min = 160.dp))
                }
                Icon(
                    Icons.Filled.OpenInFull, null,
                    Modifier.align(Alignment.BottomEnd).padding(8.dp).size(26.dp)
                        .clip(CircleShape).background(Color.White.copy(alpha = 0.85f)).padding(5.dp),
                    tint = Brand.navyLight,
                )
            }
        }
        if (pattern != null) SoundSignalButton(pattern)
    }
    preview?.let { ImageViewerDialog(it, label) { preview = null } }
}

/** Full-screen viewer with pinch-to-zoom, pan and double-tap zoom. */
@Composable
fun ImageViewerDialog(bitmap: ImageBitmap, label: String, onDismiss: () -> Unit) {
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        var scale by remember { mutableFloatStateOf(1f) }
        var offset by remember { mutableStateOf(Offset.Zero) }
        Box(Modifier.fillMaxSize().background(Color.Black)) {
            Image(
                bitmap, label,
                Modifier.fillMaxSize()
                    .pointerInput(Unit) {
                        detectTransformGestures { _, pan, zoom, _ ->
                            scale = (scale * zoom).coerceIn(1f, 5f)
                            offset = if (scale == 1f) Offset.Zero else offset + pan
                        }
                    }
                    .pointerInput(Unit) {
                        detectTapGestures(onDoubleTap = {
                            if (scale > 1f) { scale = 1f; offset = Offset.Zero } else scale = 2.5f
                        })
                    }
                    .graphicsLayer(scaleX = scale, scaleY = scale, translationX = offset.x, translationY = offset.y)
                    .background(Color.White),
                contentScale = ContentScale.Fit,
            )
            FilledTonalIconButton(
                onClick = onDismiss,
                modifier = Modifier.align(Alignment.TopEnd).safeDrawingPadding().padding(12.dp),
                colors = IconButtonDefaults.filledTonalIconButtonColors(containerColor = Color.Black.copy(alpha = 0.6f),
                                                                       contentColor = Color.White),
            ) {
                Icon(Icons.Filled.Close, stringResource(R.string.close))
            }
        }
    }
}

/** e.g. "prolonged, short, short" */
@Composable
fun spokenDescription(pattern: String): String {
    val short = stringResource(R.string.blast_short)
    val long = stringResource(R.string.blast_prolonged)
    val pause = stringResource(R.string.blast_pause)
    return pattern.mapNotNull { ch ->
        when (ch) {
            '.' -> short
            '-' -> long
            ' ' -> pause
            else -> null
        }
    }.joinToString(", ")
}

/** Play/stop button that also shows the pattern and highlights the blast that is sounding. */
@Composable
fun SoundSignalButton(pattern: String) {
    val player = (LocalContext.current.applicationContext as SbfApplication).soundPlayer
    val playback by player.state.collectAsStateWithLifecycle()
    val playing = playback?.pattern == pattern
    DisposableEffect(pattern) { onDispose { if (player.state.value?.pattern == pattern) player.stop() } }

    val a11yLabel = stringResource(if (playing) R.string.stop_sound_signal else R.string.play_sound_signal)
    val description = spokenDescription(pattern)
    Surface(
        onClick = { player.toggle(pattern) },
        shape = RoundedCornerShape(12.dp),
        color = Brand.gold.copy(alpha = 0.15f),
        modifier = Modifier.fillMaxWidth().semantics {
            contentDescription = a11yLabel
            stateDescription = description
            onClick(a11yLabel) { player.toggle(pattern); true }
        },
    ) {
        Row(Modifier.padding(horizontal = 14.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(if (playing) Icons.Filled.StopCircle else Icons.AutoMirrored.Filled.VolumeUp, null, tint = Sbf.colors.ink)
            Spacer(Modifier.width(10.dp))
            Text(stringResource(if (playing) R.string.stop else R.string.play_signal),
                 style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink)
            Spacer(Modifier.weight(1f))
            Row(horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
                pattern.forEachIndexed { i, ch ->
                    val color = if (playback?.activeIndex == i && playing) Brand.gold else Sbf.colors.ink
                    when (ch) {
                        '.' -> Box(Modifier.size(10.dp).clip(CircleShape).background(color))
                        '-' -> Box(Modifier.size(width = 26.dp, height = 6.dp).clip(CircleShape).background(color))
                        else -> Spacer(Modifier.width(8.dp))
                    }
                }
            }
        }
    }
}
