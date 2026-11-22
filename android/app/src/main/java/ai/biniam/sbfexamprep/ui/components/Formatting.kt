package ai.biniam.sbfexamprep.ui.components

import android.icu.text.RelativeDateTimeFormatter
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.platform.LocalConfiguration
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.roundToInt

@Composable
@ReadOnlyComposable
fun currentLocale(): Locale = LocalConfiguration.current.locales[0]

fun percent(value: Double, locale: Locale): String =
    NumberFormat.getPercentInstance(locale).apply { maximumFractionDigits = 0 }.format(value)

/** "5 minutes ago", "vor 2 Tagen" … */
fun relativeTime(epochMillis: Long, now: Long, locale: Locale): String {
    val f = RelativeDateTimeFormatter.getInstance(locale)
    val minutes = ((now - epochMillis) / 60_000.0).coerceAtLeast(0.0)
    return when {
        minutes < 1 -> f.format(RelativeDateTimeFormatter.Direction.PLAIN, RelativeDateTimeFormatter.AbsoluteUnit.NOW)
        minutes < 60 -> f.format(minutes.roundToInt().toDouble(), RelativeDateTimeFormatter.Direction.LAST,
                                 RelativeDateTimeFormatter.RelativeUnit.MINUTES)
        minutes < 60 * 24 -> f.format((minutes / 60).roundToInt().toDouble(), RelativeDateTimeFormatter.Direction.LAST,
                                      RelativeDateTimeFormatter.RelativeUnit.HOURS)
        else -> f.format((minutes / 1440).roundToInt().toDouble(), RelativeDateTimeFormatter.Direction.LAST,
                         RelativeDateTimeFormatter.RelativeUnit.DAYS)
    }
}
