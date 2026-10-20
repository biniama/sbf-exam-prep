package ai.biniam.sbfexamprep

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import ai.biniam.sbfexamprep.ui.SbfApp
import ai.biniam.sbfexamprep.ui.theme.SbfTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) DebugLaunch.read(intent, application as SbfApplication)
        setContent {
            SbfTheme {
                SbfApp(application as SbfApplication)
            }
        }
    }
}
