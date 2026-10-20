package ai.biniam.sbfexamprep.data

import kotlinx.serialization.json.Json
import java.io.InputStream
import java.text.Collator
import java.util.Locale

/** The official question catalogue, loaded once from `sbf_exam_questions.json`. */
class QuestionRepository(json: String) {
    val metadata: Metadata
    val sections: List<ExamSection>
    val allQuestions: List<Question>
    private val byId: Map<String, Question>

    init {
        val data = parser.decodeFromString(ExamData.serializer(), json)
        metadata = data.metadata
        sections = data.examSections
        allQuestions = data.examSections.flatMap { it.questions }
        byId = allQuestions.associateBy { it.uniqueId }
    }

    /** Questions of an exam. Basic questions (Basisfragen) belong to both licences. */
    fun questions(type: ExamType): List<Question> = when (type) {
        ExamType.ALL -> allQuestions
        ExamType.SHARED -> allQuestions.filter { it.examType == ExamType.SHARED }
        ExamType.BINNEN -> allQuestions.filter { it.examType == ExamType.BINNEN || it.examType == ExamType.SHARED }
        ExamType.SEE -> allQuestions.filter { it.examType == ExamType.SEE || it.examType == ExamType.SHARED }
    }

    fun questions(type: ExamType, category: String?): List<Question> =
        questions(type).let { base -> if (category == null) base else base.filter { it.category == category } }

    /** Licence-specific questions only (without the shared basic questions). */
    fun specificQuestions(type: ExamType): List<Question> = allQuestions.filter { it.examType == type }

    /** Canonical (English) category keys, sorted by their display name. */
    fun categories(type: ExamType, german: Boolean): List<String> {
        val collator = Collator.getInstance(if (german) Locale.GERMAN else Locale.ENGLISH)
        return questions(type).map { it.category }.distinct()
            .sortedWith { a, b -> collator.compare(categoryName(a, german), categoryName(b, german)) }
    }

    fun categoryName(key: String, german: Boolean): String =
        allQuestions.firstOrNull { it.category == key }?.category(german) ?: key

    fun question(id: String): Question? = byId[id]

    companion object {
        private val parser = Json { ignoreUnknownKeys = true }
        const val ASSET_NAME = "sbf_exam_questions.json"

        fun load(stream: InputStream) = QuestionRepository(stream.bufferedReader().use { it.readText() })
    }
}
