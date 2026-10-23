package ai.biniam.sbfexamprep.ui.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.data.LicenceGoal
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.licenceInlandTitle
import ai.biniam.sbfexamprep.ui.theme.Sbf

/** "My licence": which licences the learner is preparing for. Opened from Settings and the Home prompt. */
@Composable
fun LicenceDialog(onDismiss: () -> Unit) {
    val app = LocalApp.current
    val settings by app.progressRepository.settings.collectAsStateWithLifecycle()
    val goal = settings.licenceGoal

    fun save(newGoal: LicenceGoal) {
        if (newGoal.isValid) app.progressRepository.updateSettings { it.copy(licenceGoal = newGoal, hasChosenLicence = true) }
    }

    fun close() {
        save(goal)
        onDismiss()
    }

    AlertDialog(
        onDismissRequest = ::close,
        confirmButton = { TextButton(onClick = ::close) { Text(stringResource(R.string.done), fontWeight = FontWeight.SemiBold) } },
        title = { Text(stringResource(R.string.my_licence)) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(stringResource(R.string.sbf_inland), style = MaterialTheme.typography.labelLarge, color = Sbf.colors.muted)
                LicenceGoal.Inland.entries.forEach { option ->
                    Row(
                        Modifier.fillMaxWidth()
                            .selectable(goal.inland == option, role = Role.RadioButton) {
                                save(goal.copy(inland = option, sea = if (option == LicenceGoal.Inland.NONE) true else goal.sea))
                            }
                            .padding(vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(goal.inland == option, onClick = null)
                        Spacer(Modifier.width(10.dp))
                        Text(licenceInlandTitle(option), style = MaterialTheme.typography.bodyLarge, color = Sbf.colors.ink)
                    }
                }
                Text(stringResource(R.string.licence_inland_footer), style = MaterialTheme.typography.bodySmall,
                     color = Sbf.colors.muted, modifier = Modifier.padding(bottom = 12.dp))
                Text(stringResource(R.string.licence_sea), style = MaterialTheme.typography.labelLarge, color = Sbf.colors.muted)
                val seaEnabled = goal.inland != LicenceGoal.Inland.NONE
                Row(
                    Modifier.fillMaxWidth()
                        .toggleable(goal.sea, enabled = seaEnabled, role = Role.Checkbox) { save(goal.copy(sea = it)) }
                        .padding(vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Checkbox(goal.sea, onCheckedChange = null, enabled = seaEnabled)
                    Spacer(Modifier.width(10.dp))
                    Text(stringResource(R.string.licence_also_sea), style = MaterialTheme.typography.bodyLarge, color = Sbf.colors.ink)
                }
                Text(stringResource(R.string.licence_footer), style = MaterialTheme.typography.bodySmall, color = Sbf.colors.muted)
            }
        },
    )
}
