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
        (application as SbfApplication).billing.start()
        setContent {
            SbfTheme {
                SbfApp(application as SbfApplication)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Picks up promo codes (school codes) redeemed in the Play Store meanwhile.
        (application as SbfApplication).billing.refresh()
    }
}
