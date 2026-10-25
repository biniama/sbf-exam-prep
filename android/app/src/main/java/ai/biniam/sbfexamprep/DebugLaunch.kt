package ai.biniam.sbfexamprep

import android.content.Intent
import ai.biniam.sbfexamprep.data.FeatureFlag
import ai.biniam.sbfexamprep.data.LicenceGoal
import ai.biniam.sbfexamprep.data.ProgressState
import ai.biniam.sbfexamprep.data.QuizRecord
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * Debug-only launch options for UI checks and store screenshots, e.g.
 *
 *     adb shell am start -n ai.biniam.sbfexamprep/.MainActivity \
 *         --ez demoProgress true --es screenshotTab browse --es screenshotQuestion see_093
 *
 * `screenshotQuiz` opens "exam-binnen", "exam-segeln", "exam-see" or "practice". Ignored in release builds.
 */
object DebugLaunch {
    var tab: String? = null
        private set
    var question: String? = null
        private set
    var quiz: String? = null
        private set

    fun read(intent: Intent, app: SbfApplication) {
        if (!BuildConfig.DEBUG) return
        tab = intent.getStringExtra("screenshotTab")
        question = intent.getStringExtra("screenshotQuestion")
        quiz = intent.getStringExtra("screenshotQuiz")
        if (intent.getBooleanExtra("demoProgress", false)) seed(app)
        intent.getStringExtra("featureFlags")?.split(",")?.forEach { name ->
            FeatureFlag.entries.firstOrNull { it.name.equals(name.trim(), ignoreCase = true) }?.let { app.featureFlags.set(it, true) }
        }
    }

    /** Realistic progress so screenshots don't show an empty app (same data as on iOS). */
    private fun seed(app: SbfApplication) {
        val now = ZonedDateTime.now()
        var p = ProgressState()
        app.questions.allQuestions.take(180).forEachIndexed { i, q ->
            p = p.recordAnswer(q.uniqueId, q.category, i % 5 != 0, now.minusDays((i % 9).toLong()))
        }
        app.questions.allQuestions.take(180).forEachIndexed { i, q -> if (i % 4 == 1) p = p.markMastered(q.uniqueId, now) }
        app.questions.allQuestions.drop(20).take(6).forEach { p = p.toggleBookmark(it.uniqueId) }
        val zone = ZoneId.systemDefault()
        val ms = now.toInstant().toEpochMilli()
        p = p.saveQuizRecord(QuizRecord(ms - 90_000_000, "All", 20, 16), zone)
            .saveQuizRecord(QuizRecord(ms - 3_600_000, "Binnen", 30, 27, isExam = true, passed = true), zone)
        val state = p
        app.progressRepository.updateProgress { state }
        app.progressRepository.updateSettings {
            it.copy(onboardingDone = true, licenceGoal = LicenceGoal(LicenceGoal.Inland.MOTOR_AND_SAIL, sea = true),
                    hasChosenLicence = true)
        }
    }
}
