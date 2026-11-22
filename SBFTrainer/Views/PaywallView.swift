import SwiftUI
import StoreKit

/// Sheet that sells Binnen, See and the Both bundle, restores purchases and
/// redeems school codes (Apple offer codes for the same products).
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
                            Label("Redeem School Code", systemImage: "ticket")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.navy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.navy.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            Task { await entitlements.restorePurchases() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundStyle(Color.navyMid)
                        }
                    }

                    Text("One-time purchase, no subscription. Unlocks on all devices signed in with your Apple ID.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .background(Color.surfaceBG)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.navy)
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
            Text("Unlock the full exam")
                .font(.title2.bold())
                .foregroundStyle(Color.navy)
            Text("Practise every official ELWIS question and take unlimited exam simulations.")
                .font(.subheadline)
                .foregroundStyle(Color.navyMid)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            featureRow("checkmark.seal.fill", "All questions of your exam, German and English")
            featureRow("photo.fill", "Every diagram and sign question")
            featureRow("timer", "Unlimited exam simulations (30 questions, 30 min)")
            featureRow("arrow.counterclockwise", "Mistakes training across the whole catalogue")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.gold)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.navy)
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
                    .foregroundStyle(Color.navy)
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
        .disabled(product == nil || entitlements.purchaseInProgress != nil)
    }

    private var allUnlockedCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.successGreen)
            Text("Everything is unlocked")
                .font(.headline)
                .foregroundStyle(Color.navy)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

/// Small call-to-action card shown where free users run into locked content.
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
                        .foregroundStyle(Color.navy)
                    Text("Free: all Basisfragen and a sample of each exam")
                        .font(.caption)
                        .foregroundStyle(Color.navyMid)
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
        }
        .buttonStyle(.plain)
    }
}

/// Shown in place of the answer options for a question the user hasn't unlocked.
struct LockedQuestionCard: View {
    let examType: ExamType
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title)
                .foregroundStyle(Color.gold)
            Text("This question is part of SBF \(examType == .see ? "See" : "Binnen")")
                .font(.headline)
                .foregroundStyle(Color.navy)
                .multilineTextAlignment(.center)
            Text("Unlock it to see the answers and practise every question of the exam.")
                .font(.subheadline)
                .foregroundStyle(Color.navyMid)
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
