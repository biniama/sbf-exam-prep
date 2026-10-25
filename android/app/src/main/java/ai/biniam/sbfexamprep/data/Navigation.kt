package ai.biniam.sbfexamprep.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull
import java.io.InputStream

/** The 15 official navigation tasks of the SBF See (ELWIS, chart D49), from navigation_tasks.json. */
@Serializable
data class NavigationCatalog(
    val source: String,
    @SerialName("source_url") val sourceUrl: String,
    val chart: String,
    @SerialName("chart_excerpts") val chartExcerpts: List<String>,
    val tolerances: NavigationTolerances,
    val glossary: List<GlossaryEntry>,
    @SerialName("question_types") val questionTypes: List<QuestionTypeEntry>,
    val tasks: List<NavigationTask>,
) {
    fun task(number: Int) = tasks.firstOrNull { it.number == number }

    companion object {
        const val ASSET_NAME = "navigation_tasks.json"
        private val parser = Json { ignoreUnknownKeys = true }

        fun load(stream: InputStream): NavigationCatalog =
            parser.decodeFromString(serializer(), stream.bufferedReader().use { it.readText() })
    }
}

/** Practice tolerances for typed answers (ELWIS publishes no official tolerances). */
@Serializable
data class NavigationTolerances(
    val degrees: Double,
    val nm: Double,
    val minutes: Double,
    val knots: Double,
    @SerialName("arc_minutes") val arcMinutes: Double,
)

@Serializable
data class GlossaryEntry(
    val abbr: String,
    val de: String,
    val en: String,
    @SerialName("explanation_de") val explanationDe: String,
    @SerialName("explanation_en") val explanationEn: String,
)

@Serializable
data class QuestionTypeEntry(val number: Int, val de: String, val en: String)

@Serializable
data class NavigationTask(
    val number: Int,
    @SerialName("intro_de") val introDe: String,
    @SerialName("intro_en") val introEn: String? = null,
    @SerialName("notes_de") val notesDe: String = "",
    @SerialName("notes_en") val notesEn: String? = null,
    val values: TaskValues = TaskValues(),
    val steps: List<NavigationStep>,
) {
    @Serializable
    data class TaskValues(val mw: Double? = null, @SerialName("speed_kn") val speedKn: Double? = null)
}

@Serializable
data class NavigationStep(
    val number: Int,
    @SerialName("question_de") val questionDe: String,
    @SerialName("question_en") val questionEn: String? = null,
    @SerialName("answer_de") val answerDe: String,
    @SerialName("answer_en") val answerEn: String? = null,
    val kind: String,
    val solution: List<SolutionLine> = emptyList(),
    val check: AnswerCheck? = null,
    /** Light character code such as "Oc(3).Y.12s" (light descriptions only). */
    val code: String? = null,
) {
    /** Sub-questions that are answered by drawing on the chart. */
    val isPlot: Boolean get() = kind == "plot"
}

@Serializable
data class SolutionLine(val de: String, val en: String) {
    fun text(german: Boolean) = if (german) de else en
}

/** How a typed answer is checked; positions as [degrees, minutes]. Values are numbers or clock times. */
@Serializable
data class AnswerCheck(
    val type: String,
    val values: List<JsonPrimitive>? = null,
    val lat: List<Double>? = null,
    val lon: List<Double>? = null,
    val direction: Double? = null,
    val nm: Double? = null,
) {
    val numbers: List<Double> get() = values.orEmpty().mapNotNull { it.doubleOrNull }
    val texts: List<String> get() = values.orEmpty().filter { it.isString }.map { it.content }
}
