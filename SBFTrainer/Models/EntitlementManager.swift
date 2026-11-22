import Foundation
import StoreKit

/// The three one-time purchases sold in the app. School codes (Apple offer codes)
/// unlock these same products, so a redeemed code arrives as a normal transaction.
enum ProProduct: String, CaseIterable, Identifiable {
    case binnen = "ai.biniam.SBFExamPrep.binnen"
    case see    = "ai.biniam.SBFExamPrep.see"
    case both   = "ai.biniam.SBFExamPrep.both"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .binnen: return "SBF Binnen"
        case .see:    return "SBF See"
        case .both:   return "Binnen + See"
        }
    }

    var subtitle: String {
        switch self {
        case .binnen: return "All 253 Binnen questions incl. Basisfragen, unlimited exam simulations"
        case .see:    return "All 285 See questions incl. Basisfragen, unlimited exam simulations"
        case .both:   return "All 466 questions for both exams. Best value"
        }
    }

    var icon: String {
        switch self {
        case .binnen: return ExamType.binnen.icon
        case .see:    return ExamType.see.icon
        case .both:   return "star.circle.fill"
        }
    }
}

@MainActor
final class EntitlementManager: ObservableObject {
    static let shared = EntitlementManager()

    @Published private(set) var products: [ProProduct: Product] = [:]
    @Published private(set) var owned: Set<ProProduct> = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var purchaseInProgress: ProProduct? = nil
    @Published var errorMessage: String? = nil

    private var updatesTask: Task<Void, Never>?
    private let defaults = UserDefaults.standard

    private init() {
        updatesTask = listenForTransactions()
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    // MARK: - Access

    var hasBinnen: Bool { owned.contains(.binnen) || owned.contains(.both) }
    var hasSee: Bool    { owned.contains(.see)    || owned.contains(.both) }
    var hasEverything: Bool { hasBinnen && hasSee }

    /// Full access to the questions of one exam type.
    func hasAccess(to type: ExamType) -> Bool {
        switch type {
        case .shared: return true
        case .binnen: return hasBinnen
        case .see:    return hasSee
        case .all:    return hasEverything
        }
    }

    /// Products worth offering right now: never the bundle once one exam is owned,
    /// so nobody pays twice for the same questions.
    var offeredProducts: [ProProduct] {
        if hasEverything { return [] }
        if hasBinnen { return [.see] }
        if hasSee { return [.binnen] }
        return [.both, .binnen, .see]
    }

    // MARK: - Free exam simulation trial (one run per exam)

    private func trialKey(_ type: ExamType) -> String { "freeExamSimUsed.\(type.rawValue)" }

    func hasFreeExamTrial(for type: ExamType) -> Bool {
        !defaults.bool(forKey: trialKey(type))
    }

    func consumeFreeExamTrial(for type: ExamType) {
        defaults.set(true, forKey: trialKey(type))
        objectWillChange.send()
    }

    /// Whether an exam simulation for this exam may start now (owned or free trial left).
    func canStartExamSimulation(for type: ExamType) -> Bool {
        hasAccess(to: type) || hasFreeExamTrial(for: type)
    }

    // MARK: - Products

    func loadProducts() async {
        guard products.isEmpty, !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: ProProduct.allCases.map(\.rawValue))
            var map: [ProProduct: Product] = [:]
            for product in loaded {
                if let id = ProProduct(rawValue: product.id) { map[id] = product }
            }
            products = map
        } catch {
            errorMessage = "Could not load prices from the App Store. Please check your connection."
        }
    }

    // MARK: - Purchase

    func purchase(_ item: ProProduct) async {
        guard let product = products[item] else {
            await loadProducts()
            return
        }
        purchaseInProgress = item
        defer { purchaseInProgress = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if let transaction = checkVerified(verification) {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .pending:
                errorMessage = "Your purchase is waiting for approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "The purchase could not be completed. Please try again."
        }
    }

    /// Required by App Review: lets users get their purchases back on a new device.
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = "Could not restore purchases. Please check your connection."
        }
        await refreshEntitlements()
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        var current: Set<ProProduct> = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = checkVerified(result),
                  transaction.revocationDate == nil,
                  let item = ProProduct(rawValue: transaction.productID) else { continue }
            current.insert(item)
        }
        owned = current
    }

    /// Picks up purchases made outside the paywall: offer code redemptions in the
    /// App Store, Ask to Buy approvals, refunds and purchases on other devices.
    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = self.checkVerified(result) {
                    await transaction.finish()
                }
                await self.refreshEntitlements()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) -> T? {
        switch result {
        case .verified(let value): return value
        case .unverified:          return nil
        }
    }
}
