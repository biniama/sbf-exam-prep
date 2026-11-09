package ai.biniam.sbfexamprep

import ai.biniam.sbfexamprep.audio.SoundSignal
import ai.biniam.sbfexamprep.data.ExamFormat
import ai.biniam.sbfexamprep.data.ExamRules
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.data.LicenceGoal
import ai.biniam.sbfexamprep.data.ProgressState
import ai.biniam.sbfexamprep.data.QuizRecord
import ai.biniam.sbfexamprep.data.ReviewState
import ai.biniam.sbfexamprep.data.SpacedRepetition
import ai.biniam.sbfexamprep.reminders.ReminderScheduler
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime

class LogicTest {
    private val zone = ZoneId.of("Europe/Berlin")
    private val now = ZonedDateTime.of(2026, 5, 4, 15, 30, 0, 0, zone)

    // Exam rules ------------------------------------------------------------------------

    @Test fun examRulesFollowElwis() {
        val expected = mapOf(
            ExamFormat.BINNEN_MOTOR to (30 to 45), ExamFormat.BINNEN_SAIL to (25 to 35),
            ExamFormat.BINNEN_MOTOR_SAIL to (37 to 60), ExamFormat.SAIL_ADDON to (7 to 15), ExamFormat.SEE to (30 to 60),
        )
        for ((format, value) in expected) {
            val rules = ExamRules(format)
            assertEquals(format.raw, value.first, rules.totalCount)
            assertEquals(format.raw, value.second, rules.minutes)
        }
        assertFalse(ExamRules(ExamFormat.BINNEN_MOTOR).excludesNavigationTask)
        assertTrue(ExamRules(ExamFormat.SEE).excludesNavigationTask)
    }

    @Test fun everyPartWithAPassMarkMustBePassed() {
        val rules = ExamRules(ExamFormat.BINNEN_MOTOR)
        assertTrue(rules.result(mapOf(ExamType.SHARED to 5, ExamType.BINNEN to 18)).passed)
        assertFalse(rules.result(mapOf(ExamType.SHARED to 4, ExamType.BINNEN to 23)).passed)
        assertFalse(rules.result(mapOf(ExamType.SHARED to 7, ExamType.BINNEN to 17)).passed)

        val combined = ExamRules(ExamFormat.BINNEN_MOTOR_SAIL)
        assertTrue(combined.result(mapOf(ExamType.SHARED to 5, ExamType.BINNEN to 18, ExamType.SEGELN to 5)).passed)
        assertFalse(combined.result(mapOf(ExamType.SHARED to 7, ExamType.BINNEN to 23, ExamType.SEGELN to 4)).passed)

        val addOn = ExamRules(ExamFormat.SAIL_ADDON)
        assertTrue(addOn.result(mapOf(ExamType.SEGELN to 5)).passed)
        assertFalse(addOn.result(mapOf(ExamType.SEGELN to 4)).passed)
    }

    @Test fun sailOnlyCountsTheTotal() {
        val rules = ExamRules(ExamFormat.BINNEN_SAIL)
        assertEquals(20, rules.totalPassMark)
        assertTrue(rules.result(mapOf(ExamType.SHARED to 0, ExamType.BINNEN to 14, ExamType.SEGELN to 6)).passed)
        assertFalse(rules.result(mapOf(ExamType.SHARED to 4, ExamType.BINNEN to 12, ExamType.SEGELN to 3)).passed)
    }

    @Test fun licenceGoalOffersMatchingExams() {
        assertEquals(listOf(ExamFormat.BINNEN_MOTOR, ExamFormat.SEE), LicenceGoal().examFormats)
        assertEquals(listOf(ExamFormat.BINNEN_MOTOR_SAIL), LicenceGoal(LicenceGoal.Inland.MOTOR_AND_SAIL, sea = false).examFormats)
        assertEquals(listOf(ExamFormat.SAIL_ADDON, ExamFormat.SEE), LicenceGoal(LicenceGoal.Inland.SAIL_ADDON, sea = true).examFormats)
        assertFalse(LicenceGoal(LicenceGoal.Inland.NONE, sea = false).isValid)
    }

    @Test fun oldExamRecordsKeepTheirFormat() {
        val record = QuizRecord(0, "See", 30, 25, isExam = true, passed = true)
        assertEquals(ExamFormat.SEE, record.format)
        assertNull(QuizRecord(0, "All", 20, 15).format)
    }

    // Spaced repetition -----------------------------------------------------------------

