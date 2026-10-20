package ai.biniam.sbfexamprep.ui.quiz

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
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
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.components.examTypeTitle
import ai.biniam.sbfexamprep.ui.components.isGerman
import ai.biniam.sbfexamprep.ui.question.AnswerOption
import ai.biniam.sbfexamprep.ui.question.QuestionDetail
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf

@Composable
fun QuizScreen(vm: QuizViewModel) {
    var reviewId by rememberSaveable { mutableStateOf<String?>(null) }
    val app = LocalApp.current
    val review = reviewId?.let(app.questions::question)
    when {
        review != null -> {
            BackHandler { reviewId = null }
            QuestionDetail(listOf(review), 0, {}, { reviewId = null })
        }
        vm.phase == QuizPhase.FINISHED -> QuizResultScreen(vm, onReview = { reviewId = it })
        vm.current != null -> QuestionScreen(vm, vm.current!!)
        else -> EmptyQuiz(vm)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun QuestionScreen(vm: QuizViewModel, q: Question) {
    val app = LocalApp.current
    val progress by app.progressRepository.progress.collectAsStateWithLifecycle()
    val settings by app.progressRepository.settings.collectAsStateWithLifecycle()
    var confirmQuit by rememberSaveable { mutableStateOf(false) }
    val haptics = LocalHapticFeedback.current
    val close = { if (vm.examMode && vm.currentIndex > 0) confirmQuit = true else vm.close() }
    BackHandler(onBack = close)
    val bookmarked = progress.isBookmarked(q.uniqueId)

    Scaffold(
        containerColor = Sbf.colors.surface,
        topBar = {
            Column {
                TopAppBar(
                    title = {
                        val label = stringResource(R.string.question_n_of_m, vm.currentIndex + 1, vm.questions.size)
                        Text(stringResource(R.string.progress_fraction, vm.currentIndex + 1, vm.questions.size),
                             style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold,
                             modifier = Modifier.clearAndSetSemantics { contentDescription = label })
                    },
                    navigationIcon = {
                        IconButton(onClick = close) { Icon(Icons.Filled.Close, stringResource(R.string.close_quiz)) }
                    },
                    actions = {
                        IconButton(onClick = vm::toggleBookmark) {
                            Icon(if (bookmarked) Icons.Filled.Bookmark else Icons.Filled.BookmarkBorder,
                                 stringResource(if (bookmarked) R.string.remove_from_saved else R.string.save_question),
                                 tint = Brand.gold)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = Sbf.colors.surface),
                )
                LinearProgressIndicator(progress = { vm.progressFraction }, Modifier.fillMaxWidth(), color = Brand.navyLight,
                                        trackColor = Brand.navyLight.copy(alpha = 0.15f), drawStopIndicator = {})
                vm.examRules?.let { rules ->
                    val color = if (vm.timeRemaining > 300) Sbf.colors.success else Sbf.colors.error
                    val remaining = stringResource(R.string.time_remaining, vm.formattedTime)
                    Row(
                        Modifier.fillMaxWidth().background(Sbf.colors.card).padding(horizontal = 16.dp, vertical = 6.dp)
                            .clearAndSetSemantics { contentDescription = remaining },
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.Timer, null, Modifier.size(16.dp), tint = color)
                        Spacer(Modifier.width(6.dp))
                        Text(vm.formattedTime, style = MaterialTheme.typography.labelLarge, color = color)
                        Spacer(Modifier.weight(1f))
                        Text(stringResource(R.string.exam_sim_type, examTypeTitle(rules.type)),
                             style = MaterialTheme.typography.labelLarge, color = color)
                    }
                }
            }
        },
    ) { padding ->
        key(q.uniqueId) {
            BoxWithConstraints(Modifier.padding(padding).fillMaxSize()) {
                val wide = maxWidth > 900.dp
                val scroll = rememberScrollState()
                Column(Modifier.fillMaxSize().verticalScroll(scroll)) {
                    if (wide) {
                        ReadableWidth(1200.dp) {
                            Row(Modifier.padding(24.dp), horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                                QuestionCard(q, settings.showEnglish, Modifier.weight(1f))
                                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                                    Answers(vm, q, settings.showEnglish) { haptics.performHapticFeedback(it) }
                                }
                            }
                        }
                    } else {
                        ReadableWidth {
                            Column(Modifier.padding(start = 20.dp, end = 20.dp, top = 16.dp, bottom = 32.dp),
                                   verticalArrangement = Arrangement.spacedBy(12.dp)) {
                                QuestionCard(q, settings.showEnglish)
                                Spacer(Modifier.size(4.dp))
                                Answers(vm, q, settings.showEnglish) { haptics.performHapticFeedback(it) }
                            }
                        }
                    }
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
private fun QuestionCard(q: Question, showEnglish: Boolean, modifier: Modifier = Modifier) {
    Column(modifier.cardStyle().padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            ExamTypeBadge(q.examType)
            CategoryBadge(q.category(isGerman()))
        }
        Text(q.germanText, style = MaterialTheme.typography.bodyLarge.copy(localeList = LocaleList("de")),
             fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink, modifier = Modifier.semantics { heading() })
        if (showEnglish && q.englishText.isNotEmpty()) {
            HorizontalDivider(color = Sbf.colors.hairline)
            Text(q.englishText, style = MaterialTheme.typography.bodyMedium, fontStyle = FontStyle.Italic,
                 color = Sbf.colors.inkSecondary)
        }
        if (q.hasMedia) QuestionMedia(q)
    }
}

@Composable
private fun Answers(vm: QuizViewModel, q: Question, showEnglish: Boolean, haptic: (HapticFeedbackType) -> Unit) {
    val revealed = vm.phase == QuizPhase.REVEALED
    vm.shuffledOptions(q).forEach { (key, option) ->
        val selected = vm.selectedOption == key
        val tint = when {
            !revealed -> null
            vm.examMode -> if (selected) Brand.gold else null
            vm.isCorrect(key, q) -> Sbf.colors.success
            selected -> Sbf.colors.error
            else -> null
        }
        val icon = when {
            !revealed || vm.examMode -> null
            vm.isCorrect(key, q) -> true
            selected -> false
            else -> null
        }
        val state = when {
            !revealed -> null
            vm.examMode -> if (selected) stringResource(R.string.answer_selected) else null
            vm.isCorrect(key, q) -> stringResource(R.string.correct_answer)
            selected -> stringResource(R.string.your_answer_wrong)
            else -> null
        }
        AnswerOption(key, option.german, option.english, showEnglish, tint, icon, state, enabled = !revealed) {
            when (vm.select(key)) {
                // Like the real exam, a simulation gives no feedback until the end.
                null -> Unit
                else -> if (vm.examMode) haptic(HapticFeedbackType.SegmentTick)
                        else haptic(if (vm.isCorrect(key, q)) HapticFeedbackType.Confirm else HapticFeedbackType.Reject)
            }
        }
    }
    AnimatedVisibility(revealed, enter = fadeIn()) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            if (!vm.examMode) {
                val correct = vm.selectedOption?.let { vm.isCorrect(it, q) } == true
                Text(stringResource(if (correct) R.string.correct else R.string.wrong),
                     style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold,
                     color = if (correct) Sbf.colors.success else Sbf.colors.error,
                     modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
                q.explanation(isGerman())?.let { text ->
                    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Brand.gold.copy(alpha = 0.12f))
                            .padding(14.dp)) {
                        Icon(Icons.Filled.Lightbulb, null, tint = Brand.gold)
                        Spacer(Modifier.width(10.dp))
                        Text(text, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink)
                    }
                }
            }
            PrimaryButton(stringResource(if (vm.isLast) R.string.see_results else R.string.next_question),
                          if (vm.isLast) Icons.Filled.Flag else Icons.AutoMirrored.Filled.ArrowForward, vm::next)
        }
    }
}

@Composable
private fun EmptyQuiz(vm: QuizViewModel) {
    BackHandler(onBack = vm::close)
    Column(Modifier.fillMaxSize().background(Sbf.colors.surface).padding(32.dp),
           horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
        Icon(Icons.Filled.Inbox, null, Modifier.size(56.dp), tint = Sbf.colors.muted)
        Text(stringResource(R.string.no_questions), style = MaterialTheme.typography.titleLarge, color = Sbf.colors.ink)
        Text(stringResource(R.string.no_questions_desc), color = Sbf.colors.muted)
        Spacer(Modifier.size(24.dp))
        PrimaryButton(stringResource(R.string.done), null, vm::close, Modifier.width(240.dp))
    }
}
