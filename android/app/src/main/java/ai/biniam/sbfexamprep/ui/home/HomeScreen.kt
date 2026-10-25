package ai.biniam.sbfexamprep.ui.home

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.windowInsetsTopHeight
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FormatListNumbered
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Sailing
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.automirrored.filled.StarHalf
import androidx.compose.material.icons.filled.StarOutline
import androidx.compose.material.icons.filled.Stars
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ai.biniam.sbfexamprep.R
import androidx.compose.material.icons.filled.Map
import ai.biniam.sbfexamprep.data.FeatureFlag
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.data.QuizRecord
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.Layout
import ai.biniam.sbfexamprep.ui.components.LightStatusBarIcons
import ai.biniam.sbfexamprep.ui.components.PrimaryButton
import ai.biniam.sbfexamprep.ui.components.ReadableWidth
import ai.biniam.sbfexamprep.ui.components.SectionHeader
import ai.biniam.sbfexamprep.ui.components.StatCard
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.components.currentLocale
import ai.biniam.sbfexamprep.data.ExamFormat
import ai.biniam.sbfexamprep.data.ExamRules
import ai.biniam.sbfexamprep.ui.components.examFormatTitle
import ai.biniam.sbfexamprep.ui.components.examSummary
import ai.biniam.sbfexamprep.ui.settings.LicenceDialog
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.rememberSaveable
import ai.biniam.sbfexamprep.ui.components.examTypeTitle
import ai.biniam.sbfexamprep.ui.components.percent
import ai.biniam.sbfexamprep.ui.components.relativeTime
import ai.biniam.sbfexamprep.ui.quiz.QuizViewModel
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf
import java.time.LocalDate
import java.time.format.TextStyle

@Composable
fun HomeScreen(quiz: QuizViewModel, onBrowse: () -> Unit, onNavigation: () -> Unit = {}) {
    val app = LocalApp.current
    val progress by app.progressRepository.progress.collectAsStateWithLifecycle()
    val settings by app.progressRepository.settings.collectAsStateWithLifecycle()
    val flags by app.featureFlags.enabled.collectAsStateWithLifecycle()
    val now = System.currentTimeMillis()
    val today = LocalDate.now()
    val due = progress.dueCount(now)

    val stats = @Composable {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatCard("${progress.totalAnswered}", stringResource(R.string.answered), Icons.Filled.CheckCircle,
                     Sbf.colors.success, Modifier.weight(1f))
            StatCard("${progress.masteredCount}", stringResource(R.string.mastered), Icons.Filled.Stars,
                     Brand.gold, Modifier.weight(1f))
            StatCard("${progress.dailyStreak(today)}", stringResource(R.string.day_streak), Icons.Filled.LocalFireDepartment,
                     Sbf.colors.error, Modifier.weight(1f))
        }
    }
    val todayCard = @Composable {
        TodayCard(due) {
            if (due > 0) quiz.setupDueReview() else quiz.setup(ExamType.ALL, settings.quizCount)
        }
    }
    val streak = @Composable { StreakSection(progress.dailyStreak(today), progress.last7Days(today)) }
    val actions = @Composable {
        QuickActions(settings.quizCount, settings.licenceGoal.examFormats, progress.wrongAnswerCount, quiz, onBrowse,
                     if (FeatureFlag.NAVIGATION_TASKS in flags) onNavigation else null)
    }
    var editLicence by rememberSaveable { mutableStateOf(false) }
    if (editLicence) LicenceDialog(onDismiss = { editLicence = false })
    // Shown until a licence is picked – also announces the sailing questions to existing users.
    val licencePrompt = @Composable {
        if (!settings.hasChosenLicence) {
            ActionRow(Icons.Filled.Sailing, Brand.gold, stringResource(R.string.new_sailing),
                      stringResource(R.string.new_sailing_sub)) { editLicence = true }
        }
    }
    val recent = @Composable { RecentSection(progress.quizHistory.take(4), now) }

    LightStatusBarIcons()
    Box(Modifier.fillMaxSize()) {
    Column(Modifier.fillMaxSize().background(Sbf.colors.surface).verticalScroll(rememberScrollState())) {
        Header(progress.overallAccuracy)
        BoxWithConstraints(Modifier.padding(horizontal = 20.dp).padding(top = 20.dp, bottom = 32.dp)) {
            val wide = maxWidth >= 700.dp
            ReadableWidth(Layout.wideWidth) {
                if (wide) {
                    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                        licencePrompt()
                        stats()
                        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(16.dp)) { todayCard(); actions() }
                            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(16.dp)) { streak(); recent() }
                        }
                    }
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                        licencePrompt(); stats(); todayCard(); streak(); actions(); recent()
                    }
                }
            }
        }
    }
    // Keeps the status bar readable when the header has scrolled away.
    Spacer(Modifier.fillMaxWidth().windowInsetsTopHeight(WindowInsets.statusBars).background(Brand.navy))
    }
}

