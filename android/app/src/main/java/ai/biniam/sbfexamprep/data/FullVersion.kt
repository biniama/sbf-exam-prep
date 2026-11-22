package ai.biniam.sbfexamprep.data

/**
 * The three one-time purchases. School codes (Google Play promo codes) unlock the same
 * products. IDs must match the in-app products in the Play Console.
 */
enum class ProProduct(val productId: String) {
    BINNEN("binnen"),
    SEE("see"),
    BOTH("both");

    companion object {
        fun fromId(id: String): ProProduct? = entries.firstOrNull { it.productId == id }
    }
}

/** What the user owns. Pure logic, shared by the UI, the quiz and the unit tests. */
data class Access(val owned: Set<ProProduct> = emptySet()) {
    val hasBinnen: Boolean get() = ProProduct.BINNEN in owned || ProProduct.BOTH in owned
    val hasSee: Boolean get() = ProProduct.SEE in owned || ProProduct.BOTH in owned
    val hasEverything: Boolean get() = hasBinnen && hasSee

    /** Basic questions are always free; the sailing questions belong to the inland licence. */
    fun hasAccess(type: ExamType): Boolean = when (type) {
        ExamType.SHARED -> true
        ExamType.BINNEN, ExamType.SEGELN -> hasBinnen
        ExamType.SEE -> hasSee
        ExamType.ALL -> hasEverything
    }

    /** Never offer the bundle once one licence is owned, so nobody pays twice. */
    val offeredProducts: List<ProProduct>
        get() = when {
            hasEverything -> emptyList()
            hasBinnen -> listOf(ProProduct.SEE)
            hasSee -> listOf(ProProduct.BINNEN)
            else -> listOf(ProProduct.BOTH, ProProduct.BINNEN, ProProduct.SEE)
        }
}

/** The purchase an exam simulation in this format needs. */
val ExamFormat.licenceType: ExamType get() = if (this == ExamFormat.SEE) ExamType.SEE else ExamType.BINNEN

/** Free tier rules, identical to the iOS app (QuestionStore.makeFreeSample). */
object FreeTier {
    /** Every Nth question of each topic is free. */
    const val SAMPLE_INTERVAL = 7

    /**
     * Within each exam part and topic, sorted by question number, the 1st, 8th, 15th … question
     * is free. Basic questions are free anyway and not part of the sample.
     */
    fun sampleIds(questions: List<Question>): Set<String> =
        questions.filter { it.examType != ExamType.SHARED }
            .groupBy { it.examType to it.category }
            .values
            .flatMap { group -> group.sortedBy { it.questionNumber }.filterIndexed { i, _ -> i % SAMPLE_INTERVAL == 0 } }
            .map { it.uniqueId }
            .toSet()

    fun isUnlocked(question: Question, sample: Set<String>, access: Access): Boolean =
        question.examType == ExamType.SHARED || question.uniqueId in sample || access.hasAccess(question.examType)
}
