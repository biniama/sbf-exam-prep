package ai.biniam.sbfexamprep.ui.billing

import androidx.activity.compose.LocalActivity
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.ConfirmationNumber
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material.icons.filled.Sailing
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ai.biniam.sbfexamprep.R
import ai.biniam.sbfexamprep.billing.BillingMessage
import ai.biniam.sbfexamprep.data.ExamType
import ai.biniam.sbfexamprep.data.ProProduct
import ai.biniam.sbfexamprep.ui.LocalApp
import ai.biniam.sbfexamprep.ui.components.licenceName
import ai.biniam.sbfexamprep.ui.theme.Brand
import ai.biniam.sbfexamprep.ui.theme.Sbf

/** Sells SBF Inland, SBF Sea and the cheaper bundle; redeems school codes; restores purchases. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaywallSheet(onDismiss: () -> Unit) {
    val billing = LocalApp.current.billing
    val activity = LocalActivity.current
    val access by billing.access.collectAsStateWithLifecycle()
    val prices by billing.prices.collectAsStateWithLifecycle()
    val message by billing.message.collectAsStateWithLifecycle()
    val sheet = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheet, containerColor = Sbf.colors.surface) {
        Column(
            Modifier.verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Icon(Icons.Filled.Sailing, null, tint = Brand.gold, modifier = Modifier.size(44.dp))
            Text(stringResource(R.string.paywall_title), style = MaterialTheme.typography.titleLarge,
                 color = Sbf.colors.ink, textAlign = TextAlign.Center)
            Text(stringResource(R.string.paywall_subtitle), style = MaterialTheme.typography.bodyMedium,
                 color = Sbf.colors.inkSecondary, textAlign = TextAlign.Center)

            if (access.hasEverything) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.CheckCircle, null, tint = Sbf.colors.success)
                    Spacer(Modifier.width(8.dp))
                    Text(stringResource(R.string.paywall_all_unlocked), color = Sbf.colors.ink,
                         style = MaterialTheme.typography.titleMedium)
                }
            } else {
                Column(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Sbf.colors.card).padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Feature(Icons.Filled.Verified, stringResource(R.string.paywall_feature_questions))
                    Feature(Icons.Filled.Image, stringResource(R.string.paywall_feature_media))
                    Feature(Icons.Filled.Timer, stringResource(R.string.paywall_feature_exams))
                    Feature(Icons.Filled.Replay, stringResource(R.string.paywall_feature_review))
                }
                access.offeredProducts.forEach { product ->
                    ProductButton(product, prices[product], enabled = activity != null) {
                        activity?.let { billing.purchase(it, product) }
                    }
                }
            }

            message?.let {
                Text(
                    stringResource(when (it) {
                        BillingMessage.PENDING -> R.string.billing_pending
                        BillingMessage.PURCHASE_FAILED -> R.string.billing_failed
                        BillingMessage.PRICES_UNAVAILABLE -> R.string.billing_prices_unavailable
                    }),
                    color = Sbf.colors.error, style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Center,
                )
            }

            OutlinedButton(onClick = { activity?.let(billing::openRedeemCode) }, modifier = Modifier.fillMaxWidth()) {
                Icon(Icons.Filled.ConfirmationNumber, null)
                Spacer(Modifier.width(8.dp))
                Text(stringResource(R.string.redeem_school_code))
            }
            TextButton(onClick = { billing.clearMessage(); billing.refresh() }) {
                Text(stringResource(R.string.restore_purchases), color = Sbf.colors.inkSecondary)
            }
            Text(stringResource(R.string.paywall_footnote), style = MaterialTheme.typography.bodySmall,
                 color = Sbf.colors.muted, textAlign = TextAlign.Center)
        }
    }
}

@Composable
private fun Feature(icon: ImageVector, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = Brand.gold, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(10.dp))
        Text(text, style = MaterialTheme.typography.bodyMedium, color = Sbf.colors.ink)
    }
}

@Composable
private fun ProductButton(product: ProProduct, price: String?, enabled: Boolean, onClick: () -> Unit) {
    val bundle = product == ProProduct.BOTH
    val fg = if (bundle) Brand.navy else Color.White
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp))
            .background(if (bundle) Brand.goldGradient else Brand.navyGradient)
            .clickable(enabled = enabled && price != null, onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(if (bundle) Icons.Filled.Star else Icons.Filled.Sailing, null, tint = if (bundle) Brand.navy else Brand.gold)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(stringResource(product.titleRes), color = fg, style = MaterialTheme.typography.titleMedium,
                 fontWeight = FontWeight.SemiBold)
            Text(stringResource(product.subtitleRes), color = fg.copy(alpha = 0.8f), style = MaterialTheme.typography.bodySmall)
        }
        Spacer(Modifier.width(8.dp))
        Text(price ?: "–", color = fg, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
    }
}

private val ProProduct.titleRes: Int
    get() = when (this) {
        ProProduct.BINNEN -> R.string.product_binnen
        ProProduct.SEE -> R.string.product_see
        ProProduct.BOTH -> R.string.product_both
    }

private val ProProduct.subtitleRes: Int
    get() = when (this) {
        ProProduct.BINNEN -> R.string.product_binnen_summary
        ProProduct.SEE -> R.string.product_see_summary
        ProProduct.BOTH -> R.string.product_both_summary
    }

/** Call-to-action card where free users run into locked content. */
@Composable
fun UnlockBanner(modifier: Modifier = Modifier) {
    val billing = LocalApp.current.billing
    val access by billing.access.collectAsStateWithLifecycle()
    if (access.hasEverything) return
    Row(
        modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp))
            .background(Brand.gold.copy(alpha = 0.12f))
            .border(1.dp, Brand.gold.copy(alpha = 0.4f), RoundedCornerShape(14.dp))
            .clickable { billing.paywallShown.value = true }
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.LockOpen, null, tint = Brand.gold)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(stringResource(R.string.unlock_all_questions), color = Sbf.colors.ink,
                 style = MaterialTheme.typography.titleSmall)
            Text(stringResource(R.string.unlock_all_questions_summary), color = Sbf.colors.inkSecondary,
                 style = MaterialTheme.typography.bodySmall)
        }
        Icon(Icons.Filled.ChevronRight, null, tint = Sbf.colors.muted)
    }
}

/** Shown instead of the answer options of a question the user hasn't unlocked. */
@Composable
fun LockedQuestionCard(type: ExamType, modifier: Modifier = Modifier) {
    val billing = LocalApp.current.billing
    Column(
        modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Sbf.colors.card).padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(Icons.Filled.Lock, null, tint = Brand.gold, modifier = Modifier.size(32.dp))
        Text(stringResource(R.string.locked_question_title, licenceName(type)), color = Sbf.colors.ink,
             style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center)
        Text(stringResource(R.string.locked_question_text), color = Sbf.colors.inkSecondary,
             style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center)
        Button(
            onClick = { billing.paywallShown.value = true },
            colors = ButtonDefaults.buttonColors(containerColor = Brand.navy, contentColor = Color.White),
            modifier = Modifier.fillMaxWidth(),
        ) { Text(stringResource(R.string.unlock)) }
    }
}
