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
        case .binnen: return String(localized: "SBF Inland")
        case .see:    return String(localized: "SBF Sea")
        case .both:   return String(localized: "SBF Inland + Sea")
        }
    }

    var subtitle: String {
        switch self {
        case .binnen: return String(localized: "All inland and sailing questions, unlimited exam simulations")
        case .see:    return String(localized: "All sea questions and navigation tasks, unlimited exam simulations")
        case .both:   return String(localized: "Everything for both licences. Best value")
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
    /// Shows the paywall from the tab level (see MainTabView).
    @Published var paywallShown = false

    private var updatesTask: Task<Void, Never>?
    private let defaults: UserDefaults

    /// Test instance: fixed purchases, own defaults, no StoreKit.
    init(testOwned: Set<ProProduct>, defaults: UserDefaults) {
        self.defaults = defaults
        owned = testOwned
    }

    private init() {
        defaults = .standard
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

    /// Full access to the questions of one exam type. Basic questions are always free;
    /// the sailing questions belong to the inland licence.
    func hasAccess(to type: ExamType) -> Bool {
        switch type {
        case .shared:          return true
        case .binnen, .segeln: return hasBinnen
        case .see:             return hasSee
        case .all:             return hasEverything
        }
    }

    /// Navigation tasks 1…N are a free sample; the rest belong to SBF Sea.
    static let freeNavigationTasks = 1

    func canOpenNavigationTask(_ number: Int) -> Bool { hasSee || number <= Self.freeNavigationTasks }

    /// Products worth offering right now: never the bundle once one exam is owned,
    /// so nobody pays twice for the same questions.
    var offeredProducts: [ProProduct] {
        if hasEverything { return [] }
        if hasBinnen { return [.see] }
        if hasSee { return [.binnen] }
        return [.both, .binnen, .see]
    }

    // MARK: - Free exam simulation trial (one run per exam)

    private func trialKey(_ format: ExamFormat) -> String { "freeExamSimUsed.\(format.licenceType.rawValue)" }

    /// One free exam simulation per licence (inland formats share one trial).
    func hasFreeExamTrial(for format: ExamFormat) -> Bool {
        !defaults.bool(forKey: trialKey(format))
    }

    func consumeFreeExamTrial(for format: ExamFormat) {
        defaults.set(true, forKey: trialKey(format))
        objectWillChange.send()
    }

    /// Whether an exam simulation in this format may start now (owned or free trial left).
    func canStartExamSimulation(_ format: ExamFormat) -> Bool {
        hasAccess(to: format.licenceType) || hasFreeExamTrial(for: format)
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
            errorMessage = String(localized: "Could not load prices from the App Store. Please check your connection.")
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
                errorMessage = String(localized: "Your purchase is waiting for approval.")
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = String(localized: "The purchase could not be completed. Please try again.")
        }
    }

    /// Required by App Review: lets users get their purchases back on a new device.
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = String(localized: "Could not restore purchases. Please check your connection.")
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

extension ExamFormat {
    /// The purchase an exam simulation in this format needs.
    var licenceType: ExamType { self == .see ? .see : .binnen }
}
