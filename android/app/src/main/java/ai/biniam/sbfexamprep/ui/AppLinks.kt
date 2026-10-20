package ai.biniam.sbfexamprep.ui

object AppLinks {
    const val WEBSITE = "https://sbf-exam-prep.web.app"
    const val ELWIS = "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Sportbootfuehrerscheine-node.html"

    fun privacy(german: Boolean) = "$WEBSITE/" + if (german) "datenschutz" else "privacy"
    fun support(german: Boolean) = "$WEBSITE/" + if (german) "hilfe" else "support"
    fun playStore(packageName: String) = "market://details?id=$packageName"
    fun playStoreWeb(packageName: String) = "https://play.google.com/store/apps/details?id=$packageName"
}
