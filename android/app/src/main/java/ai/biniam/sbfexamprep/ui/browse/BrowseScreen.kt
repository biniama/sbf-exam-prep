package ai.biniam.sbfexamprep.ui.browse

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.VerticalDivider
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ai.biniam.sbfexamprep.DebugLaunch
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.data.ProgressState
import ai.biniam.sbfexamprep.data.Question
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.Layout
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.components.examTypeColor
import ai.biniam.sbfexamprep.ui.components.examTypeTextColor
import ai.biniam.sbfexamprep.ui.components.examTypeTitle
import ai.biniam.sbfexamprep.ui.components.isGerman
import ai.biniam.sbfexamprep.ui.question.QuestionDetail
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf

@Composable
fun BrowseScreen() {
    val app = LocalApp.current
    val progress by app.progressRepository.progress.collectAsStateWithLifecycle()
    var examType by rememberSaveable { mutableStateOf(ExamType.ALL) }
    var category by rememberSaveable { mutableStateOf<String?>(null) }
    var search by rememberSaveable { mutableStateOf("") }
    var onlyMistakes by rememberSaveable { mutableStateOf(false) }
    var onlySaved by rememberSaveable { mutableStateOf(false) }
    var selectedId by rememberSaveable { mutableStateOf(DebugLaunch.question) }
    var showPicker by rememberSaveable { mutableStateOf(false) }

    val questions = remember(examType, category, search, onlyMistakes, onlySaved, progress.wrongAnswers, progress.bookmarks) {
        filter(app.questions.questions(examType, category), search, onlyMistakes, onlySaved, progress)
    }
    val selectedIndex = questions.indexOfFirst { it.uniqueId == selectedId }

    BoxWithConstraints(Modifier.fillMaxSize().background(Sbf.colors.surface)) {
        val twoPane = maxWidth >= Layout.twoPaneWidth
        val list = @Composable { modifier: Modifier ->
            QuestionList(
                questions, examType, category, search, { search = it }, onlyMistakes, { onlyMistakes = it },
                onlySaved, { onlySaved = it }, progress, selectedId.takeIf { twoPane }, { showPicker = true },
                { selectedId = it.uniqueId }, modifier,
            )
        }
        if (twoPane) {
            Row(Modifier.fillMaxSize()) {
                list(Modifier.width(400.dp).fillMaxHeight())
                VerticalDivider(color = Sbf.colors.hairline)
                if (selectedIndex >= 0) {
                    QuestionDetail(questions, selectedIndex, { selectedId = questions[it].uniqueId }, null, Modifier.weight(1f))
                } else {
                    EmptyDetail(Modifier.weight(1f))
                }
            }
        } else {
            val selected = selectedId?.let(app.questions::question)
            if (selected != null) {
                BackHandler { selectedId = null }
                if (selectedIndex >= 0) {
                    QuestionDetail(questions, selectedIndex, { selectedId = questions[it].uniqueId }, { selectedId = null })
                } else {
                    QuestionDetail(listOf(selected), 0, {}, { selectedId = null })
                }
            } else {
                list(Modifier.fillMaxSize())
            }
        }
    }

    if (showPicker) {
        TopicPickerSheet(examType, category, onDismiss = { showPicker = false }) { type, cat ->
            examType = type
            category = cat
        }
    }
}

