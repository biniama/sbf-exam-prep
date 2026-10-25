package ai.biniam.sbfexamprep.ui.navigation

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Draw
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ai.biniam.sbfexamprep.R
import androidx.compose.material.icons.filled.Speed
import ai.biniam.sbfexamprep.data.LightCharacter
import ai.biniam.sbfexamprep.data.FeatureFlag
import ai.biniam.sbfexamprep.data.NavigationStep
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.ReadableWidth
import ai.biniam.sbfexamprep.ui.components.SectionHeader
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.components.isGerman
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf

/** Screens of the navigation-task feature (feature flag NAVIGATION_TASKS). */
private sealed interface NavScreen {
    data object List : NavScreen
    data class Task(val number: Int) : NavScreen
    data object Glossary : NavScreen
    data object Drills : NavScreen
}

/** [start]: "list" (task list) or "drills". Going back from the start screen closes the feature. */
@Composable
fun NavigationHost(start: String = "list", onClose: () -> Unit) {
    var screenKey by rememberSaveable { mutableStateOf(start) }
    val screen: NavScreen = when {
        screenKey == "glossary" -> NavScreen.Glossary
        screenKey == "drills" -> NavScreen.Drills
        screenKey.startsWith("task:") -> NavScreen.Task(screenKey.removePrefix("task:").toInt())
        else -> NavScreen.List
    }
    val back = { if (screenKey == start) onClose() else screenKey = "list" }
    BackHandler(onBack = back)
    when (screen) {
        NavScreen.List -> NavigationTaskList(onBack = onClose, onTask = { screenKey = "task:$it" },
                                             onGlossary = { screenKey = "glossary" }, onDrills = { screenKey = "drills" })
        is NavScreen.Task -> NavigationTaskScreen(screen.number, onBack = back)
        NavScreen.Glossary -> NavigationGlossary(onBack = back)
        NavScreen.Drills -> NavigationDrillsScreen(onBack = back)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun NavScaffold(title: String, onBack: () -> Unit, content: @Composable () -> Unit) {
    Scaffold(
        containerColor = Sbf.colors.surface,
        topBar = {
            TopAppBar(
                title = { Text(title) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, stringResource(R.string.back)) }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Sbf.colors.surface),
            )
        },
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState())) {
            ReadableWidth { Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) { content() } }
        }
    }
}

@Composable
private fun NavigationTaskList(onBack: () -> Unit, onTask: (Int) -> Unit, onGlossary: () -> Unit, onDrills: () -> Unit) {
    val app = LocalApp.current
    val catalog = app.navigation
    val flags by app.featureFlags.enabled.collectAsStateWithLifecycle()
    NavScaffold(stringResource(R.string.nav_tasks_title), onBack) {
        Row(Modifier.fillMaxWidth().cardStyle().padding(16.dp), verticalAlignment = Alignment.Top) {
            Icon(Icons.Filled.Map, null, tint = Brand.gold)
            Spacer(Modifier.width(14.dp))
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(stringResource(R.string.nav_chart_title), style = MaterialTheme.typography.titleSmall,
                     fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink)
                Text(stringResource(R.string.nav_chart_text), style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted)
            }
        }
        if (FeatureFlag.NAVIGATION_DRILLS in flags) {
            Row(Modifier.fillMaxWidth().cardStyle().clickable(onClick = onDrills).padding(16.dp),
                verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Speed, null, tint = Brand.navyLight)
                Spacer(Modifier.width(14.dp))
                Text(stringResource(R.string.ff_navigation_drills), Modifier.weight(1f), style = MaterialTheme.typography.titleSmall,
                     fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink)
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Sbf.colors.muted)
            }
        }
        Row(Modifier.fillMaxWidth().cardStyle().clickable(onClick = onGlossary).padding(16.dp),
            verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.Translate, null, tint = Brand.navyLight)
            Spacer(Modifier.width(14.dp))
            Text(stringResource(R.string.nav_glossary), Modifier.weight(1f), style = MaterialTheme.typography.titleSmall,
                 fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink)
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Sbf.colors.muted)
        }
        SectionHeader(stringResource(R.string.nav_tasks_section), Icons.Filled.Explore)
        catalog.tasks.forEach { task ->
            Row(Modifier.fillMaxWidth().cardStyle().clickable { onTask(task.number) }.padding(14.dp),
                verticalAlignment = Alignment.Top) {
                Box(Modifier.size(36.dp).clip(RoundedCornerShape(10.dp)).background(Brand.navyLight),
                    contentAlignment = Alignment.Center) {
                    Text("${task.number}", color = androidx.compose.ui.graphics.Color.White, fontWeight = FontWeight.Bold)
                }
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(stringResource(R.string.nav_task_n, task.number), style = MaterialTheme.typography.titleSmall,
                         fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink)
                    Text(task.introDe, style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted, maxLines = 3)
                }
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Sbf.colors.muted)
            }
        }
        Text(stringResource(R.string.nav_source), style = MaterialTheme.typography.labelSmall, color = Sbf.colors.muted)
    }
}

