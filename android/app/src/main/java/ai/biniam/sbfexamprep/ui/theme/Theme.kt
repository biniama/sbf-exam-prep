package ai.biniam.sbfexamprep.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

/** Brand colours — used for filled surfaces (headers, primary buttons, badges). */
object Brand {
    val navy = Color(0xFF0A2442)
    val navyMid = Color(0xFF1A3B5E)
    val navyLight = Color(0xFF295989)
    val gold = Color(0xFFC9A84D)
    val goldLight = Color(0xFFF2D98C)
    val oceanTeal = Color(0xFF1A99A8)

    val navyGradient = Brush.linearGradient(listOf(navyMid, navy))
    val goldGradient = Brush.linearGradient(listOf(goldLight, gold))
}

/** Colours that adapt to light and dark mode. */
@Immutable
data class SbfColors(
    val ink: Color,
    val inkSecondary: Color,
    val success: Color,
    val error: Color,
    val card: Color,
    val surface: Color,
    val hairline: Color,
    val muted: Color,
)

private val Light = SbfColors(
    ink = Color(0xFF0A2442), inkSecondary = Color(0xFF1A3B5E),
    success = Color(0xFF2E7D33), error = Color(0xFFC42929),
    card = Color.White, surface = Color(0xFFF2F4F8), hairline = Color(0xFFD5DAE2), muted = Color(0xFF6B7380),
)

private val Dark = SbfColors(
    ink = Color(0xFFEDF2FA), inkSecondary = Color(0xFFB3C7E0),
    success = Color(0xFF5CC76B), error = Color(0xFFF56666),
    card = Color(0xFF182230), surface = Color(0xFF0E1621), hairline = Color(0xFF2B3747), muted = Color(0xFF94A0B0),
)

val LocalSbfColors = staticCompositionLocalOf { Light }

private val LightScheme = lightColorScheme(
    primary = Brand.navy, onPrimary = Color.White,
    primaryContainer = Color(0xFFD6E3F3), onPrimaryContainer = Brand.navy,
    secondary = Brand.gold, onSecondary = Brand.navy,
    secondaryContainer = Color(0xFFF6EBC8), onSecondaryContainer = Brand.navy,
    tertiary = Brand.oceanTeal,
    background = Light.surface, onBackground = Light.ink,
    surface = Light.surface, onSurface = Light.ink, onSurfaceVariant = Light.muted,
    surfaceContainer = Color.White, surfaceContainerLow = Color.White, surfaceContainerHigh = Color.White,
    surfaceContainerLowest = Color.White, surfaceContainerHighest = Color(0xFFE6EAF0),
    outline = Color(0xFFB7C0CC), outlineVariant = Light.hairline,
    error = Light.error,
)

private val DarkScheme = darkColorScheme(
    primary = Color(0xFF9CC1F0), onPrimary = Brand.navy,
    primaryContainer = Brand.navyLight, onPrimaryContainer = Color.White,
    secondary = Brand.gold, onSecondary = Brand.navy,
    secondaryContainer = Color(0xFF4A3F1C), onSecondaryContainer = Brand.goldLight,
    tertiary = Brand.oceanTeal,
    background = Dark.surface, onBackground = Dark.ink,
    surface = Dark.surface, onSurface = Dark.ink, onSurfaceVariant = Dark.muted,
    surfaceContainer = Dark.card, surfaceContainerLow = Dark.card, surfaceContainerHigh = Color(0xFF1F2B3B),
    surfaceContainerLowest = Dark.surface, surfaceContainerHighest = Color(0xFF263345),
    outline = Color(0xFF4A5868), outlineVariant = Dark.hairline,
    error = Dark.error,
)

@Composable
fun SbfTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalSbfColors provides if (darkTheme) Dark else Light) {
        MaterialTheme(colorScheme = if (darkTheme) DarkScheme else LightScheme, content = content)
    }
}

/** Shortcut for the adaptive colours: `Sbf.colors.ink`. */
object Sbf {
    val colors: SbfColors
        @Composable get() = LocalSbfColors.current
}
