package ai.biniam.sbfexamprep.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material.icons.filled.Sailing
import androidx.compose.material.icons.filled.Stars
import androidx.compose.material.icons.filled.Waves
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.ExamFormat
import ai.biniam.sbfexamprep.data.ExamRules
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.data.LicenceGoal
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf

/** White status-bar icons while a navy screen is shown; restores the theme default afterwards. */
@Composable
fun LightStatusBarIcons() {
    val view = androidx.compose.ui.platform.LocalView.current
    if (view.isInEditMode) return
    val dark = androidx.compose.foundation.isSystemInDarkTheme()
    androidx.compose.runtime.DisposableEffect(dark) {
        val window = (view.context as? android.app.Activity)?.window
        val controller = window?.let { androidx.core.view.WindowCompat.getInsetsController(it, view) }
        controller?.isAppearanceLightStatusBars = false
        onDispose { controller?.isAppearanceLightStatusBars = !dark }
    }
}

object Layout {
    /** Comfortable reading width for question content on tablets / landscape. */
    val readableWidth = 760.dp
    /** Width for dashboards (home, setup) on large screens. */
    val wideWidth = 1000.dp
    /** Window width from which tablets get two-pane layouts. */
    val twoPaneWidth = 840.dp
}

/** True when the app runs with its German resources. */
@Composable
fun isGerman(): Boolean = stringResource(R.string.content_language) == "de"

/** Centres its content and limits it to [maxWidth] on large screens. */
@Composable
fun ReadableWidth(maxWidth: Dp = Layout.readableWidth, modifier: Modifier = Modifier, content: @Composable BoxScope.() -> Unit) {
    Box(modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        Box(Modifier.widthIn(max = maxWidth).fillMaxWidth(), content = content)
    }
}

@Composable
fun Modifier.cardStyle(radius: Dp = 16.dp): Modifier = this
    .clip(RoundedCornerShape(radius))
    .background(Sbf.colors.card)
    .border(1.dp, Sbf.colors.hairline.copy(alpha = 0.6f), RoundedCornerShape(radius))

@Composable
fun examTypeTitle(type: ExamType): String = stringResource(
    when (type) {
        ExamType.ALL -> R.string.exam_all
        ExamType.SHARED -> R.string.exam_basic
        ExamType.BINNEN -> R.string.exam_inland
        ExamType.SEGELN -> R.string.exam_sailing
        ExamType.SEE -> R.string.exam_sea
    }
)

@Composable
fun licenceName(type: ExamType): String = stringResource(
    when (type) {
        ExamType.ALL -> R.string.licence_all
        ExamType.SHARED -> R.string.licence_basic
        ExamType.BINNEN -> R.string.licence_inland
        ExamType.SEGELN -> R.string.licence_sailing
        ExamType.SEE -> R.string.licence_sea
    }
)

/** Short noun for an exam part, e.g. "7 basic + 23 inland". */
@Composable
fun partNoun(type: ExamType): String = stringResource(
    when (type) {
        ExamType.ALL -> R.string.part_questions
        ExamType.SHARED -> R.string.part_basic
        ExamType.BINNEN -> R.string.part_inland
        ExamType.SEGELN -> R.string.part_sailing
        ExamType.SEE -> R.string.part_sea
    }
)

/** Heading of an exam part in the result. */
@Composable
fun partTitle(type: ExamType): String = stringResource(
    when (type) {
        ExamType.ALL, ExamType.SHARED -> R.string.licence_basic
        ExamType.BINNEN -> R.string.part_title_inland
        ExamType.SEGELN -> R.string.part_title_sailing
        ExamType.SEE -> R.string.part_title_sea
    }
)

@Composable
fun examFormatTitle(format: ExamFormat): String = stringResource(
    when (format) {
        ExamFormat.BINNEN_MOTOR -> R.string.format_binnen_motor
        ExamFormat.BINNEN_SAIL -> R.string.format_binnen_sail
        ExamFormat.BINNEN_MOTOR_SAIL -> R.string.format_binnen_motor_sail
        ExamFormat.SAIL_ADDON -> R.string.format_sail_addon
        ExamFormat.SEE -> R.string.exam_sea
    }
)

/** For tight spaces such as the result stat card. */
@Composable
fun examFormatShortTitle(format: ExamFormat): String = stringResource(
    when (format) {
        ExamFormat.BINNEN_MOTOR -> R.string.licence_motor
        ExamFormat.BINNEN_SAIL -> R.string.licence_sail
        ExamFormat.BINNEN_MOTOR_SAIL -> R.string.licence_motor_sail
        ExamFormat.SAIL_ADDON -> R.string.format_sail_addon
        ExamFormat.SEE -> R.string.exam_sea
    }
)

fun examFormatIcon(format: ExamFormat): ImageVector = when (format) {
    ExamFormat.BINNEN_MOTOR -> Icons.Filled.Waves
    ExamFormat.BINNEN_SAIL, ExamFormat.BINNEN_MOTOR_SAIL, ExamFormat.SAIL_ADDON -> Icons.Filled.Sailing
    ExamFormat.SEE -> Icons.Filled.Air
}

/** "7 basic + 23 inland · 45 min" */
@Composable
fun examSummary(rules: ExamRules): String {
    val composition = rules.parts.map { "${it.count} ${partNoun(it.type)}" }.joinToString(" + ")
    return stringResource(R.string.exam_summary, composition, rules.minutes)
}

