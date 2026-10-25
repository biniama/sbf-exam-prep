package ai.biniam.sbfexamprep

import ai.biniam.sbfexamprep.data.ExamFormat
import ai.biniam.sbfexamprep.data.ExamRules
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.data.NavigationAnswerChecker
import ai.biniam.sbfexamprep.data.NavigationCatalog
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class NavigationExamTest {
    private val catalog = File("../../shared", NavigationCatalog.ASSET_NAME).inputStream().use { NavigationCatalog.load(it) }
    private val t = catalog.tolerances
    private fun step(task: Int, number: Int) = catalog.tasks[task - 1].steps[number - 1]
    private fun check(task: Int, number: Int, vararg input: String) = NavigationAnswerChecker.isCorrect(step(task, number), input.toList(), t)

    @Test fun answerCheckerUsesPracticeTolerances() {
        assertEquals(true, check(1, 2, "74"))
        assertEquals(false, check(1, 2, "077"))
        assertEquals(true, check(1, 3, "6,2"))
        assertEquals(true, check(1, 4, "46"))
        assertEquals(true, check(1, 5, "53", "55,9", "7", "51,2"))
        assertEquals(false, check(1, 5, "53", "56,5", "7", "51,3"))
        assertEquals(true, check(1, 6, "170", "065"))
        assertEquals(true, check(1, 8, "100", "0.8"))
        assertNull("chart work is self-graded", check(1, 7, ""))
        assertEquals(true, check(3, 5, "15:13"))
        assertEquals(false, check(12, 3, "359"))
        assertEquals(true, check(12, 3, "8"))
    }

    @Test fun navigationPartMustBePassedInTheSeaExam() {
        val rules = ExamRules(ExamFormat.SEE, includeNavigation = true)
        assertEquals(9, rules.navigationCount)
        assertFalse(rules.excludesNavigationTask)
        assertTrue(rules.result(mapOf(ExamType.SHARED to 7, ExamType.SEE to 23), navigationCorrect = 7).passed)
        assertFalse(rules.result(mapOf(ExamType.SHARED to 7, ExamType.SEE to 23), navigationCorrect = 6).passed)
        assertEquals(0, ExamRules(ExamFormat.BINNEN_MOTOR, includeNavigation = true).navigationCount)
    }
}
