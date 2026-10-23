package ai.biniam.sbfexamprep.data

import kotlinx.serialization.Serializable
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime

@Serializable
data class QuizRecord(
    /** Epoch milliseconds. */
    val date: Long,
    val examType: String,
    val totalQuestions: Int,
    val correctAnswers: Int,
    /** Set for exam simulations only. */
    val isExam: Boolean? = null,
    val passed: Boolean? = null,
    val examFormat: String? = null,
) {
    val accuracy: Double get() = if (totalQuestions > 0) correctAnswers.toDouble() / totalQuestions else 0.0
    val type: ExamType get() = ExamType.fromRaw(examType)

    /** Exam format of a simulation (records from before formats existed fall back to the exam type). */
    val format: ExamFormat?
        get() = ExamFormat.fromRaw(examFormat)
            ?: if (isExam == true) (if (type == ExamType.SEE) ExamFormat.SEE else ExamFormat.BINNEN_MOTOR) else null
}

/** Leitner box of a question for spaced repetition; [due] in epoch milliseconds. */
@Serializable
data class ReviewState(val box: Int, val due: Long)

object SpacedRepetition {
    const val MAX_BOX = 5

    /** Days until the next review for each box. */
    val intervalDays = mapOf(1 to 1, 2 to 3, 3 to 7, 4 to 14, 5 to 30)

    /**
     * Next state after an answer. A wrong answer sends the question back to box 1 and
     * makes it due immediately; a correct answer promotes it one box.
     */
    fun next(state: ReviewState?, correct: Boolean, now: ZonedDateTime): ReviewState {
        if (!correct) return ReviewState(1, now.toInstant().toEpochMilli())
        val box = minOf((state?.box ?: 0) + 1, MAX_BOX)
        val due = now.toLocalDate().plusDays(intervalDays.getValue(box).toLong()).atStartOfDay(now.zone)
        return ReviewState(box, due.toInstant().toEpochMilli())
    }
}

/** Everything the learner has done. Immutable; every change returns a new state. */
@Serializable
data class ProgressState(
    val bookmarks: Set<String> = emptySet(),
    val wrongAnswers: Map<String, Int> = emptyMap(),
    val mastered: Set<String> = emptySet(),
    val quizHistory: List<QuizRecord> = emptyList(),
    /** ISO dates (yyyy-MM-dd) on which the learner answered at least one question. */
    val studyDates: Set<String> = emptySet(),
    val categoryCorrect: Map<String, Int> = emptyMap(),
    val categoryTotal: Map<String, Int> = emptyMap(),
    val reviewStates: Map<String, ReviewState> = emptyMap(),
) {
    // Bookmarks ------------------------------------------------------------------------

    fun isBookmarked(id: String) = id in bookmarks

    fun toggleBookmark(id: String): ProgressState =
        if (id.isEmpty()) this else copy(bookmarks = if (id in bookmarks) bookmarks - id else bookmarks + id)

    // Answers --------------------------------------------------------------------------

    fun recordAnswer(questionId: String, category: String, correct: Boolean, now: ZonedDateTime): ProgressState {
        val wrong = wrongAnswers.toMutableMap()
        var mastered = mastered
        if (correct) {
            val count = wrong[questionId] ?: 0
            if (count > 1) wrong[questionId] = count - 1 else wrong.remove(questionId)
        } else {
            wrong[questionId] = (wrong[questionId] ?: 0) + 1
            mastered = mastered - questionId
        }
        val total = categoryTotal + (category to (categoryTotal[category] ?: 0) + 1)
        val right = if (correct) categoryCorrect + (category to (categoryCorrect[category] ?: 0) + 1) else categoryCorrect
        val review = reviewStates + (questionId to SpacedRepetition.next(reviewStates[questionId], correct, now))
        return copy(wrongAnswers = wrong, mastered = mastered, categoryTotal = total, categoryCorrect = right,
                    reviewStates = review).recordStudy(now.toLocalDate())
    }

    fun markMastered(id: String, now: ZonedDateTime): ProgressState = copy(
        mastered = mastered + id,
        wrongAnswers = wrongAnswers - id,
        reviewStates = reviewStates + (id to ReviewState(SpacedRepetition.MAX_BOX, now.plusDays(30).toInstant().toEpochMilli())),
    )

    fun clearWrongAnswer(id: String) = copy(wrongAnswers = wrongAnswers - id)

    val wrongAnswerCount get() = wrongAnswers.size
    fun isWrong(id: String) = (wrongAnswers[id] ?: 0) > 0

    // Spaced repetition ----------------------------------------------------------------

    fun dueQuestionIds(now: Long): List<String> = reviewStates.filter { it.value.due <= now }
        .entries.sortedWith(compareBy({ it.value.box }, { it.value.due })).map { it.key }

    fun dueCount(now: Long) = reviewStates.count { it.value.due <= now }

    val masteredCount: Int
        get() = (reviewStates.filter { it.value.box >= SpacedRepetition.MAX_BOX }.keys + mastered).size

    fun box(id: String): Int? = reviewStates[id]?.box

    // Statistics -----------------------------------------------------------------------

    fun saveQuizRecord(record: QuizRecord, zone: ZoneId): ProgressState =
        copy(quizHistory = (listOf(record) + quizHistory).take(100))
            .recordStudy(Instant.ofEpochMilli(record.date).atZone(zone).toLocalDate())

    /** Every answered question counts, not only finished quizzes. */
    val totalAnswered get() = categoryTotal.values.sum()

    val overallAccuracy: Double
        get() = totalAnswered.let { if (it > 0) categoryCorrect.values.sum().toDouble() / it else 0.0 }

    // Daily streak ---------------------------------------------------------------------

    private fun recordStudy(day: LocalDate): ProgressState =
        day.toString().let { if (it in studyDates) this else copy(studyDates = studyDates + it) }

    fun studied(day: LocalDate) = day.toString() in studyDates

    /** Consecutive days with study up to today (or yesterday, if today has no study yet). */
    fun dailyStreak(today: LocalDate): Int {
        var day = if (studied(today)) today else today.minusDays(1)
        var streak = 0
        while (studied(day)) {
            streak++
            day = day.minusDays(1)
        }
        return streak
    }

    fun last7Days(today: LocalDate): List<Pair<LocalDate, Boolean>> =
        (6 downTo 0).map { today.minusDays(it.toLong()).let { d -> d to studied(d) } }
}

/** Local preferences (not part of the progress). */
data class AppSettings(
    val showEnglish: Boolean = true,
    val quizCount: Int = 20,
    val reminderEnabled: Boolean = false,
    val reminderMinutes: Int = 18 * 60,
    val onboardingDone: Boolean = false,
    val licenceGoal: LicenceGoal = LicenceGoal(),
    /** False until the learner has picked a licence (onboarding or the Home prompt). */
    val hasChosenLicence: Boolean = false,
)
