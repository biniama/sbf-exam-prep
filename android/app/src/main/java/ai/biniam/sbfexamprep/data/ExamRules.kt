package ai.biniam.sbfexamprep.data

import kotlinx.serialization.Serializable

/**
 * Exam formats of the multiple-choice theory exam that the app simulates
 * (Bewertungsschlüssel, ELWIS, as of 31 Oct 2022).
 */
enum class ExamFormat(val raw: String) {
    BINNEN_MOTOR("binnen-motor"),
    BINNEN_SAIL("binnen-sail"),
    BINNEN_MOTOR_SAIL("binnen-motor-sail"),
    SAIL_ADDON("sail-addon"),
    SEE("see");

    companion object {
        fun fromRaw(raw: String?): ExamFormat? = entries.firstOrNull { it.raw == raw }
    }
}

/** One separately counted part of an exam; [passMark] is null when only the total counts. */
data class ExamPart(val type: ExamType, val count: Int, val passMark: Int?)

/** [includeNavigation]: the 9-question navigation task of the SBF See (feature flag NAVIGATION_EXAM). */
data class ExamRules(val format: ExamFormat, val includeNavigation: Boolean = false) {
    val parts: List<ExamPart> = when (format) {
        ExamFormat.BINNEN_MOTOR -> listOf(ExamPart(ExamType.SHARED, 7, 5), ExamPart(ExamType.BINNEN, 23, 18))
        ExamFormat.BINNEN_SAIL -> listOf(ExamPart(ExamType.SHARED, 4, null), ExamPart(ExamType.BINNEN, 14, null),
                                         ExamPart(ExamType.SEGELN, 7, null))
        ExamFormat.BINNEN_MOTOR_SAIL -> listOf(ExamPart(ExamType.SHARED, 7, 5), ExamPart(ExamType.BINNEN, 23, 18),
                                               ExamPart(ExamType.SEGELN, 7, 5))
        ExamFormat.SAIL_ADDON -> listOf(ExamPart(ExamType.SEGELN, 7, 5))
        ExamFormat.SEE -> listOf(ExamPart(ExamType.SHARED, 7, 5), ExamPart(ExamType.SEE, 23, 18))
    }

    /** Minimum correct answers over all parts (SBF Binnen under sail only). */
    val totalPassMark: Int? = if (format == ExamFormat.BINNEN_SAIL) 20 else null

    /** Time limit in minutes as in the official exam. */
    val minutes: Int = when (format) {
        ExamFormat.BINNEN_MOTOR -> 45
        ExamFormat.BINNEN_SAIL -> 35
        ExamFormat.BINNEN_MOTOR_SAIL, ExamFormat.SEE -> 60
        ExamFormat.SAIL_ADDON -> 15
    }

    /** Multiple-choice questions only. */
    val totalCount: Int get() = parts.sumOf { it.count }

    val navigationCount: Int = if (format == ExamFormat.SEE && includeNavigation) NavigationExamPart.QUESTION_COUNT else 0

    val includesNavigation: Boolean get() = navigationCount > 0

    /** The navigation task (9 written questions) is part of the SBF See exam; shown when it is not simulated. */
    val excludesNavigationTask: Boolean get() = format == ExamFormat.SEE && !includesNavigation

    fun result(correct: Map<ExamType, Int>, navigationCorrect: Int? = null) = ExamResult(this, correct, navigationCorrect)
}

data class ExamResult(val rules: ExamRules, val correct: Map<ExamType, Int>, val navigationCorrect: Int? = null) {
    fun correct(part: ExamPart): Int = correct[part.type] ?: 0

    /** A part without its own pass mark always counts as passed; the total decides. */
    fun passed(part: ExamPart): Boolean = part.passMark?.let { correct(part) >= it } ?: true

    val totalCorrect: Int get() = rules.parts.sumOf { correct(it) }

    val totalPassed: Boolean get() = rules.totalPassMark?.let { totalCorrect >= it } ?: true

    val navigationPassed: Boolean
        get() = !rules.includesNavigation || (navigationCorrect ?: 0) >= NavigationExamPart.PASS_MARK

    /** Every part with a pass mark and the total (if any) must be passed. */
    val passed: Boolean get() = totalPassed && rules.parts.all { passed(it) } && navigationPassed
}

/** The licences the learner is preparing for ("My licence"). Decides which exam simulations are offered. */
@Serializable
data class LicenceGoal(val inland: Inland = Inland.MOTOR, val sea: Boolean = true) {
    enum class Inland(val format: ExamFormat?) {
        NONE(null), MOTOR(ExamFormat.BINNEN_MOTOR), SAIL(ExamFormat.BINNEN_SAIL),
        MOTOR_AND_SAIL(ExamFormat.BINNEN_MOTOR_SAIL), SAIL_ADDON(ExamFormat.SAIL_ADDON),
    }

    val isValid: Boolean get() = inland != Inland.NONE || sea

    val includesSailing: Boolean get() = inland == Inland.SAIL || inland == Inland.MOTOR_AND_SAIL || inland == Inland.SAIL_ADDON

    val examFormats: List<ExamFormat>
        get() = (listOfNotNull(inland.format) + if (sea) listOf(ExamFormat.SEE) else emptyList())
            .ifEmpty { listOf(ExamFormat.BINNEN_MOTOR, ExamFormat.SEE) }
}
