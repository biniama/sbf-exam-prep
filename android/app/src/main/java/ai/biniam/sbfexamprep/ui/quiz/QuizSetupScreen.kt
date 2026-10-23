package ai.biniam.sbfexamprep.ui.quiz

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FormatListNumbered
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.FindInPage
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Numbers
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.RadioButtonChecked
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Sell
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.ExposedDropdownMenuAnchorType
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.ExamFormat
import ai.biniam.sbfexamprep.data.ExamRules
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.CountPill
import ai.biniam.sbfexamprep.ui.components.PrimaryButton
import ai.biniam.sbfexamprep.ui.components.ReadableWidth
import ai.biniam.sbfexamprep.ui.components.SectionHeader
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.components.examTypeIcon
import ai.biniam.sbfexamprep.ui.components.isGerman
import ai.biniam.sbfexamprep.ui.components.examFormatIcon
import ai.biniam.sbfexamprep.ui.components.examFormatTitle
import ai.biniam.sbfexamprep.ui.components.examPassText
import ai.biniam.sbfexamprep.ui.components.examSummary
import ai.biniam.sbfexamprep.ui.components.licenceName
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf

private enum class SetupMode { PRACTICE, REVIEW, MISTAKES, EXAM }

private val COUNTS = listOf(10, 20, 30, 50)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuizSetupScreen(quiz: QuizViewModel) {
    val app = LocalApp.current
    val progress by app.progressRepository.progress.collectAsStateWithLifecycle()
    val settings by app.progressRepository.settings.collectAsStateWithLifecycle()
    var mode by rememberSaveable { mutableStateOf(SetupMode.PRACTICE) }
    var examType by rememberSaveable { mutableStateOf(ExamType.ALL) }
    val formats = settings.licenceGoal.examFormats
    var chosenExam by rememberSaveable { mutableStateOf(formats.first()) }
    val exam = if (chosenExam in formats) chosenExam else formats.first()
    var category by rememberSaveable { mutableStateOf<String?>(null) }
    var count by rememberSaveable { mutableIntStateOf(settings.quizCount) }

    val now = System.currentTimeMillis()
    val due = progress.dueCount(now)
    val mistakes = progress.wrongAnswerCount
    val rules = ExamRules(exam)
    val available = when (mode) {
        SetupMode.PRACTICE -> app.questions.questions(examType, category).size
        SetupMode.REVIEW -> due
        SetupMode.MISTAKES -> mistakes
        SetupMode.EXAM -> rules.totalCount
    }
    val startCount = when (mode) {
        SetupMode.PRACTICE -> minOf(count, available)
        else -> minOf(30, available)
    }

    Scaffold(
        containerColor = Sbf.colors.surface,
        topBar = {
            TopAppBar(title = { Text(stringResource(R.string.tab_quiz)) },
                      colors = TopAppBarDefaults.topAppBarColors(containerColor = Sbf.colors.surface))
        },
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState())) {
            ReadableWidth {
                Column(Modifier.padding(start = 20.dp, end = 20.dp, bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    // Hero
                    Column(
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(Brand.navyGradient).padding(vertical = 24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Icon(if (mode == SetupMode.EXAM) Icons.Filled.Timer else Icons.Filled.Psychology, null,
                             Modifier.size(40.dp), tint = Brand.gold)
                        Text(stringResource(if (mode == SetupMode.EXAM) R.string.exam_simulation else R.string.configure_quiz),
                             style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = Color.White)
                        Text(pluralStringResource(R.plurals.questions_available, available, available),
                             style = MaterialTheme.typography.bodyMedium, color = Color.White.copy(alpha = 0.75f))
                    }

                    SectionCard(stringResource(R.string.mode), Icons.Filled.Tune) {
                        ModeRow(mode == SetupMode.PRACTICE, Icons.Filled.Layers, stringResource(R.string.practice),
                                stringResource(R.string.practice_sub)) { mode = SetupMode.PRACTICE }
                        ModeRow(mode == SetupMode.REVIEW, Icons.Filled.Replay, stringResource(R.string.due_for_review),
                                pluralStringResource(R.plurals.questions_due_today, due, due), due) { mode = SetupMode.REVIEW }
                        ModeRow(mode == SetupMode.MISTAKES, Icons.Filled.Cancel, stringResource(R.string.mistakes),
                                pluralStringResource(R.plurals.questions_answered_wrongly, mistakes, mistakes), mistakes) {
                            mode = SetupMode.MISTAKES
                        }
                        ModeRow(mode == SetupMode.EXAM, Icons.Filled.Timer, stringResource(R.string.exam_simulation),
                                stringResource(R.string.exam_sim_sub)) { mode = SetupMode.EXAM }
                    }

                    when (mode) {
                        SetupMode.PRACTICE -> {
                            SectionCard(stringResource(R.string.exam), Icons.Filled.FormatListNumbered) {
                                listOf(ExamType.ALL, ExamType.BINNEN, ExamType.SEGELN, ExamType.SEE, ExamType.SHARED).forEach { t ->
                                    ModeRow(examType == t, examTypeIcon(t), licenceName(t),
                                            pluralStringResource(R.plurals.questions_count, app.questions.questions(t).size,
                                                                 app.questions.questions(t).size)) {
                                        examType = t
                                        category = null
                                    }
                                }
                            }
                            SectionCard(stringResource(R.string.topic_optional), Icons.Filled.Sell) {
                                TopicDropdown(examType, category) { category = it }
                            }
                            SectionCard(stringResource(R.string.number_of_questions), Icons.Filled.Numbers) {
                                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                                    COUNTS.forEachIndexed { i, n ->
                                        SegmentedButton(count == n, { count = n }, SegmentedButtonDefaults.itemShape(i, COUNTS.size)) {
                                            Text("$n")
                                        }
                                    }
                                }
                            }
                        }
                        SetupMode.REVIEW -> InfoCard(Icons.Filled.Replay, stringResource(R.string.spaced_repetition),
                                                     stringResource(R.string.spaced_repetition_text))
                        SetupMode.MISTAKES -> InfoCard(Icons.Filled.Cancel, stringResource(R.string.your_mistakes),
                                                       stringResource(R.string.your_mistakes_text))
                        SetupMode.EXAM -> SectionCard(stringResource(R.string.exam), Icons.Filled.FindInPage) {
                            formats.forEach { f ->
                                ModeRow(exam == f, examFormatIcon(f), examFormatTitle(f), examSummary(ExamRules(f))) {
                                    chosenExam = f
                                }
                            }
                            RuleRow(Icons.Filled.Verified, examPassText(rules))
                            RuleRow(Icons.Filled.Timer, pluralStringResource(R.plurals.time_limit_minutes, rules.minutes, rules.minutes))
                            RuleRow(Icons.Filled.VisibilityOff, stringResource(R.string.rules_feedback))
                            if (rules.excludesNavigationTask) RuleRow(Icons.Filled.Map, stringResource(R.string.rules_navigation))
                            if (rules.totalPassMark == null && rules.parts.size > 1) {
                                RuleRow(Icons.Filled.FormatListNumbered, stringResource(R.string.each_part))
                            }
                            Text(stringResource(R.string.rules_source), style = MaterialTheme.typography.labelSmall,
                                 color = Sbf.colors.muted)
                        }
                    }

                    PrimaryButton(
                        if (mode == SetupMode.EXAM) stringResource(R.string.start_exam_sim)
                        else pluralStringResource(R.plurals.start_n_questions, startCount, startCount),
                        Icons.Filled.PlayArrow,
                        onClick = {
                            when (mode) {
                                SetupMode.PRACTICE -> quiz.setup(examType, count, category)
                                SetupMode.REVIEW -> quiz.setupDueReview()
                                SetupMode.MISTAKES -> quiz.setupMistakes()
                                SetupMode.EXAM -> quiz.setupExam(exam)
                            }
                        },
                        enabled = startCount > 0,
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionCard(title: String, icon: ImageVector, content: @Composable () -> Unit) {
    Column(Modifier.cardStyle().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        SectionHeader(title, icon)
        content()
    }
}

@Composable
private fun ModeRow(active: Boolean, icon: ImageVector, title: String, subtitle: String, badge: Int = 0, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
            .background(if (active) Brand.navyLight.copy(alpha = 0.12f) else Color.Transparent)
            .border(1.dp, if (active) Brand.navyLight.copy(alpha = 0.5f) else Sbf.colors.hairline.copy(alpha = 0.5f),
                    RoundedCornerShape(12.dp))
            .selectable(active, role = Role.RadioButton, onClick = onClick)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = if (active) Brand.gold else Sbf.colors.inkSecondary)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink)
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted)
        }
        if (badge > 0) {
            CountPill(badge)
            Spacer(Modifier.width(8.dp))
        }
        Icon(if (active) Icons.Filled.RadioButtonChecked else Icons.Filled.RadioButtonUnchecked, null,
             tint = if (active) Brand.navyLight else Sbf.colors.muted)
    }
}

