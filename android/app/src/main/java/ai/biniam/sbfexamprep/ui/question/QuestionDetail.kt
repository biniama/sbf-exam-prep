package ai.biniam.sbfexamprep.ui.question

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.intl.LocaleList
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.Question
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.CategoryBadge
import ai.biniam.sbfexamprep.ui.components.ExamTypeBadge
import ai.biniam.sbfexamprep.ui.components.PrimaryButton
import ai.biniam.sbfexamprep.ui.components.QuestionMedia
import ai.biniam.sbfexamprep.ui.components.ReadableWidth
import ai.biniam.sbfexamprep.ui.components.SecondaryButton
import ai.biniam.sbfexamprep.ui.components.isGerman
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf

/**
 * Study view of one question out of [questions]. Tapping an answer checks it;
 * the stable shuffled order means the correct answer is not always "A".
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuestionDetail(
    questions: List<Question>,
    index: Int,
    onIndexChange: (Int) -> Unit,
    onBack: (() -> Unit)?,
    modifier: Modifier = Modifier,
) {
    val app = LocalApp.current
    val progress by app.progressRepository.progress.collectAsStateWithLifecycle()
    val settings by app.progressRepository.settings.collectAsStateWithLifecycle()
    val question = questions.getOrNull(index) ?: return
    var revealed by rememberSaveable(question.uniqueId) { mutableStateOf(false) }
    var picked by rememberSaveable(question.uniqueId) { mutableStateOf<String?>(null) }
    LaunchedEffect(question.uniqueId) { app.soundPlayer.stop() }
    val bookmarked = progress.isBookmarked(question.uniqueId)
    val many = questions.size > 1
    val isLast = index == questions.lastIndex

    Scaffold(
        modifier = modifier,
        containerColor = Sbf.colors.surface,
        topBar = {
            TopAppBar(
                title = {
                    Text(if (many) stringResource(R.string.n_of_m, index + 1, questions.size)
                         else stringResource(R.string.question_number, question.questionNumber))
                },
                navigationIcon = {
                    if (onBack != null) IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, stringResource(R.string.back))
                    }
                },
                actions = {
                    if (many) {
                        IconButton(onClick = { onIndexChange(index - 1) }, enabled = index > 0) {
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, stringResource(R.string.previous_question))
                        }
                        IconButton(onClick = { onIndexChange(index + 1) }, enabled = !isLast) {
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, stringResource(R.string.next_question))
                        }
                    }
                    IconButton(onClick = { app.progressRepository.updateProgress { it.toggleBookmark(question.uniqueId) } }) {
                        Icon(if (bookmarked) Icons.Filled.Bookmark else Icons.Filled.BookmarkBorder,
                             stringResource(if (bookmarked) R.string.remove_from_saved else R.string.save_question),
                             tint = if (bookmarked) Brand.gold else Sbf.colors.inkSecondary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Sbf.colors.surface),
            )
        },
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState())) {
            ReadableWidth {
                Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Row(verticalAlignment = Alignment.Top) {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            ExamTypeBadge(question.examType)
                            CategoryBadge(question.category(isGerman()))
                        }
                        Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(stringResource(R.string.number_short, question.questionNumber),
                                 style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold,
                                 color = Sbf.colors.inkSecondary)
                            progress.box(question.uniqueId)?.let {
                                Text(stringResource(R.string.review_box, it), style = MaterialTheme.typography.labelSmall,
                                     color = Sbf.colors.muted)
                            }
                        }
                    }
                    QuestionText(question, settings.showEnglish)
                    if (question.hasMedia) QuestionMedia(question)
                    Text(stringResource(R.string.tap_to_check), style = MaterialTheme.typography.labelMedium,
                         fontWeight = FontWeight.SemiBold, color = Sbf.colors.muted)
                    question.displayOptions.forEach { option ->
                        val showState = revealed || picked != null
                        val tint = when {
                            showState && option.isCorrect -> Sbf.colors.success
                            picked == option.key && !option.isCorrect -> Sbf.colors.error
                            else -> null
                        }
                        val state = when {
                            tint == null -> null
                            option.isCorrect -> stringResource(R.string.correct_answer)
                            else -> stringResource(R.string.wrong)
                        }
                        AnswerOption(option.key, option.option.german, option.option.english, settings.showEnglish, tint,
                                     icon = if (tint == null) null else option.isCorrect, stateDescription = state,
                                     enabled = !revealed) {
                            picked = option.key
                            revealed = true
                        }
                    }
                    AnimatedVisibility(revealed, enter = fadeIn() + slideInVertically { it / 3 }) {
                        ExplanationCard(question)
                    }
                    if (!revealed) {
                        PrimaryButton(stringResource(R.string.show_correct_answer), Icons.Filled.Visibility, { revealed = true })
                    }
                    if (many && !isLast) {
                        SecondaryButton(stringResource(R.string.next_question), Icons.AutoMirrored.Filled.ArrowForward,
                                        { onIndexChange(index + 1) })
                    }
                }
            }
        }
    }
}

/** German question text (as in the exam) with the optional English translation. */
@Composable
fun QuestionText(question: Question, showEnglish: Boolean, modifier: Modifier = Modifier) {
    Column(
        modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Brand.navyLight.copy(alpha = 0.08f)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(question.germanText, style = MaterialTheme.typography.bodyLarge.copy(localeList = LocaleList("de")),
             fontWeight = FontWeight.Medium, color = Sbf.colors.ink, modifier = Modifier.semantics { heading() })
        if (showEnglish && question.englishText.isNotEmpty()) {
            Text(question.englishText, style = MaterialTheme.typography.bodyMedium, fontStyle = FontStyle.Italic,
                 color = Sbf.colors.inkSecondary)
        }
    }
}

