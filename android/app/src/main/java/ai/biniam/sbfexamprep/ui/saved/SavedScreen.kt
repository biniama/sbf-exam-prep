package ai.biniam.sbfexamprep.ui.saved

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkRemove
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DoneAll
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.Question
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.browse.QuestionRow
import ai.biniam.sbfexamprep.ui.components.Layout
import ai.biniam.sbfexamprep.ui.question.QuestionDetail
import ai.biniam.sbfexamprep.ui.quiz.QuizMode
import ai.biniam.sbfexamprep.ui.quiz.QuizViewModel
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf
import java.time.ZonedDateTime

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SavedScreen(quiz: QuizViewModel) {
    val app = LocalApp.current
    val progress by app.progressRepository.progress.collectAsStateWithLifecycle()
    var showMistakes by rememberSaveable { mutableStateOf(false) }
    var selectedId by rememberSaveable { mutableStateOf<String?>(null) }

    val saved = progress.bookmarks.mapNotNull(app.questions::question).sortedBy { it.uniqueId }
    val mistakes = progress.wrongAnswers.entries.sortedByDescending { it.value }
        .mapNotNull { app.questions.question(it.key) }
    val list = if (showMistakes) mistakes else saved
    val selectedIndex = list.indexOfFirst { it.uniqueId == selectedId }

    BoxWithConstraints(Modifier.fillMaxSize().background(Sbf.colors.surface)) {
        val twoPane = maxWidth >= Layout.twoPaneWidth
        val listPane = @Composable { modifier: Modifier ->
            Scaffold(
                modifier = modifier,
                containerColor = Sbf.colors.surface,
                topBar = {
                    TopAppBar(
                        title = { Text(stringResource(if (showMistakes) R.string.mistakes else R.string.saved_questions)) },
                        actions = {
                            if (list.isNotEmpty()) TextButton(onClick = {
                                quiz.setup(list, if (showMistakes) QuizMode.Mistakes else QuizMode.Saved)
                            }) {
                                Icon(Icons.Filled.PlayCircle, null)
                                Spacer(Modifier.width(6.dp))
                                Text(stringResource(R.string.practise))
                            }
                        },
                        colors = TopAppBarDefaults.topAppBarColors(containerColor = Sbf.colors.surface),
                    )
                },
            ) { padding ->
                Column(Modifier.padding(padding).fillMaxSize()) {
                    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp)) {
                        SegmentedButton(!showMistakes, { showMistakes = false; selectedId = null }, SegmentedButtonDefaults.itemShape(0, 2)) {
                            Text(stringResource(R.string.saved_count, saved.size))
                        }
                        SegmentedButton(showMistakes, { showMistakes = true; selectedId = null }, SegmentedButtonDefaults.itemShape(1, 2)) {
                            Text(stringResource(R.string.mistakes_count, mistakes.size))
                        }
                    }
                    if (list.isEmpty()) {
                        if (showMistakes) EmptyState(Icons.Filled.CheckCircle, stringResource(R.string.no_mistakes),
                                                     stringResource(R.string.no_mistakes_text))
                        else EmptyState(Icons.Filled.Bookmark, stringResource(R.string.no_saved),
                                        stringResource(R.string.no_saved_text))
                    } else {
                        LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            items(list, key = { it.uniqueId }) { q ->
                                SavedRow(q, showMistakes, progress.wrongAnswers[q.uniqueId] ?: 0,
                                         selected = twoPane && q.uniqueId == selectedId,
                                         onOpen = { selectedId = q.uniqueId })
                            }
                        }
                    }
                }
            }
        }

        if (twoPane) {
            Row(Modifier.fillMaxSize()) {
                listPane(Modifier.width(420.dp).fillMaxHeight())
                VerticalDivider(color = Sbf.colors.hairline)
                if (selectedIndex >= 0) {
                    QuestionDetail(list, selectedIndex, { selectedId = list[it].uniqueId }, null, Modifier.weight(1f))
                } else {
                    Box(Modifier.weight(1f))
                }
            }
        } else if (selectedId != null && selectedIndex >= 0) {
            BackHandler { selectedId = null }
            QuestionDetail(list, selectedIndex, { selectedId = list[it].uniqueId }, { selectedId = null })
        } else {
            listPane(Modifier.fillMaxSize())
        }
    }
}

@Composable
private fun SavedRow(question: Question, isMistake: Boolean, wrongCount: Int, selected: Boolean, onOpen: () -> Unit) {
    val app = LocalApp.current
    val progress by app.progressRepository.progress.collectAsStateWithLifecycle()
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.weight(1f)) { QuestionRow(question, progress, selected, onOpen) }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            if (isMistake) {
                val times = pluralStringResource(R.plurals.answered_wrongly_times, wrongCount, wrongCount)
                Text("$wrongCount×", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold,
                     color = Sbf.colors.error, modifier = Modifier.semantics { contentDescription = times })
                IconButton(onClick = { app.progressRepository.updateProgress { it.markMastered(question.uniqueId, ZonedDateTime.now()) } }) {
                    Icon(Icons.Filled.DoneAll, stringResource(R.string.mark_mastered), tint = Sbf.colors.success)
                }
                IconButton(onClick = { app.progressRepository.updateProgress { it.clearWrongAnswer(question.uniqueId) } }) {
                    Icon(Icons.Filled.Delete, stringResource(R.string.remove), tint = Sbf.colors.muted)
                }
            } else {
                IconButton(onClick = { app.progressRepository.updateProgress { it.toggleBookmark(question.uniqueId) } }) {
                    Icon(Icons.Filled.BookmarkRemove, stringResource(R.string.remove), tint = Brand.gold)
                }
            }
        }
    }
}

@Composable
private fun EmptyState(icon: ImageVector, title: String, text: String) {
    Column(Modifier.fillMaxSize().padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally,
           verticalArrangement = Arrangement.Center) {
        Icon(icon, null, Modifier.size(56.dp), tint = Sbf.colors.muted)
        Spacer(Modifier.size(12.dp))
        Text(title, style = MaterialTheme.typography.titleLarge, color = Sbf.colors.ink)
        Text(text, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.muted, textAlign = TextAlign.Center)
    }
}
