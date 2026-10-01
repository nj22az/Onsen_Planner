import XCTest
@testable import Vecka

@MainActor
private final class FakeAddOnClient: AddOnStoreClient {
    let id = AddOnProduct.widgetStudio.rawValue
    var verification = AddOnVerification()
    var result: AddOnPurchaseResult = .cancelled
    var catalogFails = false
    var restoreFails = false
    var purchases = 0
    var finished: [Set<String>] = []
    func loadProducts() async throws -> [AddOnOffering] {
        if catalogFails { throw ProStoreError.unavailable }
        return [AddOnOffering(id: id, displayPrice: "49 kr")]
    }
    func verify() async -> AddOnVerification { verification }
    func purchase(id: String) async throws -> AddOnPurchaseResult {
        purchases += 1
        if case .verified = result { verification.owned.insert(id) }
        return result
    }
    func restore() async throws { if restoreFails { throw ProStoreError.unavailable } }
    func finish(ownedIDs: Set<String>) async { finished.append(ownedIDs) }
    func updates() -> AsyncStream<Void> { AsyncStream { $0.finish() } }
}

@MainActor
final class AddOnStoreTests: XCTestCase {
    func testEntitlementsRemainIndependentAndRejectUnknownIDs() {
        var ledger = AddOnEntitlements()
        ledger.reconcile(AddOnVerification(owned: ["A", "foreign"]), knownIDs: ["A", "B"])
        XCTAssertEqual(ledger.owned, ["A"])
        ledger.reconcile(AddOnVerification(owned: ["B"], uncertain: ["A"]), knownIDs: ["A", "B"])
        XCTAssertEqual(ledger.owned, ["A", "B"])
        ledger.reconcile(AddOnVerification(owned: ["B"]), knownIDs: ["A", "B"])
        XCTAssertEqual(ledger.owned, ["B"])
    }
    func testUnverifiedAccessCannotUnlockOnNewLaunch() {
        var ledger = AddOnEntitlements()
        ledger.reconcile(AddOnVerification(uncertain: ["A"]), knownIDs: ["A"])
        XCTAssertTrue(ledger.owned.isEmpty)
    }
    func testPendingApprovalPreventsDuplicatePurchaseAndLaterUnlocks() async {
        let client = FakeAddOnClient()
        let store = AddOnStore(client: client, salesEnabled: true, listenForUpdates: false)
        await store.refresh()
        await store.loadProducts()
        client.result = .pending
        await store.buy(.widgetStudio)
        await store.buy(.widgetStudio)
        XCTAssertEqual(client.purchases, 1)
        XCTAssertFalse(store.owns(.widgetStudio))
        client.verification.owned = [client.id]
        await store.refresh()
        XCTAssertTrue(store.owns(.widgetStudio))
        XCTAssertTrue(store.pendingIDs.isEmpty)
        XCTAssertFalse(store.canPurchase(.widgetStudio))
    }
    func testCatalogFailureDoesNotRevokeVerifiedOwnership() async {
        let client = FakeAddOnClient()
        client.verification.owned = [client.id]
        let store = AddOnStore(client: client, salesEnabled: true, listenForUpdates: false)
        await store.refresh()
        client.catalogFails = true
        await store.loadProducts()
        XCTAssertTrue(store.owns(.widgetStudio))
        XCTAssertTrue(store.offerings.isEmpty)
    }
    func testVerificationFailureRetainsOnlyThisSessionsVerifiedProduct() async {
        let client = FakeAddOnClient()
        let store = AddOnStore(client: client, salesEnabled: true, listenForUpdates: false)
        client.verification.owned = [client.id]
        await store.refresh()
        client.verification = AddOnVerification(uncertain: [client.id])
        await store.refresh()
        XCTAssertTrue(store.owns(.widgetStudio))
        client.verification = AddOnVerification()
        await store.refresh()
        XCTAssertFalse(store.owns(.widgetStudio))
    }
    func testLegacyProDoesNotGrantNewUnrelatedAddOn() async {
        let client = FakeAddOnClient()
        client.verification.owned = [VeckaProduct.proLifetime.rawValue]
        let store = AddOnStore(client: client, salesEnabled: true, listenForUpdates: false)
        await store.refresh()
        XCTAssertFalse(store.owns(.widgetStudio))
        XCTAssertEqual(client.finished.last, Set<String>())
    }
    func testCancellationCanRetryAndVerifiedPurchaseFinishesOnlyItsProduct() async {
        let client = FakeAddOnClient()
        let store = AddOnStore(client: client, salesEnabled: true, listenForUpdates: false)
        await store.refresh()
        await store.loadProducts()
        await store.buy(.widgetStudio)
        XCTAssertTrue(store.canPurchase(.widgetStudio))
        XCTAssertNil(store.message)
        client.result = .verified
        await store.buy(.widgetStudio)
        XCTAssertTrue(store.owns(.widgetStudio))
        XCTAssertEqual(client.finished.last, [client.id])
    }
    func testRestoreFailurePreservesAccessAndCanRetry() async {
        let client = FakeAddOnClient()
        client.verification.owned = [client.id]
        let store = AddOnStore(client: client, salesEnabled: true, listenForUpdates: false)
        await store.refresh()
        client.restoreFails = true
        await store.restore()
        XCTAssertTrue(store.owns(.widgetStudio))
        XCTAssertNotNil(store.message)
        XCTAssertFalse(store.isBusy)
        client.restoreFails = false
        await store.restore()
        XCTAssertTrue(store.owns(.widgetStudio))
    }
    func testDisabledSalesCannotCharge() async {
        let client = FakeAddOnClient()
        let store = AddOnStore(client: client, salesEnabled: false, listenForUpdates: false)
        await store.refresh()
        await store.loadProducts()
        await store.buy(.widgetStudio)
        XCTAssertEqual(client.purchases, 0)
        XCTAssertTrue(store.offerings.isEmpty)
    }
}
