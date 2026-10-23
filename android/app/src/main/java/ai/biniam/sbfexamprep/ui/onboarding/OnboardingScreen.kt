package ai.biniam.sbfexamprep.ui.onboarding

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Sailing
import androidx.compose.material.icons.filled.TextFields
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.app.NotificationManagerCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.reminders.ReminderScheduler
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.LightStatusBarIcons
import ai.biniam.sbfexamprep.ui.theme.Brand
import kotlinx.coroutines.launch

private const val PAGES = 4

@Composable
fun OnboardingScreen() {
    val app = LocalApp.current
    val context = LocalContext.current
    val settings by app.progressRepository.settings.collectAsStateWithLifecycle()
    val pager = rememberPagerState { PAGES }
    val scope = rememberCoroutineScope()
    fun goTo(page: Int) = scope.launch { pager.animateScrollToPage(page) }
    fun finish() = app.progressRepository.updateSettings { it.copy(onboardingDone = true) }

    fun enableReminder(granted: Boolean) {
        if (granted) {
            app.progressRepository.updateSettings { it.copy(reminderEnabled = true, reminderMinutes = 18 * 60) }
            ReminderScheduler.schedule(context, 18 * 60)
        }
        goTo(3)
    }
    val permission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission(), ::enableReminder)
    LightStatusBarIcons()

    Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Brand.navy, Brand.navyMid)))) {
        Column(Modifier.fillMaxSize().safeDrawingPadding()) {
            HorizontalPager(pager, Modifier.weight(1f)) { page ->
                Column(
                    Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 28.dp, vertical = 32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
                ) {
                    Column(Modifier.widthIn(max = 560.dp), horizontalAlignment = Alignment.CenterHorizontally,
                           verticalArrangement = Arrangement.spacedBy(16.dp)) {
                        when (page) {
                            0 -> Welcome(app.questions.allQuestions.size)
                            1 -> Features()
                            2 -> Reminder(
                                onEnable = {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                        permission.launch(Manifest.permission.POST_NOTIFICATIONS)
                                    } else {
                                        enableReminder(NotificationManagerCompat.from(context).areNotificationsEnabled())
                                    }
                                },
                                onSkip = { goTo(3) },
                            )
                            else -> Translations(settings.showEnglish) { on ->
                                app.progressRepository.updateSettings { it.copy(showEnglish = on) }
                            }
                        }
                    }
                }
            }
            // Page indicator and main button
            Column(Modifier.fillMaxWidth().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally,
                   verticalArrangement = Arrangement.spacedBy(16.dp)) {
                val pageLabel = stringResource(R.string.page_n_of_m, pager.currentPage + 1, PAGES)
                Row(Modifier.clearAndSetSemantics { contentDescription = pageLabel }, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    repeat(PAGES) { i ->
                        Box(Modifier.size(if (i == pager.currentPage) 10.dp else 8.dp).clip(CircleShape)
                            .background(if (i == pager.currentPage) Brand.gold else Color.White.copy(alpha = 0.3f)))
                    }
                }
                val last = pager.currentPage == PAGES - 1
                Surface(
                    onClick = { if (last) finish() else goTo(pager.currentPage + 1) },
                    shape = RoundedCornerShape(16.dp), color = Brand.gold,
                    modifier = Modifier.widthIn(max = 480.dp).fillMaxWidth(),
                ) {
                    Text(stringResource(if (last) R.string.get_started else R.string.continue_label),
                         Modifier.padding(vertical = 16.dp), textAlign = TextAlign.Center,
                         style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = Brand.navy)
                }
            }
        }
    }
}

@Composable
private fun Title(text: String) = Text(text, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold,
                                       color = Color.White, textAlign = TextAlign.Center, modifier = Modifier.semantics { heading() })

@Composable
private fun Body(text: String) = Text(text, style = MaterialTheme.typography.bodyLarge, color = Color.White.copy(alpha = 0.8f),
                                      textAlign = TextAlign.Center)

