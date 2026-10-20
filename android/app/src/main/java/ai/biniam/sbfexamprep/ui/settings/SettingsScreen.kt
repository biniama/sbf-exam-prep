package ai.biniam.sbfexamprep.ui.settings

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.Backup
import androidx.compose.material.icons.filled.DeleteForever
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.PanTool
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.app.NotificationManagerCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.repeatOnLifecycle
import ai.biniam.sbfexamprep.BuildConfig
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.reminders.ReminderScheduler
import ai.biniam.sbfexamprep.ui.AppLinks
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.ReadableWidth
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.components.currentLocale
import ai.biniam.sbfexamprep.ui.components.isGerman
import ai.biniam.sbfexamprep.ui.components.percent
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen() {
    var showAbout by rememberSaveable { mutableStateOf(false) }
    if (showAbout) {
        BackHandler { showAbout = false }
        AboutScreen(onBack = { showAbout = false })
        return
    }

    val app = LocalApp.current
    val context = LocalContext.current
    val uri = LocalUriHandler.current
    val progress by app.progressRepository.progress.collectAsStateWithLifecycle()
    val settings by app.progressRepository.settings.collectAsStateWithLifecycle()
    val german = isGerman()
    var confirmReset by rememberSaveable { mutableStateOf(false) }
    var pickTime by rememberSaveable { mutableStateOf(false) }
    var notificationsDenied by rememberSaveable { mutableStateOf(false) }

    fun setReminder(enabled: Boolean, minutes: Int = settings.reminderMinutes) {
        app.progressRepository.updateSettings { it.copy(reminderEnabled = enabled, reminderMinutes = minutes) }
        if (enabled) ReminderScheduler.schedule(context, minutes) else ReminderScheduler.cancel(context)
    }

    val permission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        notificationsDenied = !granted
        setReminder(granted)
    }

    // Re-check when returning from the system settings.
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    LaunchedEffect(lifecycle) {
        lifecycle.repeatOnLifecycle(Lifecycle.State.RESUMED) {
            val enabled = NotificationManagerCompat.from(context).areNotificationsEnabled()
            notificationsDenied = !enabled && (settings.reminderEnabled || notificationsDenied)
            if (!enabled && app.progressRepository.settings.value.reminderEnabled) setReminder(false)
        }
    }

    Scaffold(
        containerColor = Sbf.colors.surface,
        topBar = {
            TopAppBar(title = { Text(stringResource(R.string.tab_settings)) },
                      colors = TopAppBarDefaults.topAppBarColors(containerColor = Sbf.colors.surface))
        },
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState())) {
            ReadableWidth {
                Column(Modifier.padding(start = 16.dp, end = 16.dp, bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
                    Section(stringResource(R.string.learning), stringResource(R.string.learning_footer)) {
                        SwitchRow(Icons.Filled.Translate, stringResource(R.string.show_english), settings.showEnglish) { on ->
                            app.progressRepository.updateSettings { it.copy(showEnglish = on) }
                        }
                        Divider()
                        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            Label(Icons.Filled.Schedule, stringResource(R.string.default_quiz_length))
                            val counts = listOf(10, 20, 30, 50)
                            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                                counts.forEachIndexed { i, n ->
                                    SegmentedButton(settings.quizCount == n,
                                                    { app.progressRepository.updateSettings { it.copy(quizCount = n) } },
                                                    SegmentedButtonDefaults.itemShape(i, counts.size)) { Text("$n") }
                                }
                            }
                        }
                        Divider()
                        val language = currentLocale().let { it.getDisplayLanguage(it).replaceFirstChar(Char::titlecase) }
                        LinkRow(Icons.Filled.Language, stringResource(R.string.app_language), language) {
                            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                Intent(Settings.ACTION_APP_LOCALE_SETTINGS, Uri.fromParts("package", context.packageName, null))
                            } else {
                                Intent(Settings.ACTION_LOCALE_SETTINGS)
                            }
                            context.startActivity(intent)
                        }
                    }

                    Section(stringResource(R.string.reminders), stringResource(R.string.reminders_footer)) {
                        SwitchRow(Icons.Filled.NotificationsActive, stringResource(R.string.daily_reminder), settings.reminderEnabled) { on ->
                            when {
                                !on -> setReminder(false)
                                Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU ->
                                    permission.launch(Manifest.permission.POST_NOTIFICATIONS)
                                NotificationManagerCompat.from(context).areNotificationsEnabled() -> setReminder(true)
                                else -> notificationsDenied = true
                            }
                        }
                        if (settings.reminderEnabled) {
                            Divider()
                            val time = LocalTime.of(settings.reminderMinutes / 60, settings.reminderMinutes % 60)
                            LinkRow(Icons.Filled.Schedule, stringResource(R.string.time),
                                    time.format(DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT).withLocale(currentLocale()))) {
                                pickTime = true
                            }
                        }
                        if (notificationsDenied) {
                            Divider()
                            LinkRow(Icons.AutoMirrored.Filled.OpenInNew, stringResource(R.string.allow_notifications), null) {
                                context.startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName))
                            }
                        }
                    }

                    Section(stringResource(R.string.backup), stringResource(R.string.backup_footer)) {
                        Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                            Label(Icons.Filled.Backup, stringResource(R.string.backup_local), Modifier.weight(1f))
                        }
                    }

                    val now = System.currentTimeMillis()
                    Section(stringResource(R.string.statistics)) {
                        StatRow(stringResource(R.string.questions_answered), "${progress.totalAnswered}")
                        StatRow(stringResource(R.string.overall_accuracy), percent(progress.overallAccuracy, currentLocale()))
                        StatRow(stringResource(R.string.mastered), "${progress.masteredCount}")
                        StatRow(stringResource(R.string.due_for_review), "${progress.dueCount(now)}")
                        StatRow(stringResource(R.string.mistakes_to_review), "${progress.wrongAnswerCount}")
                        StatRow(stringResource(R.string.saved_questions), "${progress.bookmarks.size}")
                        StatRow(stringResource(R.string.quizzes_completed), "${progress.quizHistory.size}", last = true)
                    }

                    Section(stringResource(R.string.question_catalogue), stringResource(R.string.catalogue_footer)) {
                        StatRow(stringResource(R.string.licence_basic), "${app.questions.specificQuestions(ExamType.SHARED).size}")
                        StatRow(stringResource(R.string.sbf_inland_specific), "${app.questions.specificQuestions(ExamType.BINNEN).size}")
                        StatRow(stringResource(R.string.sbf_sea_specific), "${app.questions.specificQuestions(ExamType.SEE).size}")
                        StatRow(stringResource(R.string.total), "${app.questions.allQuestions.size}", last = true)
                    }

                    Section(stringResource(R.string.about), stringResource(R.string.version, versionName())) {
                        LinkRow(Icons.Filled.Info, stringResource(R.string.about_app), null) { showAbout = true }
                        Divider()
                        LinkRow(Icons.AutoMirrored.Filled.HelpOutline, stringResource(R.string.help_feedback), null, external = true) {
                            uri.openUri(AppLinks.support(german))
                        }
                        Divider()
                        LinkRow(Icons.Filled.PanTool, stringResource(R.string.privacy_policy), null, external = true) {
                            uri.openUri(AppLinks.privacy(german))
                        }
                        Divider()
                        LinkRow(Icons.Filled.Star, stringResource(R.string.rate_app), null, external = true) {
                            runCatching { uri.openUri(AppLinks.playStore(context.packageName)) }
                                .onFailure { uri.openUri(AppLinks.playStoreWeb(context.packageName)) }
                        }
                    }

                    Section(stringResource(R.string.data)) {
                        Row(Modifier.fillMaxWidth().clickable { confirmReset = true }.padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.DeleteForever, null, tint = Sbf.colors.error)
                            Spacer(Modifier.width(12.dp))
                            Text(stringResource(R.string.reset_all), color = Sbf.colors.error, style = MaterialTheme.typography.bodyLarge)
                        }
                    }
                }
            }
        }
    }

    if (confirmReset) {
        AlertDialog(
            onDismissRequest = { confirmReset = false },
            title = { Text(stringResource(R.string.reset_title)) },
            text = { Text(stringResource(R.string.reset_message)) },
            confirmButton = {
                TextButton(onClick = { app.progressRepository.resetProgress(); confirmReset = false }) {
                    Text(stringResource(R.string.reset), color = Sbf.colors.error)
                }
            },
            dismissButton = { TextButton(onClick = { confirmReset = false }) { Text(stringResource(R.string.cancel)) } },
        )
    }

    if (pickTime) {
        val state = rememberTimePickerState(settings.reminderMinutes / 60, settings.reminderMinutes % 60,
                                            android.text.format.DateFormat.is24HourFormat(context))
        AlertDialog(
            onDismissRequest = { pickTime = false },
            title = { Text(stringResource(R.string.time)) },
            text = { TimePicker(state) },
            confirmButton = {
                TextButton(onClick = { setReminder(true, state.hour * 60 + state.minute); pickTime = false }) {
                    Text(stringResource(R.string.done))
                }
            },
            dismissButton = { TextButton(onClick = { pickTime = false }) { Text(stringResource(R.string.cancel)) } },
        )
    }
}