private fun filter(base: List<Question>, search: String, onlyMistakes: Boolean, onlySaved: Boolean,
                   progress: ProgressState): List<Question> {
    val query = search.trim()
    return base.filter { q ->
        (!onlyMistakes || progress.isWrong(q.uniqueId)) &&
            (!onlySaved || progress.isBookmarked(q.uniqueId)) &&
            (query.isEmpty() || q.germanText.contains(query, true) || q.englishText.contains(query, true) ||
                q.questionNumber.toString() == query ||
                q.options.values.any { it.german.contains(query, true) || it.english.contains(query, true) })
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun QuestionList(
    questions: List<Question>,
    examType: ExamType,
    category: String?,
    search: String,
    onSearch: (String) -> Unit,
    onlyMistakes: Boolean,
    onOnlyMistakes: (Boolean) -> Unit,
    onlySaved: Boolean,
    onOnlySaved: (Boolean) -> Unit,
    progress: ProgressState,
    selectedId: String?,
    onPickTopic: () -> Unit,
    onSelect: (Question) -> Unit,
    modifier: Modifier,
) {
    val app = LocalApp.current
    val german = isGerman()
    val state = rememberLazyListState()
    Scaffold(
        modifier = modifier,
        containerColor = Sbf.colors.surface,
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.tab_browse)) },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Sbf.colors.surface),
            )
        },
    ) { padding ->
        LazyColumn(
            Modifier.padding(padding).fillMaxSize(),
            state = state,
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item {
                OutlinedTextField(
                    value = search, onValueChange = onSearch, singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text(stringResource(R.string.search_questions)) },
                    leadingIcon = { Icon(Icons.Filled.Search, null) },
                    trailingIcon = {
                        if (search.isNotEmpty()) IconButton(onClick = { onSearch("") }) {
                            Icon(Icons.Filled.Clear, stringResource(R.string.clear))
                        }
                    },
                    shape = RoundedCornerShape(14.dp),
                    colors = OutlinedTextFieldDefaults.colors(unfocusedContainerColor = Sbf.colors.card,
                                                              focusedContainerColor = Sbf.colors.card),
                )
            }
            item {
                val topic = category?.let { app.questions.categoryName(it, german) } ?: stringResource(R.string.all_topics)
                Surface(onClick = onPickTopic, shape = RoundedCornerShape(14.dp), color = Color.Transparent) {
                    Row(Modifier.cardStyle(14.dp).padding(horizontal = 14.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.FilterList, null, tint = Brand.gold)
                        Spacer(Modifier.width(10.dp))
                        Column(Modifier.weight(1f)) {
                            Text(examTypeTitle(examType), style = MaterialTheme.typography.labelMedium, color = Sbf.colors.muted)
                            Text(topic, style = MaterialTheme.typography.titleSmall, color = Sbf.colors.ink,
                                 maxLines = 2, overflow = TextOverflow.Ellipsis)
                        }
                        Text(pluralStringResource(R.plurals.questions_count, questions.size, questions.size),
                             style = MaterialTheme.typography.labelMedium, color = Sbf.colors.muted)
                    }
                }
            }
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(onlyMistakes, { onOnlyMistakes(!onlyMistakes) }, label = { Text(stringResource(R.string.mistakes)) },
                               leadingIcon = { Icon(Icons.Filled.Cancel, null, Modifier.size(18.dp)) })
                    FilterChip(onlySaved, { onOnlySaved(!onlySaved) }, label = { Text(stringResource(R.string.tab_saved)) },
                               leadingIcon = { Icon(Icons.Filled.Bookmark, null, Modifier.size(18.dp)) })
                }
            }
            if (questions.isEmpty()) {
                item {
                    Text(stringResource(R.string.no_results), Modifier.fillMaxWidth().padding(32.dp),
                         textAlign = TextAlign.Center, color = Sbf.colors.muted)
                }
            }
            items(questions, key = { it.uniqueId }) { q ->
                QuestionRow(q, progress, q.uniqueId == selectedId) { onSelect(q) }
            }
        }
    }
}

@Composable
fun QuestionRow(question: Question, progress: ProgressState, selected: Boolean, onClick: () -> Unit) {
    val wrong = progress.isWrong(question.uniqueId)
    val saved = progress.isBookmarked(question.uniqueId)
    val extra = buildList {
        if (wrong) add(stringResource(R.string.answered_wrongly))
        if (saved) add(stringResource(R.string.tab_saved))
    }.joinToString(", ")
    val description = stringResource(R.string.question_label, question.questionNumber, question.germanText) +
        if (extra.isNotEmpty()) ", $extra" else ""
    Row(
        Modifier.fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(if (selected) Brand.navyLight.copy(alpha = 0.16f) else Sbf.colors.card)
            .border(1.dp, if (selected) Brand.navyLight.copy(alpha = 0.5f) else Sbf.colors.hairline.copy(alpha = 0.6f),
                    RoundedCornerShape(14.dp))
            .clickable(onClick = onClick)
            .padding(12.dp)
            .clearAndSetSemantics { contentDescription = description; this.selected = selected },
        verticalAlignment = Alignment.Top,
    ) {
        val color = examTypeColor(question.examType)
        Box(Modifier.size(34.dp).clip(CircleShape).background(color.copy(alpha = 0.15f)), contentAlignment = Alignment.Center) {
            Text("${question.questionNumber}", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold,
                 color = Sbf.colors.ink)
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(question.germanText, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink,
                 maxLines = 3, overflow = TextOverflow.Ellipsis)
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(examTypeTitle(question.examType), style = MaterialTheme.typography.labelSmall,
                     color = examTypeTextColor(question.examType),
                     fontWeight = FontWeight.SemiBold)
                if (question.hasImage) Icon(Icons.Filled.Image, null, Modifier.size(14.dp), tint = Sbf.colors.muted)
                if (question.soundPattern != null) Icon(Icons.Filled.GraphicEq, null, Modifier.size(14.dp), tint = Sbf.colors.muted)
            }
        }
        Column(horizontalAlignment = Alignment.End) {
            if (saved) Icon(Icons.Filled.Bookmark, null, Modifier.size(16.dp), tint = Brand.gold)
            if (wrong) Icon(Icons.Filled.Cancel, null, Modifier.size(16.dp), tint = Sbf.colors.error)
        }
    }
}

