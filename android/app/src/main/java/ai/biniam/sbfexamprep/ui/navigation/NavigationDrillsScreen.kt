package ai.biniam.sbfexamprep.ui.navigation

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.DrillText
import ai.biniam.sbfexamprep.data.LightCharacter
import ai.biniam.sbfexamprep.data.NavigationDrill
import ai.biniam.sbfexamprep.ui.components.PrimaryButton
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf

/** A light flashing in its real rhythm (feature flag NAVIGATION_DRILLS). */
@Composable
fun LightBeacon(light: LightCharacter, size: Dp = 90.dp) {
    var elapsed by remember(light) { mutableDoubleStateOf(0.0) }
    LaunchedEffect(light) {
        val start = withFrameNanos { it }
        while (true) withFrameNanos { elapsed = (it - start) / 1e9 }
    }
    val on = light.isOn(elapsed)
    val progress = ((elapsed % light.period) / light.period).toFloat()
    val colour = when (light.colour) {
        'R' -> Color(0xFFFF4040)
        'G' -> Color(0xFF4DFF73)
        'Y' -> Color(0xFFFFD933)
        else -> Color.White
    }
    val label = stringResource(R.string.light_animated)
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Brand.navy).padding(vertical = 16.dp)
            .semantics { contentDescription = label },
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Canvas(Modifier.size(size)) {
            val r = this.size.minDimension * 0.21f
            if (on) drawCircle(Brush.radialGradient(listOf(colour.copy(alpha = 0.6f), Color.Transparent), center, r * 2.6f), r * 2.6f)
            drawCircle(if (on) colour else Color.White.copy(alpha = 0.06f), r)
            drawCircle(Color.White.copy(alpha = 0.18f), r, style = Stroke(2.dp.toPx()))
        }
        Box(Modifier.width(size * 1.6f).height(4.dp).clip(RoundedCornerShape(2.dp)).background(Color.White.copy(alpha = 0.15f))) {
            Box(Modifier.fillMaxWidth(progress).height(4.dp).background(Color.White.copy(alpha = 0.6f)))
        }
    }
}

@Composable
private fun DrillText.resolve(): String = when (this) {
    is DrillText.Raw -> text
    is DrillText.Res -> stringResource(id, *args.toTypedArray())
}

/** Unlimited practice for the arithmetic of the navigation task. */
@Composable
fun NavigationDrillsScreen(onBack: () -> Unit) {
    var kindIndex by rememberSaveable { mutableIntStateOf(0) }
    val kind = NavigationDrill.Kind.entries[kindIndex]
    var drill by remember { mutableStateOf(NavigationDrill.make(kind)) }
    var input by remember { mutableStateOf("") }
    var picked by remember { mutableStateOf<LightCharacter?>(null) }
    var result by remember { mutableStateOf<Boolean?>(null) }
    var correct by rememberSaveable { mutableIntStateOf(0) }
    var answered by rememberSaveable { mutableIntStateOf(0) }

    fun next(k: NavigationDrill.Kind = kind) {
        drill = NavigationDrill.make(k); input = ""; picked = null; result = null
    }
    fun check() {
        if (result != null) return
        val ok = if (drill.kind == NavigationDrill.Kind.LIGHT) picked?.let(drill::check) ?: return
                 else if (input.isBlank()) return else drill.check(input)
        result = ok; answered++; if (ok) correct++
    }

    NavScaffold(stringResource(R.string.ff_navigation_drills), onBack) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState())) {
            NavigationDrill.Kind.entries.forEachIndexed { i, k ->
                FilterChip(selected = i == kindIndex, onClick = { kindIndex = i; next(k) },
                           label = { Text(stringResource(k.title), maxLines = 1) })
            }
        }
        if (answered > 0) {
            Text(stringResource(R.string.drill_score, correct, answered), style = MaterialTheme.typography.labelLarge,
                 color = Sbf.colors.muted)
        }
        Column(Modifier.fillMaxWidth().cardStyle().padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text(stringResource(drill.kind.title), style = MaterialTheme.typography.labelLarge, color = Sbf.colors.inkSecondary)
            drill.light?.let { LightBeacon(it) }
            Text(drill.prompt.resolve(), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold,
                 color = Sbf.colors.ink)
            if (drill.kind == NavigationDrill.Kind.LIGHT) {
                drill.choices.forEach { choice ->
                    val isPicked = picked == choice
                    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp))
                        .background(if (isPicked) Brand.gold.copy(alpha = 0.2f) else Brand.navyLight.copy(alpha = 0.08f))
                        .clickable(enabled = result == null) { picked = choice }.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Text(choice.notation, Modifier.weight(1f), fontFamily = FontFamily.Monospace, fontWeight = FontWeight.SemiBold,
                             color = Sbf.colors.ink)
                        if (result != null && choice == drill.light) Icon(Icons.Filled.CheckCircle, null, tint = Sbf.colors.success)
                        else if (result != null && isPicked) Icon(Icons.Filled.Cancel, null, tint = Sbf.colors.error)
                    }
                }
            } else {
                OutlinedTextField(
                    value = input, onValueChange = { input = it }, enabled = result == null, singleLine = true,
                    label = { Text(stringResource(if (drill.isClock) R.string.nav_field_clock else R.string.drill_answer)) },
                    suffix = drill.unit?.let { { Text(it.resolve()) } },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal, imeAction = ImeAction.Done),
                    keyboardActions = KeyboardActions(onDone = { check() }),
                    modifier = Modifier.widthIn(max = 220.dp),
                )
            }
            result?.let { ok ->
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                    .background((if (ok) Sbf.colors.success else Sbf.colors.error).copy(alpha = 0.08f)).padding(12.dp),
                       verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(if (ok) Icons.Filled.CheckCircle else Icons.Filled.Cancel, null,
                             tint = if (ok) Sbf.colors.success else Sbf.colors.error)
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(if (ok) R.string.correct else R.string.drill_not_quite), fontWeight = FontWeight.SemiBold,
                             color = if (ok) Sbf.colors.success else Sbf.colors.error)
                    }
                    drill.solution.forEach { Text(it.resolve(), style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink) }
                }
            }
        }
        val ready = result != null || (if (drill.kind == NavigationDrill.Kind.LIGHT) picked != null else input.isNotBlank())
        PrimaryButton(stringResource(if (result == null) R.string.drill_check else R.string.drill_next),
                      if (result == null) Icons.Filled.Check else Icons.AutoMirrored.Filled.ArrowForward,
                      onClick = { if (result == null) check() else next() }, enabled = ready)
    }
}
