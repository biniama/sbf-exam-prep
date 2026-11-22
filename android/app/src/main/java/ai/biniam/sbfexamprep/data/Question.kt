package ai.biniam.sbfexamprep.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ExamData(
    val metadata: Metadata,
    @SerialName("exam_sections") val examSections: List<ExamSection>,
)

@Serializable
data class Metadata(
    val title: String,
    @SerialName("catalog_date") val catalogDate: String,
    @SerialName("total_questions") val totalQuestions: Int,
    val languages: List<String>,
    val note: String,
)

@Serializable
data class ExamSection(
    @SerialName("exam_type") val examType: String,
    val description: String,
    @SerialName("total") val questionCount: Int,
    val questions: List<Question>,
)

@Serializable
data class QuestionOption(val german: String, val english: String)

/** An option as shown on screen: [key] is the A–D label, [originalKey] the catalogue key. */
data class DisplayOption(val key: String, val originalKey: String, val option: QuestionOption, val isCorrect: Boolean)

@Serializable
data class Question(
    @SerialName("unique_id") val uniqueId: String,
    @SerialName("question_number") val questionNumber: Int,
    val category: String,
    @SerialName("category_de") val categoryDE: String? = null,
    @SerialName("german_text") val germanText: String,
    @SerialName("english_text") val englishText: String,
    val options: Map<String, QuestionOption>,
    @SerialName("correct_option") val correctOption: String,
    @SerialName("has_image") val hasImage: Boolean,
    @SerialName("image_reference") val imageReference: String? = null,
    @SerialName("image_references") val imageReferences: List<String>? = null,
    @SerialName("sound_pattern") val soundPattern: String? = null,
    @SerialName("explanation_de") val explanationDE: String? = null,
    @SerialName("explanation_en") val explanationEN: String? = null,
) {
    val examType: ExamType
        get() = when {
            uniqueId.startsWith("shared") -> ExamType.SHARED
            uniqueId.startsWith("binnen") -> ExamType.BINNEN
            uniqueId.startsWith("segeln") -> ExamType.SEGELN
            else -> ExamType.SEE
        }

    /** Asset paths of the illustrations, e.g. `assets/see/see_091.png`. */
    val imagePaths: List<String>
        get() = imageReferences ?: listOfNotNull(imageReference)

    /** True when the question has an illustration or a playable sound signal. */
    val hasMedia: Boolean get() = hasImage || soundPattern != null

    fun category(german: Boolean): String = if (german) categoryDE ?: category else category

    /** Explanation in the display language, falling back to the other language. */
    fun explanation(german: Boolean): String? =
        if (german) explanationDE ?: explanationEN else explanationEN ?: explanationDE

    val correctText: QuestionOption? get() = options[correctOption]

    /** Option keys in catalogue order (in the official catalogue A is always correct). */
    val sortedKeys: List<String> get() = options.keys.sorted()

    /**
     * Options in a stable, per-question shuffled order, relabelled A–D, so that the
     * correct answer is not always "A" while browsing.
     */
    val displayOptions: List<DisplayOption>
        get() {
            val keys = sortedKeys
            val shuffled = keys.toMutableList().also { it.shuffleSeeded(SplitMix64(uniqueId.stableHash())) }
            return keys.mapIndexedNotNull { index, label ->
                val original = shuffled[index]
                options[original]?.let { DisplayOption(label, original, it, original == correctOption) }
            }
        }
}

enum class ExamType(val raw: String) {
    ALL("All"), SHARED("Shared"), BINNEN("Binnen"), SEGELN("Segeln"), SEE("See");

    companion object {
        fun fromRaw(raw: String): ExamType = entries.firstOrNull { it.raw == raw } ?: ALL
    }
}

// Deterministic shuffling ------------------------------------------------------------------

/** SplitMix64, the same generator as the iOS app. */
class SplitMix64(seed: ULong) {
    private var state: ULong = if (seed == 0uL) 0x9E3779B97F4A7C15uL else seed

    fun next(): ULong {
        state += 0x9E3779B97F4A7C15uL
        var z = state
        z = (z xor (z shr 30)) * 0xBF58476D1CE4E5B9uL
        z = (z xor (z shr 27)) * 0x94D049BB133111EBuL
        return z xor (z shr 31)
    }
}

fun <T> MutableList<T>.shuffleSeeded(rng: SplitMix64) {
    for (i in lastIndex downTo 1) {
        val j = (rng.next() % (i + 1).toULong()).toInt()
        val tmp = this[i]; this[i] = this[j]; this[j] = tmp
    }
}

/** FNV-1a hash that is stable across launches. */
fun String.stableHash(): ULong {
    var hash = 0xcbf29ce484222325uL
    for (byte in encodeToByteArray()) {
        hash = hash xor byte.toUByte().toULong()
        hash *= 0x100000001b3uL
    }
    return hash
}