@Composable
private fun EmptyDetail(modifier: Modifier) {
    Column(modifier.fillMaxSize().padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally,
           verticalArrangement = Arrangement.Center) {
        Icon(Icons.AutoMirrored.Filled.MenuBook, null, Modifier.size(56.dp), tint = Sbf.colors.muted)
        Spacer(Modifier.size(12.dp))
        Text(stringResource(R.string.select_question), style = MaterialTheme.typography.titleLarge, color = Sbf.colors.ink)
        Text(stringResource(R.string.select_question_hint), style = MaterialTheme.typography.bodyMedium,
             color = Sbf.colors.muted, textAlign = TextAlign.Center)
    }
}

/** Full-height sheet so that every topic is visible at once. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TopicPickerSheet(
    examType: ExamType,
    category: String?,
    onDismiss: () -> Unit,
    onPick: (ExamType, String?) -> Unit,
) {
    val app = LocalApp.current
    val german = isGerman()
    var type by remember { mutableStateOf(examType) }
    val sheet = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val topics = remember(type, german) { app.questions.categories(type, german) }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheet, containerColor = Sbf.colors.surface) {
        Column(Modifier.padding(horizontal = 16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.choose_exam_topic), style = MaterialTheme.typography.titleLarge,
                     color = Sbf.colors.ink, modifier = Modifier.weight(1f))
                TextButton(onClick = { onPick(ExamType.ALL, null); onDismiss() }) { Text(stringResource(R.string.reset)) }
            }
            Text(stringResource(R.string.exam), style = MaterialTheme.typography.labelLarge, color = Sbf.colors.muted,
                 modifier = Modifier.padding(top = 8.dp, bottom = 6.dp))
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                ExamType.entries.forEachIndexed { i, t ->
                    SegmentedButton(type == t, { type = t; onPick(t, null) }, SegmentedButtonDefaults.itemShape(i, ExamType.entries.size)) {
                        Text(examTypeTitle(t), maxLines = 1)
                    }
                }
            }
            Text(stringResource(R.string.topic), style = MaterialTheme.typography.labelLarge, color = Sbf.colors.muted,
                 modifier = Modifier.padding(top = 16.dp, bottom = 6.dp))
        }
        LazyVerticalGrid(
            GridCells.Adaptive(260.dp),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 32.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item(span = { GridItemSpan(maxLineSpan) }) {
                TopicCell(stringResource(R.string.all_topics), app.questions.questions(type).size,
                          category == null && type == examType) { onPick(type, null); onDismiss() }
            }
            items(topics, key = { it }) { key ->
                TopicCell(app.questions.categoryName(key, german), app.questions.questions(type, key).size,
                          category == key && type == examType) { onPick(type, key); onDismiss() }
            }
        }
    }
}

@Composable
private fun TopicCell(title: String, count: Int, selected: Boolean, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
            .background(if (selected) Brand.navy else Sbf.colors.card)
            .border(1.dp, Sbf.colors.hairline.copy(alpha = 0.6f), RoundedCornerShape(12.dp))
            .clickable(onClick = onClick).padding(14.dp)
            .semantics(mergeDescendants = true) { this.selected = selected },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium,
             color = if (selected) Color.White else Sbf.colors.ink)
        Text(pluralStringResource(R.plurals.questions_count, count, count), style = MaterialTheme.typography.labelSmall,
             color = if (selected) Brand.goldLight else Sbf.colors.muted)
    }
}
