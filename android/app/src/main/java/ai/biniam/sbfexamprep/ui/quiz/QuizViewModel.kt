package ai.biniam.sbfexamprep.ui.quiz

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import ai.biniam.sbfexamprep.SbfApplication
import ai.biniam.sbfexamprep.data.ExamResult
import ai.biniam.sbfexamprep.data.ExamRules
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.data.Question
import ai.biniam.sbfexamprep.data.QuestionOption
import ai.biniam.sbfexamprep.data.QuizRecord
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.time.ZoneId
import java.time.ZonedDateTime

enum class QuizPhase { ANSWERING, REVEALED, FINISHED }

sealed interface QuizMode {
    data object Practice : QuizMode
    data class Exam(val rules: ExamRules) : QuizMode
    /** Spaced-repetition questions that are due. */
    data object Review : QuizMode
    data object Mistakes : QuizMode
    data object Saved : QuizMode
}

class QuizViewModel(private val app: SbfApplication) : ViewModel() {
    private val store get() = app.questions
    private val progress get() = app.progressRepository

    /** True while the quiz screen is shown. */
    var active by mutableStateOf(false)
        private set
    var questions by mutableStateOf(emptyList<Question>())
        private set
    var currentIndex by mutableIntStateOf(0)
        private set
    var selectedOption by mutableStateOf<String?>(null)
        private set
    var phase by mutableStateOf(QuizPhase.ANSWERING)
        private set
    var correctCount by mutableIntStateOf(0)
        private set
    var wrongIds by mutableStateOf(emptyList<String>())
        private set
    var examType by mutableStateOf(ExamType.ALL)
        private set
    var mode by mutableStateOf<QuizMode>(QuizMode.Practice)
        private set
    var timeRemaining by mutableIntStateOf(0)
        private set

    /** questionId → (displayKey → originalKey): A–D stay in order, content is shuffled. */
    private var keyRemaps = mapOf<String, Map<String, String>>()
    private var answers = mutableMapOf<String, Boolean>()
    private var timerJob: Job? = null

    val current: Question? get() = questions.getOrNull(currentIndex)
    val isLast: Boolean get() = currentIndex >= questions.size - 1
    val progressFraction: Float get() = if (questions.isEmpty()) 0f else currentIndex.toFloat() / questions.size
    val examRules: ExamRules? get() = (mode as? QuizMode.Exam)?.rules
    val examMode: Boolean get() = mode is QuizMode.Exam

    /** Official scoring: basic and licence-specific parts are assessed separately. */
    val examResult: ExamResult?
        get() {
            val rules = examRules ?: return null
            val basic = questions.count { it.examType == ExamType.SHARED && answers[it.uniqueId] == true }
            val specific = questions.count { it.examType != ExamType.SHARED && answers[it.uniqueId] == true }
            return rules.result(basic, specific)
        }

    val formattedTime: String get() = "%d:%02d".format(timeRemaining / 60, timeRemaining % 60)

    // Setup ------------------------------------------------------------------------------

    /** Practice quiz from the catalogue. */
    fun setup(type: ExamType, count: Int, category: String? = null) {
        start(store.questions(type, category).shuffled().take(count), type, QuizMode.Practice)
    }

    /** Quiz over the questions answered wrongly so far, most frequent first. */
    fun setupMistakes(limit: Int = 30) {
        val ids = progress.progress.value.wrongAnswers.entries.sortedByDescending { it.value }.map { it.key }
        start(ids.mapNotNull(store::question).take(limit).shuffled(), ExamType.ALL, QuizMode.Mistakes)
    }

    /** Spaced-repetition session with the questions that are due today. */
    fun setupDueReview(limit: Int = 30) {
        val ids = progress.progress.value.dueQuestionIds(System.currentTimeMillis())
        start(ids.mapNotNull(store::question).take(limit), ExamType.ALL, QuizMode.Review)
    }

