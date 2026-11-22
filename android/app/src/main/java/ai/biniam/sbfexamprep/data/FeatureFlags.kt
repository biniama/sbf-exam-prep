package ai.biniam.sbfexamprep.data

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit
import ai.biniam.sbfexamprep.BuildConfig
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Features behind a flag. Released flags are always on and no longer appear in the flag
 * screen; the others are off by default.
 */
enum class FeatureFlag {
    NAVIGATION_TASKS, NAVIGATION_EXAM, NAVIGATION_DRILLS, NAVIGATION_DIAGRAMS, NAVIGATION_VIDEOS;

    val key: String get() = "ff." + name.lowercase()

    val isReleased: Boolean get() = this in RELEASED

    companion object {
        /** Shipped to everyone. The technique videos (YouTube links) are not released. */
        val RELEASED: Set<FeatureFlag> = setOf(NAVIGATION_TASKS, NAVIGATION_EXAM, NAVIGATION_DRILLS, NAVIGATION_DIAGRAMS)

        /** Flags that can still be toggled for testing. */
        val testable: List<FeatureFlag> get() = entries.filter { !it.isReleased }
    }
}

/**
 * Toggled under Settings → Experimental features. The section is always visible in debug builds;
 * in release builds it appears after tapping the version row seven times. Debug builds also accept
 * `--es featureFlags navigation_tasks,navigation_exam` as a launch extra (see DebugLaunch).
 */
class FeatureFlags(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("feature_flags", Context.MODE_PRIVATE)

    private val _enabled = MutableStateFlow(FeatureFlag.RELEASED + FeatureFlag.testable.filter { prefs.getBoolean(it.key, false) })
    val enabled: StateFlow<Set<FeatureFlag>> = _enabled.asStateFlow()

    private val _unlocked = MutableStateFlow(BuildConfig.DEBUG || prefs.getBoolean("ff.unlocked", false))
    val unlocked: StateFlow<Boolean> = _unlocked.asStateFlow()

    fun isOn(flag: FeatureFlag) = flag in _enabled.value

    fun set(flag: FeatureFlag, on: Boolean) {
        if (flag.isReleased) return
        _enabled.value = if (on) _enabled.value + flag else _enabled.value - flag
        prefs.edit { putBoolean(flag.key, on) }
    }

    fun unlock() {
        _unlocked.value = true
        prefs.edit { putBoolean("ff.unlocked", true) }
    }
}
