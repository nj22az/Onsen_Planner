import Foundation
import Observation
import StoreKit
import WidgetKit

struct AddOnOffering: Identifiable, Equatable {
    let id: String
    let displayPrice: String
}

enum AddOnPurchaseResult { case verified, pending, cancelled }
@MainActor
protocol AddOnStoreClient: AnyObject {
    func loadProducts() async throws -> [AddOnOffering]
    func verify() async -> AddOnVerification
    func purchase(id: String) async throws -> AddOnPurchaseResult
    func restore() async throws
    func finish(ownedIDs: Set<String>) async
    func updates() -> AsyncStream<Void>
}

@MainActor
@Observable
final class AddOnStore {
    private(set) var entitlements = AddOnEntitlements()
    private(set) var offerings: [AddOnOffering] = []
    private(set) var pendingIDs: Set<String> = []
    private(set) var uncertainIDs: Set<String> = []
    private(set) var isBusy = false
    private(set) var checking = true
    private(set) var message: String?
    let salesEnabled: Bool
    @ObservationIgnored private let client: AddOnStoreClient
    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    @ObservationIgnored private var generation = 0
    private var knownIDs: Set<String> { Set(AddOnProduct.allCases.map(\.rawValue)) }

    init(client: AddOnStoreClient? = nil, salesEnabled: Bool = ReleaseFeatures.addOnSalesEnabled,
         listenForUpdates: Bool = true) {
        self.client = client ?? AppleAddOnStoreClient()
        self.salesEnabled = salesEnabled
        if listenForUpdates {
            let updates = self.client.updates()
            updatesTask = Task { [weak self] in
                for await _ in updates {
                    guard !Task.isCancelled else { break }
                    await self?.refresh()
                }
            }
        }
    }
    deinit { updatesTask?.cancel() }
    func owns(_ product: AddOnProduct) -> Bool { entitlements.contains(product) }
    func canPurchase(_ product: AddOnProduct) -> Bool {
        salesEnabled && !checking && !isBusy && !owns(product) &&
        !pendingIDs.contains(product.rawValue) && !uncertainIDs.contains(product.rawValue) &&
        offerings.contains { $0.id == product.rawValue }
    }
    func refresh() async {
        generation &+= 1
        let token = generation
        let verified = await client.verify()
        guard token == generation else { return }
        entitlements.reconcile(verified, knownIDs: knownIDs)
        uncertainIDs = verified.uncertain.intersection(knownIDs)
        pendingIDs.subtract(entitlements.owned)
        checking = false
        await client.finish(ownedIDs: entitlements.owned)
        WidgetCenter.shared.reloadAllTimelines()
    }
    func loadProducts() async {
        guard salesEnabled else { return }
        do {
            offerings = try await client.loadProducts().filter { knownIDs.contains($0.id) }
        } catch {
            offerings = []
            message = String(localized: "week.purchase_unavailable")
        }
    }
    func buy(_ product: AddOnProduct) async {
        guard canPurchase(product) else { return }
        isBusy = true
        message = nil
        defer { isBusy = false }
        do {
            switch try await client.purchase(id: product.rawValue) {
            case .verified:
                pendingIDs.insert(product.rawValue)
                await refresh()
                message = String(localized: owns(product) ? "week.purchase_owned" : "week.purchase_check")
            case .pending:
                pendingIDs.insert(product.rawValue)
                message = String(localized: "week.purchase_pending")
            case .cancelled: break
            }
        } catch {
            message = String(localized: "week.purchase_unavailable")
        }
    }
    func restore() async {
        guard !isBusy else { return }
        isBusy = true
        message = nil
        defer { isBusy = false }
        do {
            try await client.restore()
            await refresh()
            message = String(localized: !uncertainIDs.isEmpty ? "week.purchase_check" : entitlements.owned.isEmpty ? "week.restore_empty" : "week.restore_done")
        } catch { message = String(localized: "week.restore_failed") }
    }
}

@MainActor
final class AppleAddOnStoreClient: AddOnStoreClient {
    private var products: [String: Product] = [:]
    private var unfinished: [UInt64: Transaction] = [:]
    func loadProducts() async throws -> [AddOnOffering] {
        let loaded = try await Product.products(for: AddOnProduct.allCases.map(\.rawValue))
            .filter { $0.type == .nonConsumable }
        products = Dictionary(loaded.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return loaded.map { AddOnOffering(id: $0.id, displayPrice: $0.displayPrice) }
    }
    func verify() async -> AddOnVerification { await AddOnVerifier.current() }
    func purchase(id: String) async throws -> AddOnPurchaseResult {
        guard let product = products[id] else { throw AddOnStoreError.unavailable }
        switch try await product.purchase() {
        case .success(let result):
            guard case .verified(let transaction) = result else { throw AddOnStoreError.unverified }
            unfinished[transaction.id] = transaction
            return .verified
        case .pending: return .pending
        case .userCancelled: return .cancelled
        @unknown default: throw AddOnStoreError.unavailable
        }
    }
    func restore() async throws { try await AppStore.sync() }
    func finish(ownedIDs: Set<String>) async {
        let completed = unfinished
        for (id, transaction) in completed {
            guard ownedIDs.contains(transaction.productID) || transaction.revocationDate != nil else { continue }
            await transaction.finish()
            unfinished.removeValue(forKey: id)
        }
    }
    func updates() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let listener = Task { [weak self] in
                for await result in Transaction.updates {
                    guard !Task.isCancelled, let self else { break }
                    if case .verified(let transaction) = result,
                       AddOnProduct(rawValue: transaction.productID) != nil {
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

enum AddOnStoreError: LocalizedError, Equatable {
    case unavailable, unverified
    var errorDescription: String? {
        String(localized: self == .unavailable ? "week.purchase_unavailable" : "week.purchase_check")
    }
}