    /** Quiz over an explicit list (e.g. saved questions). */
    fun setup(list: List<Question>, mode: QuizMode = QuizMode.Saved) = start(list.shuffled(), ExamType.ALL, mode)

    /** Exam simulation following the official composition: 7 basic + 23 specific questions. */
    fun setupExam(type: ExamType) {
        val rules = ExamRules(type)
        val basic = store.specificQuestions(ExamType.SHARED).shuffled().take(rules.basicCount)
        val specific = store.specificQuestions(type).shuffled().take(rules.specificCount)
        start(basic + specific, type, QuizMode.Exam(rules))
    }

    /** Same questions again in a new order (a new exam for simulations). */
    fun retry() {
        val rules = examRules
        if (rules != null) setupExam(rules.type) else start(questions.shuffled(), examType, mode)
    }

    private fun start(list: List<Question>, type: ExamType, mode: QuizMode) {
        timerJob?.cancel()
        this.mode = mode
        examType = type
        questions = list
        currentIndex = 0
        selectedOption = null
        phase = QuizPhase.ANSWERING
        correctCount = 0
        wrongIds = emptyList()
        answers = mutableMapOf()
        keyRemaps = list.associate { q ->
            val keys = q.sortedKeys
            q.uniqueId to keys.zip(keys.shuffled()).toMap()
        }
        val rules = (mode as? QuizMode.Exam)?.rules
        timeRemaining = (rules?.minutes ?: 0) * 60
        if (rules != null) startTimer()
        active = true
    }

    fun close() {
        timerJob?.cancel()
        app.soundPlayer.stop()
        active = false
    }

    fun shuffledOptions(q: Question): List<Pair<String, QuestionOption>> {
        val remap = keyRemaps[q.uniqueId] ?: return q.sortedKeys.map { it to q.options.getValue(it) }
        return q.sortedKeys.mapNotNull { key -> remap[key]?.let { q.options[it] }?.let { key to it } }
    }

    fun isCorrect(displayKey: String, q: Question): Boolean =
        (keyRemaps[q.uniqueId]?.get(displayKey) ?: displayKey) == q.correctOption

    // Answer -----------------------------------------------------------------------------

    /** Returns whether the answer was correct, or null when nothing was recorded. */
    fun select(option: String): Boolean? {
        val q = current ?: return null
        if (phase != QuizPhase.ANSWERING) return null
        selectedOption = option
        phase = QuizPhase.REVEALED
        val correct = isCorrect(option, q)
        answers[q.uniqueId] = correct
        if (correct) correctCount++ else wrongIds = wrongIds + q.uniqueId
        progress.updateProgress { it.recordAnswer(q.uniqueId, q.category, correct, ZonedDateTime.now()) }
        return correct
    }

    fun next() {
        app.soundPlayer.stop()
        if (isLast) {
            finish()
        } else {
            currentIndex++
            selectedOption = null
            phase = QuizPhase.ANSWERING
        }
    }

    /** Ends the quiz (also used when the exam time runs out). */
    fun finish() {
        if (phase == QuizPhase.FINISHED) return
        phase = QuizPhase.FINISHED
        timerJob?.cancel()
        app.soundPlayer.stop()
        if (questions.isEmpty()) return
        val result = examResult
        val record = QuizRecord(
            date = System.currentTimeMillis(), examType = examType.raw, totalQuestions = questions.size,
            correctAnswers = correctCount, isExam = result?.let { true }, passed = result?.passed,
        )
        progress.updateProgress { it.saveQuizRecord(record, ZoneId.systemDefault()) }
    }

    fun toggleBookmark() {
        val id = current?.uniqueId ?: return
        progress.updateProgress { it.toggleBookmark(id) }
    }

    private fun startTimer() {
        timerJob = viewModelScope.launch {
            while (timeRemaining > 0 && phase != QuizPhase.FINISHED) {
                delay(1000)
                timeRemaining--
                if (timeRemaining == 0) finish()
            }
        }
    }
}
