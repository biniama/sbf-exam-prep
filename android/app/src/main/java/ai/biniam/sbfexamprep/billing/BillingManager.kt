package ai.biniam.sbfexamprep.billing

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import androidx.core.content.edit
import ai.biniam.sbfexamprep.data.Access
import ai.biniam.sbfexamprep.data.ExamFormat
import ai.biniam.sbfexamprep.data.ProProduct
import ai.biniam.sbfexamprep.data.licenceType
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Google Play Billing for the three one-time purchases. School codes are Google Play promo
 * codes for the same products: a code redeemed in the Play Store arrives as a normal purchase,
 * picked up by [refresh] when the app comes back to the foreground.
 */
class BillingManager(context: Context) : PurchasesUpdatedListener {
    private val appContext = context.applicationContext
    private val prefs: SharedPreferences = appContext.getSharedPreferences("billing", Context.MODE_PRIVATE)

    /** Last known purchases, so the app starts unlocked even before Play answers. */
    private val _access = MutableStateFlow(Access(loadCachedOwned()))
    val access: StateFlow<Access> = _access.asStateFlow()

    private val _prices = MutableStateFlow<Map<ProProduct, String>>(emptyMap())
    val prices: StateFlow<Map<ProProduct, String>> = _prices.asStateFlow()

    private val _message = MutableStateFlow<BillingMessage?>(null)
    /** One-off feedback for the paywall (pending purchase, error). */
    val message: StateFlow<BillingMessage?> = _message.asStateFlow()

    /** Shows the paywall sheet above everything else (see SbfApp). */
    val paywallShown = MutableStateFlow(false)

    private var productDetails: Map<ProProduct, ProductDetails> = emptyMap()

    private val client: BillingClient = BillingClient.newBuilder(appContext)
        .setListener(this)
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .enableAutoServiceReconnection()
        .build()

    fun start() {
        if (client.isReady) {
            refresh()
            return
        }
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    loadProducts()
                    refresh()
                }
            }

            override fun onBillingServiceDisconnected() {
                // Reconnection is automatic (enableAutoServiceReconnection).
            }
        })
    }

    /** Re-reads owned purchases from Play: promo code redemptions, purchases on other devices, refunds. */
    fun refresh() {
        if (!client.isReady) return start()
        val params = QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build()
        client.queryPurchasesAsync(params) { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) handlePurchases(purchases, replaceAll = true)
        }
    }

    private fun loadProducts() {
        val products = ProProduct.entries.map {
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(it.productId)
                .setProductType(BillingClient.ProductType.INAPP)
                .build()
        }
        val params = QueryProductDetailsParams.newBuilder().setProductList(products).build()
        client.queryProductDetailsAsync(params) { result, details ->
            if (result.responseCode != BillingClient.BillingResponseCode.OK) return@queryProductDetailsAsync
            productDetails = details.productDetailsList.mapNotNull { pd -> ProProduct.fromId(pd.productId)?.let { it to pd } }.toMap()
            _prices.value = productDetails.mapNotNull { (product, pd) ->
                pd.oneTimePurchaseOfferDetails?.formattedPrice?.let { product to it }
            }.toMap()
        }
    }

    fun purchase(activity: Activity, product: ProProduct) {
        val details = productDetails[product]
        if (details == null) {
            _message.value = BillingMessage.PRICES_UNAVAILABLE
            start()
            return
        }
        val params = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(details).build()))
            .build()
        client.launchBillingFlow(activity, params)
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: MutableList<Purchase>?) {
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> handlePurchases(purchases.orEmpty(), replaceAll = false)
            BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED -> refresh()
            BillingClient.BillingResponseCode.USER_CANCELED -> Unit
            else -> _message.value = BillingMessage.PURCHASE_FAILED
        }
    }

    private fun handlePurchases(purchases: List<Purchase>, replaceAll: Boolean) {
        val owned = mutableSetOf<ProProduct>()
        for (purchase in purchases) {
            when (purchase.purchaseState) {
                Purchase.PurchaseState.PURCHASED -> {
                    owned += purchase.products.mapNotNull(ProProduct::fromId)
                    // Unacknowledged purchases are refunded by Play after three days.
                    if (!purchase.isAcknowledged) acknowledge(purchase)
                }
                Purchase.PurchaseState.PENDING -> _message.value = BillingMessage.PENDING
                else -> Unit
            }
        }
        val updated = if (replaceAll) owned else _access.value.owned + owned
        _access.value = Access(updated)
        prefs.edit { putStringSet(KEY_OWNED, updated.map { it.productId }.toSet()) }
        if (_access.value.hasEverything) paywallShown.value = false
    }

    private fun acknowledge(purchase: Purchase) {
        val params = AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.purchaseToken).build()
        client.acknowledgePurchase(params) { }
    }

    private fun loadCachedOwned(): Set<ProProduct> =
        prefs.getStringSet(KEY_OWNED, emptySet()).orEmpty().mapNotNull(ProProduct::fromId).toSet()

    fun clearMessage() {
        _message.value = null
    }

    /** Opens the Play Store page for redeeming a promo code (school code). */
    fun openRedeemCode(activity: Activity) {
        activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/redeem?code=")))
    }

    // Free exam simulation trial (one per licence) ------------------------------------------

    private fun trialKey(format: ExamFormat) = "freeExamSimUsed." + format.licenceType.raw

    fun hasFreeExamTrial(format: ExamFormat): Boolean = !prefs.getBoolean(trialKey(format), false)

    fun consumeFreeExamTrial(format: ExamFormat) = prefs.edit { putBoolean(trialKey(format), true) }

    fun canStartExamSimulation(format: ExamFormat): Boolean =
        _access.value.hasAccess(format.licenceType) || hasFreeExamTrial(format)

    companion object {
        private const val KEY_OWNED = "owned"
    }
}

enum class BillingMessage { PENDING, PURCHASE_FAILED, PRICES_UNAVAILABLE }
