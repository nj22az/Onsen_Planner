//
//  StoreManager.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) — Say More With Less
//  StoreKit 2 backbone for Vecka Pro: product loading, purchasing,
//  restore, and entitlement tracking.
//
//  Product catalog (create these in App Store Connect → Vecka → In-App
//  Purchases before release; until then the paywall renders in its
//  graceful "products unavailable" state and never crashes):
//    • Johansson.Vecka.pro.yearly   → Auto-Renewable Subscription (yearly, trial)
//    • Johansson.Vecka.pro.monthly  → Auto-Renewable Subscription (monthly)
//    • Johansson.Vecka.pro.lifetime → Non-Consumable
//

import Foundation
import StoreKit

/// Identifiers for every Vecka Pro product.
enum VeckaProduct: String, CaseIterable, Sendable {
    case proYearly = "Johansson.Vecka.pro.yearly"
    case proMonthly = "Johansson.Vecka.pro.monthly"
    case proLifetime = "Johansson.Vecka.pro.lifetime"

    /// Sort order used on the paywall (flagship first).
    var sortRank: Int {
        switch self {
        case .proYearly: return 0
        case .proMonthly: return 1
        case .proLifetime: return 2
        }
    }
}

/// Free-tier limits. Pro removes all of these.
enum ProLimits {
    /// Custom events (countdowns) a free user may keep.
    static let freeEventLimit = 3
    /// Trips a free user may keep.
    static let freeTripLimit = 3
}

/// Central StoreKit 2 manager. Singleton-owned and injected into the view
/// hierarchy via `.environment(...)` from `VeckaApp`, so previews and
/// UI-test roots can use `StoreManager.shared` directly.
@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()

    /// Available products, sorted flag-ship first. Empty until
    /// `loadProducts()` succeeds (and stays empty if the products do not
    /// exist in App Store Connect yet).
    private(set) var products: [Product] = []

    /// True after the first `loadProducts()` attempt finished, regardless
    /// of success — drives the paywall's loading vs. fallback states.
    private(set) var productsLoaded = false

    /// True while a purchase sheet interaction is in flight.
    private(set) var purchaseInFlight = false

    /// Last user-presentable error message (purchase/restore failures).
    private(set) var lastError: String?

    /// Whether the user currently holds Vecka Pro.
    ///
    /// The source of truth is StoreKit's `Transaction.currentEntitlements`;
    /// this property is its main-actor mirror and is persisted to
    /// `UserDefaults` so a cold launch starts with the last known state
    /// while StoreKit re-verifies asynchronously.
    private(set) var isPro: Bool

    private static let isProDefaultsKey = "vecka.pro.entitlement"

    /// Listener for transactions that happen outside an explicit purchase
    /// call (family sharing, Ask to Buy approval, renewals, revocations,
    /// purchases on another device).
    private var transactionUpdatesTask: Task<Void, Never>?

    private init() {
        isPro = UserDefaults.standard.bool(forKey: Self.isProDefaultsKey)
        transactionUpdatesTask = Task.detached { [weak self] in
            await self?.observeTransactionUpdates()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    // MARK: - Products

    /// Fetch the product catalog from the App Store. Safe to call more than
    /// once (e.g. when the paywall appears after a failed launch attempt).
    func loadProducts() async {
        do {
            let ids = VeckaProduct.allCases.map(\.rawValue)
            let fetched = try await Product.products(for: ids)
            products = fetched.sorted {
                (VeckaProduct(rawValue: $0.id)?.sortRank ?? .max) <
                (VeckaProduct(rawValue: $1.id)?.sortRank ?? .max)
            }
            lastError = nil
        } catch {
            Log.w("StoreManager: product fetch failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
        }
        productsLoaded = true
    }

    /// Look up a loaded product by its catalog identifier.
    func product(for id: VeckaProduct) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    // MARK: - Purchase

    /// Purchase a product. Returns true when the entitlement became active.
    /// Handles user cancellation and Ask-to-Buy/pending states quietly.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    lastError = nil
                    Log.i("StoreManager: purchased \(transaction.productID)")
                    return isPro
                case .unverified(_, let error):
                    Log.w("StoreManager: unverified transaction: \(error.localizedDescription)")
                    lastError = error.localizedDescription
                    return false
                }

            case .pending:
                // Ask to Buy / SCA: entitlement arrives later via Transaction.updates.
                Log.i("StoreManager: purchase pending approval")
                return false

            case .userCancelled:
                return false

            @unknown default:
                return false
            }
        } catch {
            Log.w("StoreManager: purchase failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Restore

    /// Restore purchases (required by App Review for any IAP that can be
    /// bought on another device). `AppStore.sync()` also surfaces the system
    /// account sheet when needed.
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            lastError = nil
        } catch {
            Log.w("StoreManager: restore failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
        }
    }

    // MARK: - Entitlements

    /// Recompute `isPro` from current verified entitlements. A revocation
    /// (refund) flips it back to false; the subscription grace period /
    /// billing-retry states keep it true because Apple keeps the
    /// entitlement alive until expiration.
    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard VeckaProduct.allCases.contains(where: { $0.rawValue == transaction.productID }) else { continue }
            if transaction.revocationDate == nil {
                active = true
            }
        }
        setIsPro(active)
    }

    /// Persist and publish the entitlement state.
    private func setIsPro(_ newValue: Bool) {
        guard newValue != isPro else { return }
        isPro = newValue
        UserDefaults.standard.set(newValue, forKey: Self.isProDefaultsKey)
        Log.i("StoreManager: Vecka Pro entitlement \(newValue ? "ACTIVE" : "inactive")")
    }

    /// Non-isolated listener entry point (the task is detached).
    private func observeTransactionUpdates() async {
        for await update in Transaction.updates {
            guard case .verified(let transaction) = update else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }
}