@Composable
private fun Header(accuracy: Double) {
    Box(Modifier.fillMaxWidth().background(Brand.navyGradient), contentAlignment = Alignment.Center) {
        Column(
            Modifier.windowInsetsPadding(WindowInsets.statusBars).padding(top = 20.dp, bottom = 28.dp, start = 24.dp, end = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(Icons.Filled.Sailing, null, Modifier.size(40.dp), tint = Brand.gold)
            Text(stringResource(R.string.app_name), style = MaterialTheme.typography.headlineMedium,
                 fontWeight = FontWeight.Bold, color = Color.White, modifier = Modifier.semantics { heading() })
            Text(stringResource(R.string.app_subtitle), style = MaterialTheme.typography.bodyMedium,
                 color = Color.White.copy(alpha = 0.75f))
            AccuracyRing(accuracy, Modifier.padding(top = 6.dp))
        }
    }
}

@Composable
private fun AccuracyRing(accuracy: Double, modifier: Modifier = Modifier) {
    val animated by animateFloatAsState(accuracy.toFloat(), tween(1000), label = "accuracy")
    val label = stringResource(R.string.accuracy)
    val value = percent(accuracy, currentLocale())
    Box(modifier.size(110.dp).clearAndSetSemantics { contentDescription = "$label: $value" }, contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize().padding(5.dp)) {
            val stroke = Stroke(width = 10.dp.toPx(), cap = StrokeCap.Round)
            drawArc(Color.White.copy(alpha = 0.15f), 0f, 360f, false, style = stroke)
            drawArc(Brand.gold, -90f, 360f * animated, false, style = stroke,
                    topLeft = Offset.Zero, size = Size(size.width, size.height))
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = Color.White)
            Text(label, style = MaterialTheme.typography.labelSmall, color = Color.White.copy(alpha = 0.7f))
        }
    }
}

@Composable
private fun TodayCard(due: Int, onStart: () -> Unit) {
    Column(Modifier.cardStyle().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SectionHeader(stringResource(R.string.today), Icons.Filled.CalendarToday)
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(if (due > 0) Icons.Filled.Replay else Icons.Filled.Verified, null, Modifier.size(34.dp),
                 tint = if (due > 0) Brand.gold else Sbf.colors.success)
            Spacer(Modifier.width(14.dp))
            Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(if (due > 0) pluralStringResource(R.plurals.questions_due_for_review, due, due) else stringResource(R.string.nothing_due),
                     style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink)
                Text(stringResource(if (due > 0) R.string.due_explainer else R.string.nothing_due_explainer),
                     style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted)
            }
        }
        PrimaryButton(stringResource(if (due > 0) R.string.start_review else R.string.start_quick_quiz),
                      if (due > 0) Icons.Filled.PlayArrow else Icons.Filled.Bolt, onStart)
    }
}

@Composable
private fun StreakSection(streak: Int, days: List<Pair<LocalDate, Boolean>>) {
    val locale = currentLocale()
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            SectionHeader(stringResource(R.string.study_streak), Icons.Filled.LocalFireDepartment, Modifier.weight(1f))
            Text(
                pluralStringResource(R.plurals.days, streak, streak),
                Modifier.clip(CircleShape)
                    .background(if (streak > 0) Brand.goldGradient else androidx.compose.ui.graphics.SolidColor(Color.Gray))
                    .padding(horizontal = 10.dp, vertical = 4.dp),
                style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold,
                color = if (streak > 0) Brand.navy else Color.White,
            )
        }
        val studied = stringResource(R.string.studied)
        val notStudied = stringResource(R.string.not_studied)
        Row(Modifier.cardStyle().padding(14.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            days.forEach { (date, done) ->
                val weekday = date.dayOfWeek.getDisplayName(TextStyle.FULL, locale)
                Column(
                    Modifier.weight(1f).clearAndSetSemantics { contentDescription = "$weekday: ${if (done) studied else notStudied}" },
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Box(
                        Modifier.size(34.dp).clip(CircleShape)
                            .background(if (done) Brand.gold else Brand.navyLight.copy(alpha = 0.15f)),
                        contentAlignment = Alignment.Center,
                    ) {
                        if (done) Icon(Icons.Filled.Check, null, Modifier.size(16.dp), tint = Brand.navy)
                    }
                    Text(date.dayOfWeek.getDisplayName(TextStyle.NARROW, locale), style = MaterialTheme.typography.labelSmall,
                         color = if (done) Sbf.colors.ink else Sbf.colors.muted)
                }
            }
        }
    }
}