    @Test fun correctAnswersPromoteThroughTheBoxes() {
        var state: ReviewState? = null
        val expectedDays = listOf(1L, 3L, 7L, 14L, 30L, 30L)
        for ((i, days) in expectedDays.withIndex()) {
            state = SpacedRepetition.next(state, true, now)
            assertEquals(minOf(i + 1, 5), state.box)
            val due = now.toLocalDate().plusDays(days).atStartOfDay(zone).toInstant().toEpochMilli()
            assertEquals(due, state.due)
        }
    }

    @Test fun wrongAnswerResetsToBoxOneAndIsDueNow() {
        val state = SpacedRepetition.next(ReviewState(4, 0), false, now)
        assertEquals(1, state.box)
        assertEquals(now.toInstant().toEpochMilli(), state.due)
    }

    // Progress --------------------------------------------------------------------------

    @Test fun answersUpdateMistakesAndStatistics() {
        var p = ProgressState()
        p = p.recordAnswer("q1", "Lights", false, now)
        p = p.recordAnswer("q1", "Lights", false, now)
        assertEquals(2, p.wrongAnswers["q1"])
        p = p.recordAnswer("q1", "Lights", true, now)
        assertEquals(1, p.wrongAnswers["q1"])
        p = p.recordAnswer("q1", "Lights", true, now)
        assertNull(p.wrongAnswers["q1"])
        assertEquals(4, p.totalAnswered)
        assertEquals(0.5, p.overallAccuracy, 1e-9)
        assertTrue(p.studied(now.toLocalDate()))
    }

    @Test fun dueQuestionsAreSortedByBox() {
        val t = now.toInstant().toEpochMilli()
        val p = ProgressState(reviewStates = mapOf(
            "a" to ReviewState(3, t - 1000), "b" to ReviewState(1, t - 10), "c" to ReviewState(1, t - 500),
            "d" to ReviewState(2, t + 1000),
        ))
        assertEquals(listOf("c", "b", "a"), p.dueQuestionIds(t))
        assertEquals(3, p.dueCount(t))
    }

    @Test fun masteredCountsBoxFiveAndManualMarks() {
        var p = ProgressState(reviewStates = mapOf("a" to ReviewState(5, 0), "b" to ReviewState(2, 0)))
        p = p.markMastered("c", now)
        assertEquals(2, p.masteredCount)
        p = p.markMastered("a", now)
        assertEquals(2, p.masteredCount)
    }

    @Test fun streakCountsConsecutiveDays() {
        val today = LocalDate.of(2026, 5, 4)
        val p = ProgressState(studyDates = setOf("2026-05-01", "2026-05-02", "2026-05-03"))
        assertEquals(3, p.dailyStreak(today))           // today not studied yet: streak still alive
        assertEquals(0, p.dailyStreak(today.plusDays(1)))
        val withToday = p.copy(studyDates = p.studyDates + "2026-05-04")
        assertEquals(4, withToday.dailyStreak(today))
        assertEquals(listOf(false, false, false, true, true, true, true), withToday.last7Days(today).map { it.second })
    }

    @Test fun quizHistoryKeepsTheLatestHundred() {
        var p = ProgressState()
        repeat(105) { p = p.saveQuizRecord(QuizRecord(it.toLong(), "All", 10, it % 10), zone) }
        assertEquals(100, p.quizHistory.size)
        assertEquals(104L, p.quizHistory.first().date)
    }

    @Test fun bookmarksToggle() {
        val p = ProgressState().toggleBookmark("x")
        assertTrue(p.isBookmarked("x"))
        assertFalse(p.toggleBookmark("x").isBookmarked("x"))
        assertEquals(p, p.toggleBookmark(""))
    }

    // Sound signals ---------------------------------------------------------------------

    @Test fun soundSignalTimeline() {
        val (segments, total) = SoundSignal.timeline("-..")
        assertEquals(listOf(0.0, 5.0, 7.0), segments.map { it.start })
        assertEquals(listOf(4.0, 1.0, 1.0), segments.map { it.duration })
        assertEquals(8.0, total, 1e-9)
        val (grouped, groupedTotal) = SoundSignal.timeline(". .")
        assertEquals(listOf(0.0, 3.5), grouped.map { it.start })
        assertEquals(4.5, groupedTotal, 1e-9)
    }

    // Reminders -------------------------------------------------------------------------

    @Test fun reminderFiresAtTheNextOccurrence() {
        assertEquals(now.withHour(18).withMinute(0), ReminderScheduler.nextTrigger(18 * 60, now))
        assertEquals(now.plusDays(1).withHour(9).withMinute(15), ReminderScheduler.nextTrigger(9 * 60 + 15, now))
    }
}
