package ai.biniam.sbfexamprep.data

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.serialization.json.Json

/**
 * Stores progress and settings in SharedPreferences. They stay on the device and are
 * included in the user's Android backup (see res/xml/data_extraction_rules.xml).
 */
class ProgressRepository(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("progress", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true }

    private val _progress = MutableStateFlow(loadProgress())
    val progress: StateFlow<ProgressState> = _progress.asStateFlow()

    private val _settings = MutableStateFlow(loadSettings())
    val settings: StateFlow<AppSettings> = _settings.asStateFlow()

    private fun loadProgress(): ProgressState = prefs.getString(KEY_STATE, null)
        ?.let { runCatching { json.decodeFromString(ProgressState.serializer(), it) }.getOrNull() }
        ?: ProgressState()

    private fun loadSettings() = AppSettings(
        showEnglish = prefs.getBoolean("showEnglish", true),
        quizCount = prefs.getInt("quizCount", 20),
        reminderEnabled = prefs.getBoolean("reminderEnabled", false),
        reminderMinutes = prefs.getInt("reminderMinutes", 18 * 60),
        onboardingDone = prefs.getBoolean("onboardingDone", false),
        licenceGoal = prefs.getString("licenceGoal", null)
            ?.let { runCatching { json.decodeFromString(LicenceGoal.serializer(), it) }.getOrNull() }
            ?: LicenceGoal(),
        hasChosenLicence = prefs.contains("licenceGoal"),
    )

    fun updateProgress(change: (ProgressState) -> ProgressState) {
        _progress.update(change)
        prefs.edit { putString(KEY_STATE, json.encodeToString(ProgressState.serializer(), _progress.value)) }
    }

    fun updateSettings(change: (AppSettings) -> AppSettings) {
        _settings.update(change)
        val s = _settings.value
        prefs.edit {
            putBoolean("showEnglish", s.showEnglish)
            putInt("quizCount", s.quizCount)
            putBoolean("reminderEnabled", s.reminderEnabled)
            putInt("reminderMinutes", s.reminderMinutes)
            putBoolean("onboardingDone", s.onboardingDone)
            if (s.hasChosenLicence) putString("licenceGoal", json.encodeToString(LicenceGoal.serializer(), s.licenceGoal))
        }
    }

    fun resetProgress() = updateProgress { ProgressState() }

    private companion object {
        const val KEY_STATE = "state"
    }
}
