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

class NavigationDrillTest {
    @Test fun everyDrillAcceptsItsOwnAnswer() {
        val random = kotlin.random.Random(42)
        ai.biniam.sbfexamprep.data.NavigationDrill.Kind.entries.forEach { kind ->
            repeat(200) {
                val drill = ai.biniam.sbfexamprep.data.NavigationDrill.make(kind, random)
                when {
                    kind == ai.biniam.sbfexamprep.data.NavigationDrill.Kind.LIGHT -> {
                        assertTrue(drill.check(drill.light!!))
                        assertEquals(4, drill.choices.map { it.code }.toSet().size)
                        assertEquals("colour must not give the answer away", 1, drill.choices.map { it.colour }.toSet().size)
                    }
                    drill.isClock -> {
                        val m = drill.answer.toInt()
                        assertTrue(drill.check("%02d:%02d".format((m / 60) % 24, m % 60)))
                    }
                    else -> {
                        assertTrue(drill.check("%.2f".format(java.util.Locale.ROOT, drill.answer)))
                        assertFalse(drill.check("%.2f".format(java.util.Locale.ROOT, drill.answer + 5)))
                    }
                }
            }
        }
    }

    @Test fun lightCharactersHaveTheRightRhythm() {
        ai.biniam.sbfexamprep.data.LightCharacter.drillCodes.forEach {
            assertTrue(it, ai.biniam.sbfexamprep.data.LightCharacter.parse(it) != null)
        }
        val iso = ai.biniam.sbfexamprep.data.LightCharacter.parse("Iso.W.8s")!!
        assertEquals(8.0, iso.period, 1e-9)
        assertTrue(iso.isOn(1.0))
        assertFalse(iso.isOn(5.0))
        val oc3 = ai.biniam.sbfexamprep.data.LightCharacter.parse("Oc(3).Y.12s")!!
        assertEquals(12.0, oc3.period, 1e-9)
        assertEquals(3, oc3.phases.count { !it.first })
        assertNull(ai.biniam.sbfexamprep.data.LightCharacter.parse("Xyz.W.4s"))
    }
}