/**
 * One answer. [tint] colours it after checking; [icon] true shows a check mark, false a cross.
 */
@Composable
fun AnswerOption(
    key: String,
    german: String,
    english: String,
    showEnglish: Boolean,
    tint: Color?,
    icon: Boolean?,
    stateDescription: String?,
    enabled: Boolean,
    onClick: () -> Unit,
) {
    val label = stringResource(R.string.answer_label, key, german)
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = RoundedCornerShape(14.dp),
        color = tint?.copy(alpha = 0.10f) ?: Sbf.colors.card,
        modifier = Modifier.fillMaxWidth()
            .border(1.5.dp, tint?.copy(alpha = 0.6f) ?: Sbf.colors.hairline, RoundedCornerShape(14.dp))
            .semantics(mergeDescendants = true) {
                contentDescription = label
                stateDescription?.let { this.stateDescription = it }
            },
    ) {
        Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(32.dp).clip(CircleShape).background(tint?.copy(alpha = 0.15f) ?: Brand.navyLight.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center,
            ) {
                Text(key, style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold,
                     color = tint ?: Sbf.colors.inkSecondary)
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(german, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink)
                if (showEnglish && english.isNotEmpty()) {
                    Text(english, style = MaterialTheme.typography.bodySmall, fontStyle = FontStyle.Italic, color = Sbf.colors.muted)
                }
            }
            if (icon != null && tint != null) {
                Spacer(Modifier.width(8.dp))
                Icon(if (icon) Icons.Filled.CheckCircle else Icons.Filled.Cancel, null, tint = tint)
            }
        }
    }
}

/** Shows the correct answer and why it is correct. */
@Composable
fun ExplanationCard(question: Question) {
    val success = Sbf.colors.success
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(success.copy(alpha = 0.08f))
            .border(1.dp, success.copy(alpha = 0.3f), RoundedCornerShape(14.dp)).padding(14.dp)
            .semantics(mergeDescendants = true) { liveRegion = LiveRegionMode.Polite },
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.CheckCircle, null, tint = success, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(6.dp))
            Text(stringResource(R.string.correct_answer), style = MaterialTheme.typography.titleSmall,
                 fontWeight = FontWeight.SemiBold, color = success)
        }
        Text(question.correctText?.german.orEmpty(), style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink)
        question.explanation(isGerman())?.let {
            HorizontalDivider(color = Sbf.colors.hairline)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Lightbulb, null, tint = Brand.gold, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(6.dp))
                Text(stringResource(R.string.why), style = MaterialTheme.typography.titleSmall,
                     fontWeight = FontWeight.SemiBold, color = Brand.gold)
            }
            Text(it, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink)
        }
    }
}
