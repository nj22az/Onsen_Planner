import Foundation
import Observation

enum VeckaProduct: String, CaseIterable, Sendable {
    case proYearly = "Johansson.Vecka.pro.yearly"
    case proMonthly = "Johansson.Vecka.pro.monthly"
    case proLifetime = "Johansson.Vecka.pro.lifetime"

    var sortRank: Int {
        switch self {
        case .proYearly: return 0
        case .proMonthly: return 1
        case .proLifetime: return 2
        }
    }
}

enum ProLimits {
    static let freeEventLimit = 3
    static let freeTripLimit = 3
}

enum ProductLoadState: Equatable { case idle, loading, ready, unavailable }
enum PurchaseState: Equatable { case idle, purchasing, pending, restoring, completed, failed }
enum EntitlementState: Equatable { case checking, active, inactive, unavailable }

@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()
    private(set) var products: [ProOffering] = []
    private(set) var productState: ProductLoadState = .idle
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var entitlementState: EntitlementState = .checking
    private(set) var lastError: String?
    private(set) var statusMessage: String?
    private(set) var isPro = false
    /// Presentation only: never grants access before StoreKit verification.
    private(set) var previouslyHadPro: Bool
    let salesEnabled: Bool

    var canUseProFeatures: Bool { !salesEnabled || isPro }
    var purchaseInFlight: Bool { purchaseState == .purchasing || purchaseState == .restoring }
    var canPurchase: Bool {
        salesEnabled && !isPro && entitlementState == .inactive &&
        productState == .ready && !purchaseInFlight && purchaseState != .pending
    }

    @ObservationIgnored private let client: ProStoreClient
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var transactionUpdatesTask: Task<Void, Never>?
    @ObservationIgnored private var entitlementGeneration = 0
    private static let defaultsKey = "vecka.pro.entitlement"

    init(client: ProStoreClient? = nil, defaults: UserDefaults = .standard,
         salesEnabled: Bool = ReleaseFeatures.proSalesEnabled, listenForUpdates: Bool = true) {
        self.client = client ?? AppleProStoreClient()
        self.defaults = defaults
        self.salesEnabled = salesEnabled
        previouslyHadPro = defaults.bool(forKey: Self.defaultsKey)
        if listenForUpdates {
            let updates = self.client.updates()
            transactionUpdatesTask = Task { [weak self] in
                for await _ in updates {
                    guard !Task.isCancelled else { break }
                    await self?.refreshEntitlements()
                }
            }
        }
    }

    deinit { transactionUpdatesTask?.cancel() }

    func loadProducts() async {
        guard salesEnabled, productState != .loading else { return }
        productState = .loading
        do {
            let fetched = try await client.loadProducts()
            products = fetched
            productState = fetched.isEmpty ? .unavailable : .ready
        } catch {
            // Do not change entitlements just because product/pricing servers fail.
            productState = .unavailable
            Log.w("Product loading failed: \(error.localizedDescription)")
        }
    }

    func product(for id: VeckaProduct) -> ProOffering? {
        products.first { $0.id == id.rawValue }
    }

    @discardableResult
    func purchase(_ product: ProOffering) async -> Bool {
        guard canPurchase, products.contains(where: { $0.id == product.id }) else { return false }
        purchaseState = .purchasing
        lastError = nil
        statusMessage = nil
        do {
            let result = try await client.purchase(productID: product.id)
            switch result {
            case .verified:
                await refreshEntitlements()
                if isPro {
                    purchaseState = .completed
                    statusMessage = "Vecka Pro is active."
                    return true
                }
                purchaseState = .pending
                statusMessage = "Your purchase is confirmed. Checking access; please use Check access if it does not update."
            case .pending:
                purchaseState = .pending
                statusMessage = "Awaiting purchase approval. You can continue using your planner."
            case .cancelled:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed
            lastError = error.localizedDescription
        }
        return false
    }

    func restorePurchases() async {
        guard !purchaseInFlight else { return }
        let wasPending = purchaseState == .pending
        purchaseState = .restoring
        lastError = nil
        statusMessage = nil
        do {
            try await client.restore()
            await refreshEntitlements()
            if entitlementState == .unavailable {
                purchaseState = wasPending ? .pending : .failed
                lastError = "Purchases could not be verified. Try again later; your planner data is unchanged."
            } else if isPro {
                purchaseState = .completed
                statusMessage = "Your Vecka Pro purchase was restored."
            } else {
                purchaseState = wasPending ? .pending : .idle
                statusMessage = wasPending ? "No approved purchase yet. Approval may still be pending." : "No active Vecka Pro purchase was found for this Apple Account."
            }
        } catch {
            purchaseState = wasPending ? .pending : .failed
            lastError = "Restore failed. \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        entitlementGeneration &+= 1
        let generation = entitlementGeneration
        let result = await client.currentEntitlement()
        guard generation == entitlementGeneration else { return }
        switch result {
        case .active:
            isPro = true
            entitlementState = .active
            if purchaseState == .pending {
                purchaseState = .completed
                statusMessage = "Vecka Pro is now active."
            }
        case .inactive:
            isPro = false
            entitlementState = .inactive
        case .unavailable:
            // Keep only access already verified in this running session.
            // A saved Boolean on its own never grants paid access.
            entitlementState = .unavailable
            return
        }
        previouslyHadPro = isPro
        defaults.set(isPro, forKey: Self.defaultsKey)
        await client.finishVerifiedTransactions(accessGranted: isPro)
    }
}
