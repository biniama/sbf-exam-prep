package ai.biniam.sbfexamprep

import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.data.QuestionRepository
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

/** Checks the shared catalogue (also used by the iOS app) and the Android resources. */
class DataIntegrityTest {
    private val shared = File("../../shared")
    private val store = QuestionRepository(File(shared, QuestionRepository.ASSET_NAME).readText())

    @Test fun catalogueIsComplete() {
        assertEquals(466, store.allQuestions.size)
        assertEquals(store.metadata.totalQuestions, store.allQuestions.size)
        assertEquals(store.allQuestions.size, store.allQuestions.map { it.uniqueId }.toSet().size)
        assertEquals(72, store.specificQuestions(ExamType.SHARED).size)
        assertEquals(store.specificQuestions(ExamType.SHARED).size + store.specificQuestions(ExamType.BINNEN).size,
                     store.questions(ExamType.BINNEN).size)
    }

    @Test fun everyQuestionHasFourOptionsAndAValidAnswer() {
        for (q in store.allQuestions) {
            assertEquals(q.uniqueId, listOf("A", "B", "C", "D"), q.sortedKeys)
            assertNotNull(q.uniqueId, q.options[q.correctOption])
            assertTrue(q.uniqueId, q.germanText.isNotBlank())
            assertFalse(q.uniqueId, q.categoryDE.isNullOrBlank())
        }
    }

    @Test fun imagesExistAndDecode() {
        val referenced = mutableSetOf<String>()
        for (q in store.allQuestions) {
            assertEquals(q.uniqueId, q.hasImage, q.imagePaths.isNotEmpty())
            for (path in q.imagePaths) {
                val file = File(shared, path)
                assertTrue("$path missing", file.exists())
                assertTrue("$path is not a valid PNG", isPng(file))
                referenced += file.canonicalPath
            }
        }
        val onDisk = File(shared, "assets").walk().filter { it.extension == "png" }.map { it.canonicalPath }.toSet()
        assertEquals("orphaned images", emptySet<String>(), onDisk - referenced)
    }

    @Test fun soundPatternsAreValid() {
        val patterns = store.allQuestions.mapNotNull { it.soundPattern }
        assertTrue(patterns.size >= 20)
        patterns.forEach { assertTrue(it, it.isNotBlank() && it.all { ch -> ch in ".- " }) }
    }

    @Test fun everyQuestionHasExplanationsInBothLanguages() {
        for (q in store.allQuestions) {
            assertFalse("${q.uniqueId} German explanation missing", q.explanationDE.isNullOrBlank())
            assertFalse("${q.uniqueId} English explanation missing", q.explanationEN.isNullOrBlank())
        }
    }

    @Test fun displayOptionsKeepExactlyOneCorrectAnswer() {
        for (q in store.allQuestions) {
            val options = q.displayOptions
            assertEquals(listOf("A", "B", "C", "D"), options.map { it.key })
            assertEquals(q.uniqueId, 1, options.count { it.isCorrect })
            assertEquals(q.options[q.correctOption], options.first { it.isCorrect }.option)
            assertEquals("stable order", options, q.displayOptions)
        }
        // The official catalogue always lists the correct answer first; browsing must not.
        val correctIsA = store.allQuestions.count { it.displayOptions.first().isCorrect }
        assertTrue("correct answer is A for $correctIsA questions", correctIsA < store.allQuestions.size * 0.4)
    }

    @Test fun categoriesAreSortedByDisplayName() {
        val german = store.categories(ExamType.ALL, german = true).map { store.categoryName(it, true) }
        assertEquals(german.sortedWith(java.text.Collator.getInstance(java.util.Locale.GERMAN)), german)
        assertEquals(22, german.size)
    }

    @Test fun germanResourcesMatchEnglish() {
        val en = resources("values")
        val de = resources("values-de")
        assertEquals("missing German resources", en.keys - "app_name", de.keys)
        for ((name, text) in de) {
            assertEquals("placeholders of $name", placeholders(en.getValue(name)), placeholders(text))
        }
        assertEquals("Fragen", de["tab_browse"])
        assertEquals("de", de["content_language"])
    }

    private fun resources(folder: String): Map<String, String> {
        val doc = DocumentBuilderFactory.newInstance().newDocumentBuilder()
            .parse(File("src/main/res/$folder/strings.xml"))
        val result = mutableMapOf<String, String>()
        val strings = doc.getElementsByTagName("string")
        for (i in 0 until strings.length) {
            val e = strings.item(i) as org.w3c.dom.Element
            result[e.getAttribute("name")] = e.textContent
        }
        val plurals = doc.getElementsByTagName("plurals")
        for (i in 0 until plurals.length) {
            val e = plurals.item(i) as org.w3c.dom.Element
            result["plurals/" + e.getAttribute("name")] = e.getElementsByTagName("item").let { items ->
                (0 until items.length).joinToString("|") { items.item(it).textContent }
            }
        }
        return result
    }

    /** PNG signature plus a non-empty IHDR (javax.imageio is not available to Android unit tests). */
    private fun isPng(file: File): Boolean {
        val bytes = file.inputStream().use { it.readNBytes(24) }
        val signature = byteArrayOf(0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
        val width = java.nio.ByteBuffer.wrap(bytes, 16, 4).int
        val height = java.nio.ByteBuffer.wrap(bytes, 20, 4).int
        return bytes.size == 24 && bytes.copyOf(8).contentEquals(signature) && width > 100 && height > 100
    }

    private fun placeholders(text: String) = Regex("%(\\d\\$)?[ds]").findAll(text).map { it.value }.toSortedSet()
}