/** "Pass: at least 5 of 7 basic and 18 of 23 inland" or the total for the sailing licence alone. */
@Composable
fun examPassText(rules: ExamRules): String {
    rules.totalPassMark?.let { return stringResource(R.string.rules_pass_total, it, rules.totalCount) }
    val parts = rules.parts.mapNotNull { part ->
        part.passMark?.let { stringResource(R.string.part_pass, it, part.count, partNoun(part.type)) }
    }
    val joined = if (parts.size > 1) {
        stringResource(R.string.list_and, parts.dropLast(1).joinToString(", "), parts.last())
    } else parts.firstOrNull().orEmpty()
    return stringResource(R.string.rules_pass_parts, joined)
}

@Composable
fun licenceInlandTitle(inland: LicenceGoal.Inland): String = stringResource(
    when (inland) {
        LicenceGoal.Inland.NONE -> R.string.licence_none
        LicenceGoal.Inland.MOTOR -> R.string.licence_motor
        LicenceGoal.Inland.SAIL -> R.string.licence_sail
        LicenceGoal.Inland.MOTOR_AND_SAIL -> R.string.licence_motor_sail
        LicenceGoal.Inland.SAIL_ADDON -> R.string.licence_sail_addon
    }
)

/** "Inland · motor + sail · Sea" */
@Composable
fun licenceSummary(goal: LicenceGoal): String =
    (listOfNotNull(goal.inland.format?.let { examFormatTitle(it) }) +
        if (goal.sea) listOf(examFormatTitle(ExamFormat.SEE)) else emptyList()).joinToString(" · ")

fun examTypeIcon(type: ExamType): ImageVector = when (type) {
    ExamType.ALL -> Icons.Filled.Layers
    ExamType.SHARED -> Icons.Filled.Stars
    ExamType.BINNEN -> Icons.Filled.Waves
    ExamType.SEGELN -> Icons.Filled.Sailing
    ExamType.SEE -> Icons.Filled.Air
}

fun examTypeColor(type: ExamType): Color = when (type) {
    ExamType.ALL -> Brand.navyLight
    ExamType.SHARED -> Brand.gold
    ExamType.BINNEN -> Brand.oceanTeal
    ExamType.SEGELN -> Color(0xFFA84533)
    ExamType.SEE -> Brand.navyLight
}

/** Exam-type colour for text: gold is too light for small text on white. */
@Composable
fun examTypeTextColor(type: ExamType): Color =
    if (type == ExamType.SHARED && !androidx.compose.foundation.isSystemInDarkTheme()) Color(0xFF8A6D1A) else examTypeColor(type)

@Composable
fun ExamTypeBadge(type: ExamType) {
    val color = examTypeColor(type)
    Row(
        Modifier.clip(CircleShape).background(color.copy(alpha = 0.15f)).padding(horizontal = 10.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(examTypeIcon(type), null, Modifier.size(14.dp), tint = color)
        Text(examTypeTitle(type), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
             color = examTypeTextColor(type))
    }
}

@Composable
fun CategoryBadge(text: String) {
    Text(
        text,
        Modifier.clip(CircleShape).background(Brand.navyLight.copy(alpha = 0.10f)).padding(horizontal = 10.dp, vertical = 4.dp),
        style = MaterialTheme.typography.labelMedium,
        color = Sbf.colors.inkSecondary,
        maxLines = 2,
        overflow = TextOverflow.Ellipsis,
    )
}

@Composable
fun SectionHeader(title: String, icon: ImageVector? = null, modifier: Modifier = Modifier) {
    Row(modifier.semantics { heading() }, verticalAlignment = Alignment.CenterVertically) {
        if (icon != null) {
            Icon(icon, null, Modifier.size(18.dp), tint = Brand.gold)
            Spacer(Modifier.width(6.dp))
        }
        Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = Sbf.colors.ink)
    }
}

@Composable
fun StatCard(value: String, label: String, icon: ImageVector, color: Color, modifier: Modifier = Modifier) {
    Column(
        modifier.cardStyle().padding(vertical = 14.dp, horizontal = 8.dp)
            .clearAndSetSemantics { contentDescription = "$label: $value" },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(icon, null, tint = color)
        Text(value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = Sbf.colors.ink,
             maxLines = 1, overflow = TextOverflow.Ellipsis)
        Text(label, style = MaterialTheme.typography.labelSmall, color = Sbf.colors.muted, maxLines = 1,
             overflow = TextOverflow.Ellipsis)
    }
}

/** Filled navy button used for the main action of a screen. */
@Composable
fun PrimaryButton(text: String, icon: ImageVector?, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true) {
    androidx.compose.material3.Surface(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        color = Color.Transparent,
    ) {
        Row(
            Modifier.background(if (enabled) Brand.navyGradient else androidx.compose.ui.graphics.SolidColor(Color.Gray))
                .padding(vertical = 14.dp, horizontal = 16.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (icon != null) {
                Icon(icon, null, tint = Color.White, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(8.dp))
            }
            Text(text, color = Color.White, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        }
    }
}

/** Light secondary button. */
@Composable
fun SecondaryButton(text: String, icon: ImageVector?, onClick: () -> Unit, modifier: Modifier = Modifier) {
    androidx.compose.material3.Surface(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        color = Brand.navyLight.copy(alpha = 0.12f),
    ) {
        Row(
            Modifier.padding(vertical = 14.dp, horizontal = 16.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (icon != null) {
                Icon(icon, null, tint = Sbf.colors.ink, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(8.dp))
            }
            Text(text, color = Sbf.colors.ink, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
        }
    }
}

/** Small pill with a number, e.g. the count of due questions. */
@Composable
fun CountPill(count: Int, color: Color = Brand.gold, textColor: Color = Brand.navy) {
    Text(
        "$count",
        Modifier.clip(CircleShape).background(color).padding(horizontal = 8.dp, vertical = 2.dp),
        style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = textColor,
    )
}
