package ai.biniam.sbfexamprep.ui.navigation

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.OndemandVideo
import androidx.compose.material.icons.filled.SmartDisplay
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.NavigationTechnique
import ai.biniam.sbfexamprep.data.NavigationVideo
import ai.biniam.sbfexamprep.ui.components.SectionHeader
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.components.isGerman
import ai.biniam.sbfexamprep.ui.theme.Sbf

/** A video row that opens the video in YouTube (feature flag NAVIGATION_VIDEOS). */
@Composable
fun NavigationVideoRow(video: NavigationVideo, start: Int? = null) {
    val uriHandler = LocalUriHandler.current
    Row(Modifier.fillMaxWidth().cardStyle().clickable { uriHandler.openUri(video.url(start)) }.padding(14.dp),
        verticalAlignment = Alignment.Top) {
        Icon(Icons.Filled.SmartDisplay, null, Modifier.size(28.dp), tint = Sbf.colors.error)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(video.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold,
                 color = Sbf.colors.ink, maxLines = 3, overflow = TextOverflow.Ellipsis)
            Text(videoMeta(video), style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted, maxLines = 1,
                 overflow = TextOverflow.Ellipsis)
        }
        Icon(Icons.AutoMirrored.Filled.OpenInNew, null, Modifier.size(16.dp), tint = Sbf.colors.muted)
    }
}

/** "Channel · 13 min · German" */
@Composable
private fun videoMeta(video: NavigationVideo): String = listOfNotNull(
    video.channel,
    stringResource(R.string.videos_minutes, video.minutes),
    video.lang?.let { stringResource(if (it == "de") R.string.videos_german else R.string.videos_english) },
).joinToString(" · ")

/** Technique videos, all of them or one technique (opened from a sub-question). */
@Composable
fun NavigationVideosScreen(techniques: List<NavigationTechnique>, onBack: () -> Unit) {
    val german = isGerman()
    val title = techniques.singleOrNull()?.title(german) ?: stringResource(R.string.videos_title)
    NavScaffold(title, onBack) {
        techniques.forEach { technique ->
            if (techniques.size > 1) SectionHeader(technique.title(german), Icons.Filled.OndemandVideo)
            technique.videos.forEach { NavigationVideoRow(it) }
        }
        NavigationVideosDisclaimer()
    }
}

@Composable
fun NavigationVideosDisclaimer() {
    Text(stringResource(R.string.videos_disclaimer), style = MaterialTheme.typography.labelSmall, color = Sbf.colors.muted)
}
