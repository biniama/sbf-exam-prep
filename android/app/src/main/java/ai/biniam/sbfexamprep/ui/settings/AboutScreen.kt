package ai.biniam.sbfexamprep.ui.settings

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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.Checklist
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.automirrored.filled.LibraryBooks
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.PanTool
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Sailing
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import ai.biniam.sbfexamprep.BuildConfig
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.ui.AppLinks
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.ReadableWidth
import ai.biniam.sbfexamprep.ui.components.cardStyle
import ai.biniam.sbfexamprep.ui.components.isGerman
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AboutScreen(onBack: () -> Unit) {
    val app = LocalApp.current
    val uri = LocalUriHandler.current
    val german = isGerman()
    val store = app.questions
    Scaffold(
        containerColor = Sbf.colors.surface,
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.about)) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, stringResource(R.string.back)) }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Sbf.colors.surface),
            )
        },
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState())) {
            ReadableWidth {
                Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally,
                           verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Box(Modifier.size(84.dp).clip(RoundedCornerShape(20.dp)).background(Brand.navyGradient),
                            contentAlignment = Alignment.Center) {
                            Icon(Icons.Filled.Sailing, null, Modifier.size(48.dp), tint = Brand.gold)
                        }
                        Text(stringResource(R.string.app_name), style = MaterialTheme.typography.headlineSmall,
                             fontWeight = FontWeight.Bold, color = Sbf.colors.ink)
                        Text(stringResource(R.string.version, "${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})"),
                             style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted)
                    }
                    Card(Icons.AutoMirrored.Filled.MenuBook, Brand.navyLight, stringResource(R.string.about_this_app)) {
                        Body(stringResource(R.string.about_text_1))
                        Body(stringResource(R.string.about_text_2))
                    }
                    Card(Icons.AutoMirrored.Filled.LibraryBooks, Brand.oceanTeal, stringResource(R.string.question_catalogue)) {
                        CountRow(stringResource(R.string.licence_basic), store.specificQuestions(ExamType.SHARED).size)
                        CountRow(stringResource(R.string.sbf_inland_specific), store.specificQuestions(ExamType.BINNEN).size)
                        CountRow(stringResource(R.string.licence_sailing), store.specificQuestions(ExamType.SEGELN).size)
                        CountRow(stringResource(R.string.sbf_sea_specific), store.specificQuestions(ExamType.SEE).size)
                        CountRow(stringResource(R.string.illustrated_questions), store.allQuestions.count { it.hasImage })
                        HorizontalDivider(color = Sbf.colors.hairline)
                        CountRow(stringResource(R.string.total), store.allQuestions.size, bold = true)
                    }
                    Card(Icons.Filled.Star, Brand.gold, stringResource(R.string.features)) {
                        Feature(Icons.Filled.Checklist, stringResource(R.string.feature_practice))
                        Feature(Icons.Filled.Timer, stringResource(R.string.feature_exam))
                        Feature(Icons.Filled.Replay, stringResource(R.string.feature_spaced))
                        Feature(Icons.AutoMirrored.Filled.VolumeUp, stringResource(R.string.feature_sounds))
                    }
                    Card(Icons.Filled.Description, Brand.navyLight, stringResource(R.string.sources_legal)) {
                        Body(stringResource(R.string.sources_1))
                        Body(stringResource(R.string.sources_2))
                        Body(stringResource(R.string.sources_3))
                        Link(Icons.AutoMirrored.Filled.OpenInNew, stringResource(R.string.elwis_info)) { uri.openUri(AppLinks.ELWIS) }
                        Link(Icons.Filled.PanTool, stringResource(R.string.privacy_policy)) { uri.openUri(AppLinks.privacy(german)) }
                        Text(stringResource(R.string.copyright), style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted)
                    }
                }
            }
        }
    }
}

@Composable
private fun Card(icon: ImageVector, color: Color, title: String, content: @Composable () -> Unit) {
    Column(Modifier.cardStyle().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(32.dp).clip(RoundedCornerShape(8.dp)).background(color), contentAlignment = Alignment.Center) {
                Icon(icon, null, Modifier.size(18.dp), tint = Color.White)
            }
            Spacer(Modifier.width(10.dp))
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = Sbf.colors.ink)
        }
        content()
    }
}

@Composable
private fun Body(text: String) = Text(text, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink)

@Composable
private fun CountRow(label: String, count: Int, bold: Boolean = false) {
    Row {
        Text(label, Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink,
             fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal)
        Text("$count", style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink,
             fontWeight = if (bold) FontWeight.Bold else FontWeight.SemiBold)
    }
}

@Composable
private fun Feature(icon: ImageVector, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, Modifier.size(20.dp), tint = Brand.gold)
        Spacer(Modifier.width(10.dp))
        Body(text)
    }
}

@Composable
private fun Link(icon: ImageVector, text: String, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, Modifier.size(18.dp), tint = Brand.navyLight)
        Spacer(Modifier.width(8.dp))
        Text(text, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = Brand.navyLight)
    }
}
