package ai.biniam.sbfexamprep

import ai.biniam.sbfexamprep.data.Access
import ai.biniam.sbfexamprep.data.ExamFormat
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.data.ProProduct
import ai.biniam.sbfexamprep.data.QuestionRepository
import ai.biniam.sbfexamprep.data.licenceType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/** Free tier and purchases. The sample sizes must match the iOS app (FreeTierTests). */
class FreeTierTest {
    private val store = QuestionRepository(File("../../shared", QuestionRepository.ASSET_NAME).readText())

    private fun freeCount(type: ExamType) =
        store.specificQuestions(type).count { store.isUnlocked(it, Access()) }

    @Test fun freeSampleMatchesIos() {
        assertEquals(store.specificQuestions(ExamType.SHARED).size, freeCount(ExamType.SHARED))
        assertEquals(29, freeCount(ExamType.BINNEN))
        assertEquals(9, freeCount(ExamType.SEGELN))
        assertEquals(34, freeCount(ExamType.SEE))
    }

    @Test fun everyTopicHasAFreeQuestion() {
        for (type in listOf(ExamType.BINNEN, ExamType.SEGELN, ExamType.SEE)) {
            store.specificQuestions(type).groupBy { it.category }.forEach { (category, questions) ->
                assertTrue("$type / $category", questions.any { store.isUnlocked(it, Access()) })
            }
        }
    }

    @Test fun accessPerProduct() {
        val binnen = Access(setOf(ProProduct.BINNEN))
        assertTrue(binnen.hasAccess(ExamType.BINNEN))
        assertTrue(binnen.hasAccess(ExamType.SEGELN))
        assertFalse(binnen.hasAccess(ExamType.SEE))
        assertEquals(listOf(ProProduct.SEE), binnen.offeredProducts)

        val see = Access(setOf(ProProduct.SEE))
        assertTrue(see.hasAccess(ExamType.SEE))
        assertFalse(see.hasAccess(ExamType.SEGELN))
        assertEquals(listOf(ProProduct.BINNEN), see.offeredProducts)

        val both = Access(setOf(ProProduct.BOTH))
        assertTrue(both.hasEverything)
        assertTrue(both.offeredProducts.isEmpty())
        assertTrue(store.allQuestions.all { store.isUnlocked(it, both) })

        // Navigation tasks: task 1 is free, the rest belong to SBF Sea.
        assertTrue(Access().canOpenNavigationTask(1))
        assertFalse(Access().canOpenNavigationTask(2))
        assertFalse(binnen.canOpenNavigationTask(15))
        assertTrue(see.canOpenNavigationTask(15))
        assertTrue(both.canOpenNavigationTask(15))

        assertEquals(3, Access().offeredProducts.size)
        assertTrue(Access().hasAccess(ExamType.SHARED))
    }

    @Test fun examFormatsNeedTheRightLicence() {
        assertEquals(ExamType.SEE, ExamFormat.SEE.licenceType)
        for (format in ExamFormat.entries.filter { it != ExamFormat.SEE }) {
            assertEquals(format.raw, ExamType.BINNEN, format.licenceType)
        }
    }

    @Test fun productIdsRoundTrip() {
        ProProduct.entries.forEach { assertEquals(it, ProProduct.fromId(it.productId)) }
    }
}