@Composable
private fun QuickActions(quizCount: Int, formats: List<ExamFormat>, mistakes: Int, quiz: QuizViewModel, onBrowse: () -> Unit,
                         onNavigation: (() -> Unit)?) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        SectionHeader(stringResource(R.string.quick_start), Icons.Filled.Bolt)
        ActionRow(Icons.Filled.PlayCircle, Brand.navy, stringResource(R.string.quick_quiz),
                  pluralStringResource(R.plurals.random_questions, quizCount, quizCount)) {
            quiz.setup(ExamType.ALL, quizCount)
        }
        formats.forEach { format ->
            ActionRow(Icons.Filled.Timer, if (format == ExamFormat.SEE) Brand.navyLight else Brand.oceanTeal,
                      stringResource(R.string.exam_sim_type, examFormatTitle(format)), examSummary(ExamRules(format))) {
                quiz.setupExam(format)
            }
        }
        if (onNavigation != null) {
            ActionRow(Icons.Filled.Map, Brand.oceanTeal, stringResource(R.string.nav_home_title),
                      stringResource(R.string.nav_home_sub), onNavigation)
        }
        if (mistakes > 0) {
            ActionRow(Icons.Filled.Replay, Sbf.colors.error, stringResource(R.string.practise_mistakes),
                      pluralStringResource(R.plurals.questions_to_retry, mistakes, mistakes)) { quiz.setupMistakes() }
        }
        ActionRow(Icons.Filled.FormatListNumbered, Brand.gold, stringResource(R.string.all_in_order),
                  stringResource(R.string.all_in_order_sub), onBrowse)
    }
}

@Composable
fun ActionRow(icon: ImageVector, color: Color, title: String, subtitle: String, onClick: () -> Unit) {
    Surface(onClick = onClick, shape = RoundedCornerShape(16.dp), color = Color.Transparent) {
        Row(Modifier.cardStyle().padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(44.dp).clip(RoundedCornerShape(12.dp)).background(color), contentAlignment = Alignment.Center) {
                Icon(icon, null, tint = Color.White)
            }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink)
                Text(subtitle, style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted)
            }
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Sbf.colors.muted)
        }
    }
}

@Composable
private fun RecentSection(records: List<QuizRecord>, now: Long) {
    if (records.isEmpty()) return
    val locale = currentLocale()
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        SectionHeader(stringResource(R.string.recent_quizzes), Icons.Filled.History)
        records.forEach { record ->
            val exam = record.isExam == true
            val passed = record.passed == true
            val (icon, tint) = when {
                exam && passed -> Icons.Filled.Verified to Sbf.colors.success
                exam -> Icons.Filled.Cancel to Sbf.colors.error
                record.accuracy >= 0.8 -> Icons.Filled.Star to Brand.gold
                record.accuracy >= 0.6 -> Icons.AutoMirrored.Filled.StarHalf to Sbf.colors.muted
                else -> Icons.Filled.StarOutline to Sbf.colors.muted
            }
            Row(Modifier.cardStyle().padding(12.dp).semantics(mergeDescendants = true) {}, verticalAlignment = Alignment.CenterVertically) {
                Icon(icon, null, tint = tint)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    val type = record.format?.let { examFormatTitle(it) } ?: examTypeTitle(record.type)
                    Text(stringResource(if (exam) R.string.recent_exam else R.string.recent_quiz, type),
                         style = MaterialTheme.typography.titleSmall, color = Sbf.colors.ink)
                    Text(relativeTime(record.date, now, locale), style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted)
                }
                Text(stringResource(R.string.score_fraction, record.correctAnswers, record.totalQuestions),
                     style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold,
                     color = if (record.accuracy >= 0.6) Sbf.colors.success else Sbf.colors.error)
            }
        }
    }
}
