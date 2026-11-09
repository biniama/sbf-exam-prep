package ai.biniam.sbfexamprep.ui.quiz

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.Assignment
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.ui.navigation.NavigationExamReview
import ai.biniam.sbfexamprep.data.NavigationExamPart
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.CountPill
import ai.biniam.sbfexamprep.ui.components.Layout
import ai.biniam.sbfexamprep.ui.components.PrimaryButton
import ai.biniam.sbfexamprep.ui.components.ReadableWidth
import ai.biniam.sbfexamprep.ui.components.SecondaryButton
import ai.biniam.sbfexamprep.ui.components.SectionHeader
import ai.biniam.sbfexamprep.ui.components.StatCard
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.components.currentLocale
import ai.biniam.sbfexamprep.ui.components.examTypeIcon
import ai.biniam.sbfexamprep.ui.components.examFormatIcon
import ai.biniam.sbfexamprep.ui.components.examFormatShortTitle
import ai.biniam.sbfexamprep.ui.components.examTypeTitle
import ai.biniam.sbfexamprep.ui.components.partTitle
import ai.biniam.sbfexamprep.ui.components.percent
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuizResultScreen(vm: QuizViewModel, onReview: (String) -> Unit) {
    val app = LocalApp.current
    BackHandler(onBack = vm::close)
    val total = vm.questions.size
    val accuracy = if (total == 0) 0.0 else vm.correctCount.toDouble() / total
    val result = vm.examResult
    val grade = when {
        result != null -> if (result.passed) R.string.passed else R.string.not_passed
        accuracy >= 0.9 -> R.string.excellent
        accuracy >= 0.75 -> R.string.great_job
        accuracy >= 0.6 -> R.string.good_effort
        else -> R.string.keep_practising
    }
    val gradeColor = when {
        result != null -> if (result.passed) Sbf.colors.success else Sbf.colors.error
        accuracy >= 0.8 -> Sbf.colors.success
        accuracy >= 0.6 -> Brand.gold
        else -> Sbf.colors.error
    }

    Scaffold(
        containerColor = Sbf.colors.surface,
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.results)) },
                actions = { TextButton(onClick = vm::close) { Text(stringResource(R.string.done), fontWeight = FontWeight.SemiBold) } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Sbf.colors.surface),
            )
        },
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState())) {
            ReadableWidth(Layout.readableWidth) {
                Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                    // Score
                    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally,
                           verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        ScoreRing(accuracy, gradeColor)
                        Text(stringResource(grade), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold,
                             color = gradeColor, modifier = Modifier.semantics { heading() })
                        if (result != null) {
                            Text(stringResource(if (result.passed) R.string.exam_passed else R.string.exam_not_passed),
                                 style = MaterialTheme.typography.titleSmall, color = Sbf.colors.ink)
                        }
                        Text(stringResource(R.string.answered_correctly, vm.correctCount, total),
                             style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.muted)
                    }

                    // Official scoring
                    if (result != null) {
                        Column(Modifier.cardStyle().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            SectionHeader(stringResource(R.string.official_scoring), Icons.AutoMirrored.Filled.Assignment)
                            result.rules.parts.forEach { part ->
                                PartRow(partTitle(part.type), result.correct(part), part.count, part.passMark,
                                        if (part.passMark == null) null else result.passed(part))
                            }
                            if (result.rules.includesNavigation) {
                                PartRow(stringResource(R.string.nav_exam_title), result.navigationCorrect ?: 0,
                                        result.rules.navigationCount, NavigationExamPart.PASS_MARK, result.navigationPassed)
                            }
                            val totalPassMark = result.rules.totalPassMark
                            if (totalPassMark != null) {
                                PartRow(stringResource(R.string.total), result.totalCorrect, result.rules.totalCount,
                                        totalPassMark, result.totalPassed)
                                Text(stringResource(R.string.total_only), style = MaterialTheme.typography.bodySmall,
                                     color = Sbf.colors.muted)
                            } else if (result.rules.parts.size > 1 || result.rules.includesNavigation) {
                                Text(stringResource(R.string.each_part), style = MaterialTheme.typography.bodySmall,
                                     color = Sbf.colors.muted)
                            }
                            if (result.rules.excludesNavigationTask) {
                                Text(stringResource(R.string.navigation_task_note), style = MaterialTheme.typography.bodySmall,
                                     color = Sbf.colors.muted)
                            }
                        }
                    }

                    vm.navigationPart?.let { NavigationExamReview(it, vm::regradeNavigation) }

                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        StatCard("${vm.correctCount}", stringResource(R.string.correct), Icons.Filled.CheckCircle,
                                 Sbf.colors.success, Modifier.weight(1f))
                        StatCard("${vm.wrongIds.size}", stringResource(R.string.wrong), Icons.Filled.Cancel,
                                 Sbf.colors.error, Modifier.weight(1f))
                        val format = result?.rules?.format
                        StatCard(format?.let { examFormatShortTitle(it) } ?: examTypeTitle(vm.examType), stringResource(R.string.exam),
                                 format?.let { examFormatIcon(it) } ?: examTypeIcon(vm.examType), Brand.navyLight, Modifier.weight(1f))
                    }

                    // Mistakes
                    if (vm.wrongIds.isNotEmpty()) {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                SectionHeader(stringResource(R.string.review_mistakes), Icons.Filled.ErrorOutline, Modifier.weight(1f))
                                CountPill(vm.wrongIds.size)
                            }
                            vm.wrongIds.mapNotNull(app.questions::question).forEach { q ->
                                Row(Modifier.cardStyle(12.dp).clickable { onReview(q.uniqueId) }.padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Filled.Cancel, null, Modifier.size(20.dp), tint = Sbf.colors.error)
                                    Spacer(Modifier.width(10.dp))
                                    Text(q.germanText, Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium,
                                         color = Sbf.colors.ink, maxLines = 2, overflow = TextOverflow.Ellipsis)
                                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Sbf.colors.muted)
                                }
                            }
                        }
                    }

                    // Actions
                    PrimaryButton(stringResource(if (vm.examMode) R.string.new_exam_sim else R.string.retry_questions),
                                  Icons.Filled.Refresh, vm::retry)
                    if (vm.wrongIds.isNotEmpty()) {
                        val wrong = vm.wrongIds.mapNotNull(app.questions::question)
                        SecondaryButton(pluralStringResource(R.plurals.practise_the_mistakes, wrong.size, wrong.size),
                                        Icons.Filled.Cancel, { vm.setup(wrong, QuizMode.Mistakes) })
                    }
                    SecondaryButton(stringResource(R.string.done), null, vm::close)
                }
            }
        }
    }
}