@Composable
private fun NavigationTaskScreen(number: Int, onBack: () -> Unit) {
    val app = LocalApp.current
    val task = app.navigation.task(number) ?: return onBack()
    val settings by app.progressRepository.settings.collectAsStateWithLifecycle()
    val flags by app.featureFlags.enabled.collectAsStateWithLifecycle()
    var revealed by rememberSaveable { mutableStateOf(setOf<Int>()) }
    NavScaffold(stringResource(R.string.nav_task_n, number), onBack) {
        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Brand.navyLight.copy(alpha = 0.10f)).padding(16.dp)) {
            Bilingual(task.introDe, task.introEn, settings.showEnglish)
        }
        task.values.mw?.let { mw ->
            Text(stringResource(R.string.nav_variation, signedDegrees(mw)), style = MaterialTheme.typography.bodySmall,
                 color = Sbf.colors.muted)
        }
        task.steps.forEach { step ->
            StepCard(step, step.number in revealed, settings.showEnglish, FeatureFlag.NAVIGATION_DRILLS in flags) {
                revealed = if (step.number in revealed) revealed - step.number else revealed + step.number
            }
        }
        if (task.notesDe.isNotEmpty()) {
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Sbf.colors.error.copy(alpha = 0.08f)).padding(12.dp)) {
                Bilingual(task.notesDe, task.notesEn, settings.showEnglish, small = true)
            }
        }
        val all = revealed.size == task.steps.size
        TextButton(onClick = { revealed = if (all) emptySet() else task.steps.map { it.number }.toSet() },
                   modifier = Modifier.fillMaxWidth()) {
            Text(stringResource(if (all) R.string.nav_hide_all else R.string.nav_show_all), fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun StepCard(step: NavigationStep, open: Boolean, showEnglish: Boolean, showLight: Boolean, onToggle: () -> Unit) {
    val german = isGerman()
    Column(Modifier.fillMaxWidth().cardStyle().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.Top) {
            Box(Modifier.size(26.dp).clip(CircleShape).background(Brand.gold.copy(alpha = 0.35f)), contentAlignment = Alignment.Center) {
                Text("${step.number}", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold, color = Brand.navy)
            }
            Spacer(Modifier.width(10.dp))
            Bilingual(step.questionDe, step.questionEn, showEnglish)
        }
        if (step.isPlot) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Draw, null, Modifier.size(16.dp), tint = Brand.oceanTeal)
                Spacer(Modifier.width(6.dp))
                Text(stringResource(R.string.nav_chart_work), style = MaterialTheme.typography.labelMedium, color = Brand.oceanTeal)
            }
        }
        AnimatedVisibility(open) {
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Sbf.colors.success.copy(alpha = 0.08f)).padding(12.dp),
                   verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(stringResource(R.string.nav_official_result), style = MaterialTheme.typography.labelMedium,
                     fontWeight = FontWeight.SemiBold, color = Sbf.colors.success)
                Bilingual(step.answerDe, step.answerEn, showEnglish, emphasis = true)
                if (showLight) step.code?.let(LightCharacter::parse)?.let { LightBeacon(it, 70.dp) }
                if (step.solution.isNotEmpty()) {
                    HorizontalDivider(color = Sbf.colors.hairline)
                    Text(stringResource(R.string.nav_how_to_solve), style = MaterialTheme.typography.labelMedium,
                         fontWeight = FontWeight.SemiBold, color = Sbf.colors.inkSecondary)
                    step.solution.forEach { line ->
                        val text = line.text(german)
                        Text(text, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink,
                             fontWeight = if ('=' in text) FontWeight.Medium else FontWeight.Normal)
                    }
                }
            }
        }
        TextButton(onClick = onToggle, contentPadding = androidx.compose.foundation.layout.PaddingValues(0.dp)) {
            Icon(if (open) Icons.Filled.VisibilityOff else Icons.Filled.Visibility, null, Modifier.size(18.dp))
            Spacer(Modifier.width(6.dp))
            Text(stringResource(if (open) R.string.nav_hide_solution else R.string.nav_show_solution), fontWeight = FontWeight.SemiBold)
        }
    }
}

/** German text as in the exam, with the English translation below when enabled. */
@Composable
private fun Bilingual(de: String, en: String?, showEnglish: Boolean, emphasis: Boolean = false, small: Boolean = false) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(de, style = if (small) MaterialTheme.typography.bodySmall else MaterialTheme.typography.bodyLarge,
             fontWeight = if (emphasis) FontWeight.SemiBold else FontWeight.Normal, color = Sbf.colors.ink)
        if (showEnglish && !en.isNullOrEmpty()) {
            Text(en, style = MaterialTheme.typography.bodySmall, fontStyle = FontStyle.Italic, color = Sbf.colors.inkSecondary)
        }
    }
}

@Composable
private fun NavigationGlossary(onBack: () -> Unit) {
    val catalog = LocalApp.current.navigation
    val german = isGerman()
    NavScaffold(stringResource(R.string.nav_glossary), onBack) {
        Column(Modifier.fillMaxWidth().cardStyle()) {
            catalog.glossary.forEachIndexed { i, entry ->
                if (i > 0) HorizontalDivider(Modifier.padding(start = 14.dp), color = Sbf.colors.hairline)
                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(entry.abbr, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = Brand.navy)
                        Spacer(Modifier.width(10.dp))
                        Text(if (german) entry.de else "${entry.de} – ${entry.en}", style = MaterialTheme.typography.bodyMedium,
                             fontWeight = FontWeight.SemiBold, color = Sbf.colors.ink)
                    }
                    Text(if (german) entry.explanationDe else entry.explanationEn, style = MaterialTheme.typography.bodySmall,
                         color = Sbf.colors.muted)
                }
            }
        }
        Text(stringResource(R.string.nav_signs), style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted)
        SectionHeader(stringResource(R.string.nav_question_types), Icons.Filled.Explore)
        Column(Modifier.fillMaxWidth().cardStyle().padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            catalog.questionTypes.forEach { type ->
                Text("${type.number}. ${type.de}", style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink)
                if (!german) Text(type.en, style = MaterialTheme.typography.bodySmall, fontStyle = FontStyle.Italic, color = Sbf.colors.muted)
            }
        }
    }
}

private fun signedDegrees(v: Double) = if (v == 0.0) "0°" else "%+.0f°".format(v)