@Composable
private fun RuleRow(icon: ImageVector, text: String) {
    Row(verticalAlignment = Alignment.Top) {
        Icon(icon, null, Modifier.size(20.dp), tint = Brand.gold)
        Spacer(Modifier.width(10.dp))
        Text(text, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink)
    }
}

@Composable
private fun InfoCard(icon: ImageVector, title: String, text: String) {
    Column(Modifier.cardStyle().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        SectionHeader(title, icon)
        Text(text, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TopicDropdown(type: ExamType, category: String?, onSelect: (String?) -> Unit) {
    val app = LocalApp.current
    val german = isGerman()
    var expanded by rememberSaveable { mutableStateOf(false) }
    val allTopics = stringResource(R.string.all_topics)
    ExposedDropdownMenuBox(expanded, { expanded = it }) {
        OutlinedTextField(
            value = category?.let { app.questions.categoryName(it, german) } ?: allTopics,
            onValueChange = {}, readOnly = true, singleLine = true,
            label = { Text(stringResource(R.string.topic)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded) },
            modifier = Modifier.fillMaxWidth().menuAnchor(ExposedDropdownMenuAnchorType.PrimaryNotEditable),
        )
        ExposedDropdownMenu(expanded, { expanded = false }) {
            DropdownMenuItem(text = { Text(allTopics) }, onClick = { onSelect(null); expanded = false },
                             leadingIcon = if (category == null) ({ Icon(Icons.Filled.CheckCircle, null) }) else null)
            app.questions.categories(type, german).forEach { key ->
                DropdownMenuItem(
                    text = { Text(app.questions.categoryName(key, german)) },
                    onClick = { onSelect(key); expanded = false },
                    leadingIcon = if (category == key) ({ Icon(Icons.Filled.CheckCircle, null) }) else null,
                )
            }
        }
    }
}
