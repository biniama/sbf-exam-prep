package ai.biniam.sbfexamprep.data

import androidx.compose.runtime.mutableStateMapOf
import kotlin.math.abs
import kotlin.math.min

/** Input fields of one navigation sub-question in the exam simulation. */
enum class NavigationField {
    DEGREES, NAUTICAL_MILES, MINUTES, KNOTS, CLOCK,
    LATITUDE_DEGREES, LATITUDE_MINUTES, LONGITUDE_DEGREES, LONGITUDE_MINUTES, TEXT;

    companion object {
        /** Fields for a sub-question; free text when the answer cannot be checked automatically. */
        fun fieldsFor(step: NavigationStep): List<NavigationField> {
            val check = step.check ?: return listOf(TEXT)
            return when (check.type) {
                "degrees" -> List(check.values?.size ?: 1) { DEGREES }
                "nm" -> listOf(NAUTICAL_MILES)
                "minutes" -> listOf(MINUTES)
                "knots" -> listOf(KNOTS)
                "clock" -> listOf(CLOCK)
                "position" -> listOf(LATITUDE_DEGREES, LATITUDE_MINUTES, LONGITUDE_DEGREES, LONGITUDE_MINUTES)
                "set_drift" -> listOf(DEGREES, NAUTICAL_MILES)
                else -> listOf(TEXT)
            }
        }
    }
}

/** Checks typed answers against the official results within the practice tolerances. */
object NavigationAnswerChecker {
    /** `null` when the sub-question has to be graded by the learner (chart work, descriptions). */
    fun isCorrect(step: NavigationStep, inputs: List<String>, t: NavigationTolerances): Boolean? {
        val check = step.check ?: return null
        return when (check.type) {
            "degrees" -> {
                val expected = check.numbers
                inputs.size >= expected.size && expected.zip(inputs).all { (e, input) ->
                    number(input)?.let { angleDifference(it, e) <= t.degrees } ?: false
                }
            }
            "nm" -> within(inputs.firstOrNull(), check.numbers.firstOrNull(), t.nm)
            "minutes" -> within(inputs.firstOrNull(), check.numbers.firstOrNull(), t.minutes)
            "knots" -> within(inputs.firstOrNull(), check.numbers.firstOrNull(), t.knots)
            "clock" -> {
                val expected = check.texts.firstOrNull()?.let(::clockMinutes)
                val given = inputs.firstOrNull()?.let(::clockMinutes)
                expected != null && given != null && abs(given - expected) <= t.minutes + 1
            }
            "position" -> {
                val lat = check.lat ?: return false
                val lon = check.lon ?: return false
                val v = inputs.take(4).map(::number)
                if (v.size < 4 || v.any { it == null }) return false
                val dLat = abs((v[0]!! * 60 + v[1]!!) - (lat[0] * 60 + lat[1]))
                val dLon = abs((v[2]!! * 60 + v[3]!!) - (lon[0] * 60 + lon[1]))
                dLat <= t.arcMinutes && dLon <= t.arcMinutes
            }
            "set_drift" -> {
                val d = inputs.getOrNull(0)?.let(::number)
                val n = inputs.getOrNull(1)?.let(::number)
                // Small displacements make the direction sensitive; allow a little more there.
                d != null && n != null && check.direction != null && check.nm != null &&
                    angleDifference(d, check.direction) <= t.degrees * 3 && abs(n - check.nm) <= t.nm
            }
            else -> null
        }
    }

    fun number(s: String): Double? = s.trim().replace(",", ".").replace("°", "").toDoubleOrNull()

    /** "15:12", "15.12" or "1512" → minutes after midnight. */
    fun clockMinutes(s: String): Double? {
        val digits = s.filter { it.isDigit() }
        if (digits.length !in 3..4) return null
        val value = digits.toInt()
        val h = value / 100
        val m = value % 100
        return if (h < 24 && m < 60) (h * 60 + m).toDouble() else null
    }

    fun angleDifference(a: Double, b: Double): Double {
        val d = abs(a - b) % 360
        return min(d, 360 - d)
    }

    private fun within(input: String?, expected: Double?, tolerance: Double): Boolean {
        val v = input?.let(::number) ?: return false
        return expected != null && abs(v - expected) <= tolerance + 1e-9
    }
}

/** The navigation part of an exam simulation: one task, 9 sub-questions, pass with 7. */
class NavigationExamPart(val task: NavigationTask, val tolerances: NavigationTolerances) {
    val inputs = mutableStateMapOf<Int, List<String>>().apply {
        task.steps.forEach { put(it.number, List(NavigationField.fieldsFor(it).size) { "" }) }
    }

    /** Learner's own grading for sub-questions that cannot be checked automatically. */
    val selfGrades = mutableStateMapOf<Int, Boolean>()

    fun autoResult(step: NavigationStep): Boolean? =
        NavigationAnswerChecker.isCorrect(step, inputs[step.number].orEmpty(), tolerances)

    fun isCorrect(step: NavigationStep): Boolean = autoResult(step) ?: (selfGrades[step.number] ?: false)

    val correctCount: Int get() = task.steps.count { isCorrect(it) }

    fun setInput(step: Int, index: Int, value: String) {
        val values = inputs[step].orEmpty().toMutableList()
        while (values.size <= index) values.add("")
        values[index] = value
        inputs[step] = values
    }

    companion object {
        const val QUESTION_COUNT = 9
        const val PASS_MARK = 7
    }
}