private fun versionName() = "${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})"

@Composable
private fun Section(title: String, footer: String? = null, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(title.uppercase(currentLocale()), style = MaterialTheme.typography.labelMedium, color = Sbf.colors.muted,
             modifier = Modifier.padding(start = 14.dp).semantics { heading() })
        Column(Modifier.cardStyle(14.dp)) { content() }
        if (footer != null) {
            Text(footer, style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted, modifier = Modifier.padding(horizontal = 14.dp))
        }
    }
}

@Composable
private fun Divider() = HorizontalDivider(Modifier.padding(start = 50.dp), color = Sbf.colors.hairline)

@Composable
private fun Label(icon: ImageVector, text: String, modifier: Modifier = Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, Modifier.size(22.dp), tint = Brand.navyLight)
        Spacer(Modifier.width(14.dp))
        Text(text, style = MaterialTheme.typography.bodyLarge, color = Sbf.colors.ink)
    }
}

@Composable
private fun SwitchRow(icon: ImageVector, text: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        Modifier.fillMaxWidth().toggleable(checked, role = Role.Switch, onValueChange = onChange).padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Label(icon, text, Modifier.weight(1f))
        Switch(checked, onCheckedChange = null)
    }
}

@Composable
private fun LinkRow(icon: ImageVector, text: String, value: String?, external: Boolean = false, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
        Label(icon, text, Modifier.weight(1f))
        if (value != null) Text(value, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.inkSecondary)
        Spacer(Modifier.width(6.dp))
        Icon(if (external) Icons.AutoMirrored.Filled.OpenInNew else Icons.AutoMirrored.Filled.KeyboardArrowRight, null,
             Modifier.size(18.dp), tint = Sbf.colors.muted)
    }
}

@Composable
private fun StatRow(label: String, value: String, last: Boolean = false) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge, color = Sbf.colors.ink)
        Text(value, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium, color = Sbf.colors.inkSecondary)
    }
    if (!last) HorizontalDivider(Modifier.padding(start = 14.dp), color = Sbf.colors.hairline.copy(alpha = 0.7f))
}

