import SwiftUI
import StoreKit

/// Sells SBF Inland, SBF Sea and the cheaper bundle, restores purchases and redeems
/// school codes (Apple offer codes for the same products).
struct PaywallView: View {
    @EnvironmentObject var entitlements: EntitlementManager
    @Environment(\.dismiss) private var dismiss
    @State private var showRedeemSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header

                    if entitlements.hasEverything {
                        allUnlockedCard
                    } else {
                        featureList
                        productList
                    }

                    VStack(spacing: 12) {
                        Button {
                            showRedeemSheet = true
                        } label: {
                            Label("Redeem school code", systemImage: "ticket")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.navyLight.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            Task { await entitlements.restorePurchases() }
                        } label: {
                            Text("Restore purchases")
                                .font(.subheadline)
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }

                    Text("One-time purchase, no subscription. Unlocks on all devices with your Apple ID.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .readableWidth()
            }
            .background(Color.surfaceBG)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .offerCodeRedemption(isPresented: $showRedeemSheet) { _ in
                Task { await entitlements.refreshEntitlements() }
            }
            .task { await entitlements.loadProducts() }
            .alert("Purchase", isPresented: Binding(
                get: { entitlements.errorMessage != nil },
                set: { if !$0 { entitlements.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(entitlements.errorMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "sailboat.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.gold)
                .accessibilityHidden(true)
            Text("Unlock the full catalogue")
                .font(.title2.bold())
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
            Text("Practise every official question and take unlimited exam simulations.")
                .font(.subheadline)
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            featureRow("checkmark.seal.fill", "All questions of your licence, German and English")
            featureRow("photo.fill", "Every illustration and sound signal")
            featureRow("timer", "Unlimited exam simulations with the official pass marks")
            featureRow("arrow.counterclockwise", "Spaced repetition and mistakes across the whole catalogue")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func featureRow(_ icon: String, _ text: LocalizedStringKey) -> some View {
        Label {
            Text(text).font(.subheadline).foregroundStyle(Color.ink)
        } icon: {
            Image(systemName: icon).foregroundStyle(Color.gold)
        }
    }

    private var productList: some View {
        VStack(spacing: 10) {
            ForEach(entitlements.offeredProducts) { item in
                productButton(item)
            }
            if entitlements.products.isEmpty {
                if entitlements.isLoadingProducts {
                    ProgressView().padding()
                } else {
                    Button("Load prices") {
                        Task { await entitlements.loadProducts() }
                    }
                }
            }
        }
    }

    private func productButton(_ item: ProProduct) -> some View {
        let product = entitlements.products[item]
        let isBundle = item == .both
        let busy = entitlements.purchaseInProgress == item
        return Button {
            Task { await entitlements.purchase(item) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundStyle(isBundle ? Color.navy : Color.gold)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(isBundle ? Color.navy : .white)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(isBundle ? Color.navyMid : Color.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if busy {
                    ProgressView()
                } else {
                    Text(product?.displayPrice ?? "–")
                        .font(.headline)
                        .foregroundStyle(isBundle ? Color.navy : .white)
                }
            }
            .padding(16)
            .background(isBundle ? AnyShapeStyle(AppGradient.gold) : AnyShapeStyle(AppGradient.navy))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(product == nil || entitlements.purchaseInProgress != nil)
    }

    private var allUnlockedCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.successGreen)
            Text("Everything is unlocked")
                .font(.headline)
                .foregroundStyle(Color.ink)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

/// Call-to-action card shown where free users run into locked content.
struct UnlockBanner: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "lock.open.fill")
                    .font(.title3)
                    .foregroundStyle(Color.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock all questions")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.ink)
                    Text("Free: all basic questions and a sample of every topic")
                        .font(.caption)
                        .foregroundStyle(Color.inkSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.gold.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gold.opacity(0.4), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Shown instead of the answer options of a question the user hasn't unlocked.
struct LockedQuestionCard: View {
    let examType: ExamType
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title)
                .foregroundStyle(Color.gold)
                .accessibilityHidden(true)
            Text("Part of the full version · \(examType.licenceName)")
                .font(.headline)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
            Text("Unlock it to see the answers and practise every question of your licence.")
                .font(.subheadline)
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
            Button(action: action) {
                Text("Unlock")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppGradient.navy)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}
