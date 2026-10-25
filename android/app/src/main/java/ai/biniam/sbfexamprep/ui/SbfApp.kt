package ai.biniam.sbfexamprep.ui

import androidx.activity.compose.BackHandler
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Checklist
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.adaptive.navigationsuite.NavigationSuiteScaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import ai.biniam.sbfexamprep.DebugLaunch
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.ExamFormat
import ai.biniam.sbfexamprep.data.FeatureFlag
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.SbfApplication
import ai.biniam.sbfexamprep.ui.browse.BrowseScreen
import ai.biniam.sbfexamprep.ui.home.HomeScreen
import ai.biniam.sbfexamprep.ui.onboarding.OnboardingScreen
import ai.biniam.sbfexamprep.ui.quiz.QuizScreen
import ai.biniam.sbfexamprep.ui.quiz.QuizSetupScreen
import ai.biniam.sbfexamprep.ui.navigation.NavigationHost
import ai.biniam.sbfexamprep.ui.quiz.QuizViewModel
import ai.biniam.sbfexamprep.ui.saved.SavedScreen
import ai.biniam.sbfexamprep.ui.settings.SettingsScreen

enum class AppTab(val label: Int, val icon: ImageVector) {
    HOME(R.string.tab_home, Icons.Filled.Home),
    BROWSE(R.string.tab_browse, Icons.AutoMirrored.Filled.MenuBook),
    QUIZ(R.string.tab_quiz, Icons.Filled.Checklist),
    SAVED(R.string.tab_saved, Icons.Filled.Bookmark),
    SETTINGS(R.string.tab_settings, Icons.Filled.Settings),
}

/** Tab label that shrinks instead of wrapping (e.g. "Einstellungen" on narrow phones). */
@Composable
private fun TabLabel(text: String) {
    val style = LocalTextStyle.current
    BasicText(
        text, maxLines = 1, style = style.copy(color = LocalContentColor.current),
        autoSize = TextAutoSize.StepBased(minFontSize = 9.sp, maxFontSize = style.fontSize, stepSize = 0.5.sp),
    )
}

/** Application-wide objects for the composables below the root. */
val LocalApp = staticCompositionLocalOf<SbfApplication> { error("SbfApplication not provided") }

@Composable
fun SbfApp(app: SbfApplication) {
    CompositionLocalProvider(LocalApp provides app) {
        val settings by app.progressRepository.settings.collectAsStateWithLifecycle()
        if (!settings.onboardingDone) {
            OnboardingScreen()
            return@CompositionLocalProvider
        }
        val quiz: QuizViewModel = viewModel { QuizViewModel(app) }
        val holder = rememberSaveableStateHolder()
        var tab by rememberSaveable {
            mutableStateOf(AppTab.entries.firstOrNull { it.name.equals(DebugLaunch.tab, ignoreCase = true) } ?: AppTab.HOME)
        }
        LaunchedEffect(Unit) {
            when (DebugLaunch.quiz) {
                "exam-binnen" -> quiz.setupExam(ExamFormat.BINNEN_MOTOR)
                "exam-segeln" -> quiz.setupExam(ExamFormat.BINNEN_MOTOR_SAIL)
                "exam-see" -> quiz.setupExam(ExamFormat.SEE, app.featureFlags.isOn(FeatureFlag.NAVIGATION_EXAM))
                "navigation-exam" -> { quiz.setupExam(ExamFormat.SEE, includeNavigation = true); quiz.debugSkipToNavigation() }
                "practice" -> quiz.setup(ExamType.ALL, 20)
            }
        }

        if (quiz.active) {
            QuizScreen(quiz)
            return@CompositionLocalProvider
        }
        var navigationOpen by rememberSaveable { mutableStateOf(false) }
        if (navigationOpen) {
            NavigationHost(onClose = { navigationOpen = false })
            return@CompositionLocalProvider
        }

        BackHandler(enabled = tab != AppTab.HOME) { tab = AppTab.HOME }
        NavigationSuiteScaffold(
            navigationSuiteItems = {
                AppTab.entries.forEach { item ->
                    item(
                        selected = tab == item,
                        onClick = { tab = item },
                        icon = { Icon(item.icon, null) },
                        label = { TabLabel(stringResource(item.label)) },
                    )
                }
            },
        ) {
            holder.SaveableStateProvider(tab.name) {
                when (tab) {
                    AppTab.HOME -> HomeScreen(quiz, onBrowse = { tab = AppTab.BROWSE }, onNavigation = { navigationOpen = true })
                    AppTab.BROWSE -> BrowseScreen()
                    AppTab.QUIZ -> QuizSetupScreen(quiz)
                    AppTab.SAVED -> SavedScreen(quiz)
                    AppTab.SETTINGS -> SettingsScreen()
                }
            }
        }
    }
}