@Composable
private fun ScoreRing(accuracy: Double, color: Color) {
    Box(Modifier.size(140.dp), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize().padding(6.dp)) {
            val stroke = Stroke(12.dp.toPx(), cap = StrokeCap.Round)
            drawArc(color.copy(alpha = 0.15f), 0f, 360f, false, style = stroke)
            if (accuracy > 0) drawArc(color, -90f, 360f * accuracy.toFloat(), false, style = stroke)
        }
        Text(percent(accuracy, currentLocale()), style = MaterialTheme.typography.headlineMedium,
             fontWeight = FontWeight.Bold, color = Sbf.colors.ink)
    }
}

@Composable
/** [passed] is null when the part has no pass mark of its own (only the total counts). */
private fun PartRow(title: String, correct: Int, total: Int, passMark: Int?, passed: Boolean?) {
    val color = when (passed) {
        true -> Sbf.colors.success
        false -> Sbf.colors.error
        null -> Sbf.colors.muted
    }
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(when (passed) {
            true -> Icons.Filled.CheckCircle
            false -> Icons.Filled.Cancel
            null -> Icons.Outlined.Circle
        }, null, tint = color)
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleSmall, color = Sbf.colors.ink)
            if (passMark != null) {
                Text(stringResource(R.string.pass_mark, passMark, total), style = MaterialTheme.typography.bodySmall,
                     color = Sbf.colors.muted)
            }
        }
        Text(stringResource(R.string.score_fraction, correct, total), style = MaterialTheme.typography.titleMedium,
             fontWeight = FontWeight.Bold, textAlign = TextAlign.End, color = color)
    }
}
