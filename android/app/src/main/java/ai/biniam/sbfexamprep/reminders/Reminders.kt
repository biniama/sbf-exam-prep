package ai.biniam.sbfexamprep.reminders

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import ai.biniam.sbfexamprep.MainActivity
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.SbfApplication
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime

/** Daily study reminder: a local notification, nothing leaves the device. */
object ReminderScheduler {
    private const val CHANNEL_ID = "study_reminders"
    private const val NOTIFICATION_ID = 1

    /** Next occurrence of [minutes] after midnight, strictly after [now]. */
    fun nextTrigger(minutes: Int, now: ZonedDateTime = ZonedDateTime.now()): ZonedDateTime {
        val today = ZonedDateTime.of(now.toLocalDate(), LocalTime.of(minutes / 60, minutes % 60), now.zone)
        return if (today.isAfter(now)) today else today.plusDays(1)
    }

    fun schedule(context: Context, minutes: Int) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val at = nextTrigger(minutes).toInstant().toEpochMilli()
        // A 10-minute window keeps the alarm battery friendly without needing exact-alarm permission.
        alarms.setWindow(AlarmManager.RTC_WAKEUP, at, 10 * 60 * 1000L, pendingIntent(context))
    }

    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java)?.cancel(pendingIntent(context))
    }

    private fun pendingIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context, 0, Intent(context, ReminderReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    fun showNotification(context: Context) {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, context.getString(R.string.reminder_channel), NotificationManager.IMPORTANCE_DEFAULT)
        )
        val open = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(context.getString(R.string.reminder_title))
            .setContentText(context.getString(R.string.reminder_body))
            .setStyle(NotificationCompat.BigTextStyle().bigText(context.getString(R.string.reminder_body)))
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        try {
            manager.notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // Permission was revoked between the check and the call.
        }
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext as SbfApplication
        val settings = app.progressRepository.settings.value
        if (!settings.reminderEnabled) return
        val today = LocalDate.now(ZoneId.systemDefault())
        // Skip the reminder when the learner already studied today.
        if (!app.progressRepository.progress.value.studied(today)) ReminderScheduler.showNotification(context)
        ReminderScheduler.schedule(context, settings.reminderMinutes)
    }
}

private val RESCHEDULE_ACTIONS = setOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED)

/** Alarms are cleared on reboot and must follow clock changes. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in RESCHEDULE_ACTIONS) return
        val settings = (context.applicationContext as SbfApplication).progressRepository.settings.value
        if (settings.reminderEnabled) ReminderScheduler.schedule(context, settings.reminderMinutes)
    }
}
