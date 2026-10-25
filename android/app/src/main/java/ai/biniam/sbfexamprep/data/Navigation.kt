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
    /** Step-by-step solution diagram (null where the official results do not fix the geometry). */
    val diagram: NavigationDiagram? = null,
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

/** Geometry in nautical miles around the diagram centre; see tools/data/navigation_diagrams.py. */
@Serializable
data class NavigationDiagram(
    val grid: Grid,
    val width: Double,
    val height: Double,
    val elements: List<Element>,
    val frames: List<Frame>,
) {
    /** [k] = cos(latitude): nautical miles per minute of longitude. */
    @Serializable
    data class Grid(val lat: Double, val lon: Double, val k: Double)

    @Serializable
    data class Element(
        val id: String,
        val type: String,
        val style: String,
        val label: String? = null,
        @SerialName("label_en") val labelEn: String? = null,
        val sub: String? = null,
        val x: Double? = null,
        val y: Double? = null,
        val x1: Double? = null,
        val y1: Double? = null,
        val x2: Double? = null,
        val y2: Double? = null,
    ) {
        fun label(german: Boolean) = if (german) label else labelEn ?: label
    }

    @Serializable
    data class Frame(val show: List<String>, val de: String, val en: String, val step: Int? = null) {
        fun text(german: Boolean) = if (german) de else en
    }
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