@Composable
private fun Welcome(count: Int) {
    Box(Modifier.size(120.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.08f)), contentAlignment = Alignment.Center) {
        Icon(Icons.Filled.Sailing, null, Modifier.size(64.dp), tint = Brand.gold)
    }
    Text(stringResource(R.string.app_name), style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold,
         color = Color.White, modifier = Modifier.semantics { heading() })
    Text(stringResource(R.string.app_subtitle), style = MaterialTheme.typography.titleSmall, color = Brand.goldLight)
    Spacer(Modifier.size(8.dp))
    Title(stringResource(R.string.pass_your_exam))
    Body(stringResource(R.string.onboarding_all_questions, count))
    // Play policy: government information must link to its original source.
    val uri = androidx.compose.ui.platform.LocalUriHandler.current
    Text(stringResource(R.string.not_government), style = MaterialTheme.typography.bodySmall,
         color = Color.White.copy(alpha = 0.7f), textAlign = TextAlign.Center)
    TextButton(onClick = { uri.openUri(ai.biniam.sbfexamprep.ui.AppLinks.ELWIS) }) {
        Text(stringResource(R.string.source_elwis), color = Brand.goldLight)
    }
}

@Composable
private fun Features() {
    Title(stringResource(R.string.everything_you_need))
    Spacer(Modifier.size(4.dp))
    FeatureRow(Icons.Filled.Verified, Color(0xFF34C759), stringResource(R.string.official_questions), stringResource(R.string.official_questions_text))
    FeatureRow(Icons.Filled.Timer, Color(0xFFFF9500), stringResource(R.string.real_exam_sim), stringResource(R.string.real_exam_sim_text))
    FeatureRow(Icons.Filled.Image, Brand.oceanTeal, stringResource(R.string.signs_lights_sounds), stringResource(R.string.signs_lights_sounds_text))
    FeatureRow(Icons.Filled.Replay, Color(0xFFAF52DE), stringResource(R.string.spaced_repetition), stringResource(R.string.due_explainer))
}

@Composable
private fun FeatureRow(icon: ImageVector, color: Color, title: String, body: String) {
    Row(Modifier.fillMaxWidth().semantics(mergeDescendants = true) {}, verticalAlignment = Alignment.Top) {
        Box(Modifier.size(44.dp).clip(RoundedCornerShape(12.dp)).background(color), contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = Color.White)
        }
        Spacer(Modifier.width(14.dp))
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, color = Color.White)
            Text(body, style = MaterialTheme.typography.bodyMedium, color = Color.White.copy(alpha = 0.75f))
        }
    }
}

@Composable
private fun Reminder(onEnable: () -> Unit, onSkip: () -> Unit) {
    Box(Modifier.size(110.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.08f)), contentAlignment = Alignment.Center) {
        Icon(Icons.Filled.Notifications, null, Modifier.size(56.dp), tint = Brand.gold)
    }
    Title(stringResource(R.string.stay_on_track))
    Body(stringResource(R.string.reminder_pitch))
    Surface(onClick = onEnable, shape = RoundedCornerShape(14.dp), color = Color.White.copy(alpha = 0.12f),
            modifier = Modifier.fillMaxWidth().border(1.dp, Brand.gold.copy(alpha = 0.6f), RoundedCornerShape(14.dp))) {
        Row(Modifier.padding(16.dp), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.NotificationsActive, null, tint = Brand.gold)
            Spacer(Modifier.width(8.dp))
            Text(stringResource(R.string.enable_reminder), style = MaterialTheme.typography.titleSmall,
                 fontWeight = FontWeight.SemiBold, color = Color.White)
        }
    }
    TextButton(onClick = onSkip) { Text(stringResource(R.string.not_now), color = Color.White.copy(alpha = 0.8f)) }
}

@Composable
private fun Translations(showEnglish: Boolean, onChange: (Boolean) -> Unit) {
    Box(Modifier.size(110.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.08f)), contentAlignment = Alignment.Center) {
        Icon(Icons.Filled.Translate, null, Modifier.size(56.dp), tint = Brand.gold)
    }
    Title(stringResource(R.string.translations))
    Body(stringResource(R.string.translations_question))
    Choice(Icons.Filled.TextFields, stringResource(R.string.german_only), !showEnglish) { onChange(false) }
    Choice(Icons.Filled.Translate, stringResource(R.string.german_english), showEnglish) { onChange(true) }
}

@Composable
private fun Choice(icon: ImageVector, label: String, active: Boolean, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp))
            .background(if (active) Brand.gold else Color.White.copy(alpha = 0.1f))
            .selectable(active, role = Role.RadioButton, onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = if (active) Brand.navy else Color.White)
        Spacer(Modifier.width(12.dp))
        Text(label, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold,
             color = if (active) Brand.navy else Color.White)
    }
}
