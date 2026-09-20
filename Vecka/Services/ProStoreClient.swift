import Foundation
import StoreKit

struct ProOffering: Identifiable, Equatable {
    let id: String
    let displayName: String
    let displayPrice: String
    let detail: String
}

enum ProEntitlement: Equatable { case active, inactive, unavailable }
enum ProPurchaseResult { case verified, pending, cancelled }

@MainActor
protocol ProStoreClient: AnyObject {
    func loadProducts() async throws -> [ProOffering]
    func currentEntitlement() async -> ProEntitlement
    func purchase(productID: String) async throws -> ProPurchaseResult
    func restore() async throws
    func finishVerifiedTransactions(accessGranted: Bool) async
    func updates() -> AsyncStream<Void>
}

enum ProStoreError: LocalizedError {
    case unavailable, unverified
    var errorDescription: String? {
        switch self {
        case .unavailable: return "This purchase is unavailable. Reload the products and try again."
        case .unverified: return "The purchase could not be verified. Restore purchases or try again later."
        }
    }
}

/// StoreKit is isolated here so recovery behaviour can be tested without payments.
@MainActor
final class AppleProStoreClient: ProStoreClient {
    private var products: [String: Product] = [:]
    private var unfinished: [UInt64: Transaction] = [:]

    func loadProducts() async throws -> [ProOffering] {
        let fetched = try await Product.products(for: VeckaProduct.allCases.map(\.rawValue))
        products = Dictionary(fetched.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var offerings: [ProOffering] = []
        for product in fetched {
            guard let kind = VeckaProduct(rawValue: product.id) else { continue }
            var detail = kind == .proLifetime ? "One payment, Pro forever" : ""
            if let subscription = product.subscription {
                detail = "\(product.displayPrice) every \(Self.periodDescription(subscription.subscriptionPeriod))"
                let eligibleForTrial = await subscription.isEligibleForIntroOffer
                if let offer = subscription.introductoryOffer,
                   offer.paymentMode == .freeTrial,
                   eligibleForTrial {
                    detail = "\(Self.periodDescription(offer.period)) free trial, then \(detail)"
                }
            }
            offerings.append(ProOffering(id: product.id, displayName: product.displayName,
                                         displayPrice: product.displayPrice, detail: detail))
        }
        return offerings.sorted {
            (VeckaProduct(rawValue: $0.id)?.sortRank ?? .max) < (VeckaProduct(rawValue: $1.id)?.sortRank ?? .max)
        }
    }

    private static func periodDescription(_ period: Product.SubscriptionPeriod) -> String {
        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        @unknown default: unit = "period"
        }
        return "\(period.value) \(unit)\(period.value == 1 ? "" : "s")"
    }

    func currentEntitlement() async -> ProEntitlement {
        var couldNotVerify = false
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                guard VeckaProduct(rawValue: transaction.productID) != nil else { continue }
                // currentEntitlements includes subscribed / grace-period access,
                // and excludes expired, refunded and revoked subscriptions.
                if transaction.revocationDate == nil { return .active }
            case .unverified(let transaction, _):
                if VeckaProduct(rawValue: transaction.productID) != nil { couldNotVerify = true }
            }
        }
        return couldNotVerify ? .unavailable : .inactive
    }

    func purchase(productID: String) async throws -> ProPurchaseResult {
        guard let product = products[productID] else { throw ProStoreError.unavailable }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw ProStoreError.unverified }
            unfinished[transaction.id] = transaction
            return .verified
        case .pending: return .pending
        case .userCancelled: return .cancelled
        @unknown default: throw ProStoreError.unavailable
        }
    }

    func restore() async throws { try await AppStore.sync() }

    func finishVerifiedTransactions(accessGranted: Bool) async {
        let completed = unfinished
        for (id, transaction) in completed {
            let expired = transaction.expirationDate.map { $0 <= Date() } ?? false
            guard accessGranted || transaction.revocationDate != nil || expired else { continue }
            await transaction.finish()
            unfinished.removeValue(forKey: id)
        }
    }

    func updates() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let listener = Task { [weak self] in
                for await update in Transaction.updates {
                    guard !Task.isCancelled, let self else { break }
                    if case .verified(let transaction) = update,
                       VeckaProduct(rawValue: transaction.productID) != nil {
                        self.unfinished[transaction.id] = transaction
                        continuation.yield(())
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in listener.cancel() }
        }
    }
}
