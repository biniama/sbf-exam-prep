package ai.biniam.sbfexamprep.ui.navigation

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Draw
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.NavigationExamPart
import ai.biniam.sbfexamprep.data.NavigationField
import ai.biniam.sbfexamprep.data.NavigationStep
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.PrimaryButton
import ai.biniam.sbfexamprep.ui.components.ReadableWidth
import ai.biniam.sbfexamprep.ui.components.SectionHeader
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.quiz.QuizViewModel
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf

/** Navigation part of the See exam simulation: one task, typed answers, no feedback until the end. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NavigationExamScreen(vm: QuizViewModel) {
    val part = vm.navigationPart ?: return
    val settings by LocalApp.current.progressRepository.settings.collectAsStateWithLifecycle()
    var confirmQuit by rememberSaveable { mutableStateOf(false) }
    BackHandler { confirmQuit = true }
    Scaffold(
        containerColor = Sbf.colors.surface,
        topBar = {
            Column {
                TopAppBar(
                    title = { Text(stringResource(R.string.nav_exam_title), fontWeight = FontWeight.SemiBold) },
                    navigationIcon = {
                        IconButton(onClick = { confirmQuit = true }) { Icon(Icons.Filled.Close, stringResource(R.string.close_quiz)) }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = Sbf.colors.surface),
                )
                val color = if (vm.timeRemaining > 300) Sbf.colors.success else Sbf.colors.error
                Row(Modifier.fillMaxWidth().background(Sbf.colors.card).padding(horizontal = 16.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Timer, null, Modifier.size(16.dp), tint = color)
                    Spacer(Modifier.width(6.dp))
                    Text(vm.formattedTime, style = MaterialTheme.typography.labelLarge, color = color)
                }
            }
        },
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().imePadding().verticalScroll(rememberScrollState())) {
            ReadableWidth {
                Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Map, null, tint = Brand.navyLight)
                        Spacer(Modifier.width(8.dp))
                        Text(stringResource(R.string.nav_exam_task_n, part.task.number), style = MaterialTheme.typography.titleMedium,
                             fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink)
                    }
                    Text(stringResource(R.string.nav_exam_hint), style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted)
                    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Brand.navyLight.copy(alpha = 0.10f)).padding(14.dp),
                           verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(part.task.introDe, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink)
                        if (settings.showEnglish) part.task.introEn?.let {
                            Text(it, style = MaterialTheme.typography.bodySmall, fontStyle = FontStyle.Italic, color = Sbf.colors.inkSecondary)
                        }
                    }
                    part.task.steps.forEach { step -> StepInput(part, step, settings.showEnglish) }
                    PrimaryButton(stringResource(R.string.finish_see_result), Icons.Filled.CheckCircle, onClick = vm::finish)
                    val t = part.tolerances
                    Text(stringResource(R.string.nav_exam_tolerance, t.degrees.toInt(), "%.1f".format(t.nm), t.minutes.toInt(),
                                        "%.1f".format(t.arcMinutes)),
                         style = MaterialTheme.typography.labelSmall, color = Sbf.colors.muted)
                }
            }
        }
    }
    if (confirmQuit) {
        AlertDialog(
            onDismissRequest = { confirmQuit = false },
            title = { Text(stringResource(R.string.end_exam_title)) },
            text = { Text(stringResource(R.string.unanswered_wrong)) },
            confirmButton = {
                Column(horizontalAlignment = Alignment.End) {
                    TextButton(onClick = { confirmQuit = false; vm.finish() }) { Text(stringResource(R.string.finish_see_result)) }
                    TextButton(onClick = { confirmQuit = false; vm.close() }) {
                        Text(stringResource(R.string.quit_without_result), color = Sbf.colors.error)
                    }
                    TextButton(onClick = { confirmQuit = false }) { Text(stringResource(R.string.continue_label)) }
                }
            },
        )
    }
}

@Composable
private fun StepInput(part: NavigationExamPart, step: NavigationStep, showEnglish: Boolean) {
    val fields = NavigationField.fieldsFor(step)
    Column(Modifier.fillMaxWidth().cardStyle().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.Top) {
            Box(Modifier.size(26.dp).clip(CircleShape).background(Brand.gold.copy(alpha = 0.35f)), contentAlignment = Alignment.Center) {
                Text("${step.number}", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold, color = Brand.navy)
            }
            Spacer(Modifier.width(10.dp))
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(step.questionDe, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink)
                if (showEnglish) step.questionEn?.let {
                    Text(it, style = MaterialTheme.typography.bodySmall, fontStyle = FontStyle.Italic, color = Sbf.colors.inkSecondary)
                }
            }
        }
        if (step.isPlot) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Draw, null, Modifier.size(16.dp), tint = Brand.oceanTeal)
                Spacer(Modifier.width(6.dp))
                Text(stringResource(R.string.nav_chart_work), style = MaterialTheme.typography.labelMedium, color = Brand.oceanTeal)
            }
        }
        // Two fields per row so positions (4 fields) and cross bearings fit on a phone.
        fields.indices.chunked(2).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                row.forEach { index ->
                    val field = fields[index]
                    OutlinedTextField(
                        value = part.inputs[step.number]?.getOrNull(index).orEmpty(),
                        onValueChange = { part.setInput(step.number, index, it) },
                        label = { Text(fieldLabel(field)) },
                        suffix = fieldUnit(field)?.let { { Text(it) } },
                        singleLine = field != NavigationField.TEXT,
                        keyboardOptions = KeyboardOptions(
                            keyboardType = if (field == NavigationField.TEXT) KeyboardType.Text else KeyboardType.Decimal),
                        modifier = if (field == NavigationField.TEXT) Modifier.fillMaxWidth() else Modifier.widthIn(max = 150.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun fieldLabel(field: NavigationField): String = stringResource(
    when (field) {
        NavigationField.DEGREES -> R.string.nav_field_degrees
        NavigationField.NAUTICAL_MILES -> R.string.nav_field_distance
        NavigationField.MINUTES -> R.string.nav_field_minutes
        NavigationField.KNOTS -> R.string.nav_field_speed
        NavigationField.CLOCK -> R.string.nav_field_clock
        NavigationField.LATITUDE_DEGREES -> R.string.nav_field_lat_deg
        NavigationField.LATITUDE_MINUTES -> R.string.nav_field_lat_min
        NavigationField.LONGITUDE_DEGREES -> R.string.nav_field_lon_deg
        NavigationField.LONGITUDE_MINUTES -> R.string.nav_field_lon_min
        NavigationField.TEXT -> R.string.nav_field_text
    }
)

@Composable
private fun fieldUnit(field: NavigationField): String? = when (field) {
    NavigationField.DEGREES, NavigationField.LATITUDE_DEGREES, NavigationField.LONGITUDE_DEGREES -> "°"
    NavigationField.NAUTICAL_MILES -> stringResource(R.string.nav_unit_nm)
    NavigationField.MINUTES -> "min"
    NavigationField.KNOTS -> "kn"
    NavigationField.LATITUDE_MINUTES -> "' N"
    NavigationField.LONGITUDE_MINUTES -> "' E"
    NavigationField.CLOCK, NavigationField.TEXT -> null
}

/** Result of the navigation part with self-grading for chart work and descriptions. */
@Composable
fun NavigationExamReview(part: NavigationExamPart, onRegrade: () -> Unit) {
    val settings by LocalApp.current.progressRepository.settings.collectAsStateWithLifecycle()
    Column(Modifier.fillMaxWidth().cardStyle().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SectionHeader(stringResource(R.string.nav_exam_task_n, part.task.number), Icons.Filled.Map)
        if (part.task.steps.any { part.autoResult(it) == null }) {
            Text(stringResource(R.string.nav_self_grade_hint), style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted)
        }
        part.task.steps.forEach { step ->
            val auto = part.autoResult(step)
            val graded = auto != null || part.selfGrades[step.number] != null
            val correct = part.isCorrect(step)
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row(verticalAlignment = Alignment.Top) {
                    Icon(when {
                        correct -> Icons.Filled.CheckCircle
                        graded -> Icons.Filled.Cancel
                        else -> Icons.Outlined.Circle
                    }, null, tint = when {
                        correct -> Sbf.colors.success
                        graded -> Sbf.colors.error
                        else -> Sbf.colors.muted
                    })
                    Spacer(Modifier.width(8.dp))
                    Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text("${step.number}. ${step.questionDe}", style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted,
                             maxLines = 2)
                        val given = part.inputs[step.number].orEmpty().filter { it.isNotBlank() }.joinToString(" · ")
                        if (given.isNotEmpty()) {
                            Text(stringResource(R.string.nav_your_answer, given), style = MaterialTheme.typography.bodyMedium,
                                 color = Sbf.colors.ink)
                        }
                        Text(stringResource(R.string.nav_official_answer, step.answerDe), style = MaterialTheme.typography.bodyMedium,
                             fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink)
                        if (settings.showEnglish) step.answerEn?.let {
                            Text(it, style = MaterialTheme.typography.bodySmall, fontStyle = FontStyle.Italic, color = Sbf.colors.inkSecondary)
                        }
                    }
                }
                if (auto == null) {
                    Row(Modifier.padding(start = 32.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        listOf(true, false).forEach { value ->
                            val selected = part.selfGrades[step.number] == value
                            val tint = if (value) Sbf.colors.success else Sbf.colors.error
                            OutlinedButton(
                                onClick = { part.selfGrades[step.number] = value; onRegrade() },
                                border = BorderStroke(1.dp, tint),
                                colors = androidx.compose.material3.ButtonDefaults.outlinedButtonColors(
                                    containerColor = if (selected) tint else androidx.compose.ui.graphics.Color.Transparent,
                                    contentColor = if (selected) androidx.compose.ui.graphics.Color.White else tint),
                            ) {
                                Text(stringResource(if (value) R.string.nav_self_right else R.string.wrong))
                            }
                        }
                    }
                }
            }
        }
    }
}
