package ai.biniam.sbfexamprep.data

/**
 * Official ELWIS scoring for the multiple-choice part of the theory exam
 * (Bewertungsschlüssel, ELWIS, as of 31 Oct 2022).
 *
 * Both licences: 7 basic questions (pass ≥ 5) + 23 licence-specific questions (pass ≥ 18).
 * SBF Binnen: 45 minutes. SBF See: 60 minutes including a 9-question navigation task,
 * which this app does not simulate.
 */
data class ExamRules(val type: ExamType) {
    init {
        require(type == ExamType.BINNEN || type == ExamType.SEE) { "Exam simulation exists for SBF Binnen and SBF See" }
    }

    val basicCount = 7
    val basicPassMark = 5
    val specificCount = 23
    val specificPassMark = 18
    val totalCount get() = basicCount + specificCount

    /** Time limit in minutes as in the official exam. */
    val minutes get() = if (type == ExamType.BINNEN) 45 else 60

    /** The navigation task (9 written questions) is part of the SBF See exam but not of this app. */
    val excludesNavigationTask get() = type == ExamType.SEE

    fun result(basicCorrect: Int, specificCorrect: Int) = ExamResult(this, basicCorrect, specificCorrect)
}

data class ExamResult(val rules: ExamRules, val basicCorrect: Int, val specificCorrect: Int) {
    val basicPassed get() = basicCorrect >= rules.basicPassMark
    val specificPassed get() = specificCorrect >= rules.specificPassMark

    /** Both parts are assessed separately; the exam is passed only if both are passed. */
    val passed get() = basicPassed && specificPassed
}
