import XCTest
@testable import Vecka

@MainActor
private final class FakeProStore: ProStoreClient {
    let offering = ProOffering(id: VeckaProduct.proYearly.rawValue, displayName: "Yearly", displayPrice: "100 kr", detail: "100 kr per year")
    var catalogFails = false
    var catalogEmpty = false
    var restoreFails = false
    var entitlement: ProEntitlement = .inactive
    var result: ProPurchaseResult = .cancelled
    var purchaseCalls = 0
    var finishedCalls = 0
    func loadProducts() async throws -> [ProOffering] {
        if catalogFails { throw ProStoreError.unavailable }
        return catalogEmpty ? [] : [offering]
    }
    func currentEntitlement() async -> ProEntitlement { entitlement }
    func purchase(productID: String) async throws -> ProPurchaseResult {
        purchaseCalls += 1
        if case .verified = result { entitlement = .active }
        return result
    }
    func restore() async throws { if restoreFails { throw ProStoreError.unavailable } }
    func finishVerifiedTransactions(accessGranted: Bool) async { finishedCalls += 1 }
    func updates() -> AsyncStream<Void> { AsyncStream { $0.finish() } }
}

@MainActor
final class StoreRecoveryTests: XCTestCase {
    private func manager(_ client: FakeProStore, salesEnabled: Bool = true) -> StoreManager {
        StoreManager(client: client, salesEnabled: salesEnabled, listenForUpdates: false)
    }

    func testUnavailableCatalogCanRetryWithoutRevokingPro() async {
        let client = FakeProStore()
        client.entitlement = .active
        let store = manager(client)
        await store.refreshEntitlements()
        client.catalogFails = true
        await store.loadProducts()
        XCTAssertEqual(store.productState, .unavailable)
        XCTAssertTrue(store.isPro)
        client.catalogFails = false
        await store.loadProducts()
        XCTAssertEqual(store.productState, .ready)
        XCTAssertEqual(store.products.count, 1)
    }

    func testEmptyCatalogCanRecover() async {
        let client = FakeProStore()
        client.catalogEmpty = true
        let store = manager(client)
        await store.refreshEntitlements()
        await store.loadProducts()
        XCTAssertFalse(store.canPurchase)
        client.catalogEmpty = false
        await store.loadProducts()
        XCTAssertTrue(store.canPurchase)
    }

    func testPendingApprovalPreventsRepeatedPurchasesAndLaterUnlocks() async {
        let client = FakeProStore()
        client.result = .pending
        let store = manager(client)
        await store.refreshEntitlements()
        await store.loadProducts()
        let purchased = await store.purchase(client.offering)
        XCTAssertFalse(purchased)
        XCTAssertEqual(store.purchaseState, .pending)
        _ = await store.purchase(client.offering)
        XCTAssertEqual(client.purchaseCalls, 1)
        client.entitlement = .active
        await store.refreshEntitlements()
        XCTAssertTrue(store.isPro)
        XCTAssertEqual(store.purchaseState, .completed)
    }

    func testCancellationAndFailedRestoreHaveDistinctOutcomes() async {
        let client = FakeProStore()
        let store = manager(client)
        await store.refreshEntitlements()
        await store.loadProducts()
        _ = await store.purchase(client.offering)
        XCTAssertEqual(store.purchaseState, .idle)
        XCTAssertNil(store.lastError)
        client.restoreFails = true
        await store.restorePurchases()
        XCTAssertEqual(store.purchaseState, .failed)
        XCTAssertNotNil(store.lastError)
        client.restoreFails = false
        await store.restorePurchases()
        XCTAssertNil(store.lastError)
        XCTAssertNotNil(store.statusMessage)
    }

    func testVerifiedRevocationRemovesAccessButUnavailableVerificationDoesNot() async {
        let client = FakeProStore()
        client.entitlement = .active
        let store = manager(client)
        await store.refreshEntitlements()
        client.entitlement = .unavailable
        await store.refreshEntitlements()
        XCTAssertTrue(store.isPro)
        client.entitlement = .inactive
        await store.refreshEntitlements()
        XCTAssertFalse(store.isPro)
    }

    func testSavedBooleanDoesNotGrantUnverifiedAccess() async throws {
        let suite = "entitlement-test-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "vecka.pro.entitlement")
        let client = FakeProStore()
        client.entitlement = .unavailable
        let store = StoreManager(client: client, defaults: defaults, salesEnabled: true, listenForUpdates: false)
        XCTAssertTrue(store.previouslyHadPro)
        await store.refreshEntitlements()
        XCTAssertFalse(store.isPro)
        XCTAssertFalse(store.canPurchase)
    }

    func testDisabledSalesPreserveFeaturesAndPreventPurchases() async {
        let client = FakeProStore()
        let store = manager(client, salesEnabled: false)
        await store.refreshEntitlements()
        await store.loadProducts()
        XCTAssertTrue(store.canUseProFeatures)
        XCTAssertFalse(store.isPro)
        _ = await store.purchase(client.offering)
        XCTAssertEqual(client.purchaseCalls, 0)
    }
}
