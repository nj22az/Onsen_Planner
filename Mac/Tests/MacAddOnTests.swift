import XCTest
@testable import OnsenPlannerMac

@MainActor
private final class MacFakeStore: AddOnStoreClient {
    var verification = AddOnVerification()
    var result: AddOnPurchaseResult = .pending
    var purchaseCalls = 0
    func loadProducts() async throws -> [AddOnOffering] { [AddOnOffering(id: AddOnProduct.widgetStudio.rawValue, displayPrice: "49 kr")] }
    func verify() async -> AddOnVerification { verification }
    func purchase(id: String) async throws -> AddOnPurchaseResult { purchaseCalls += 1; return result }
    func restore() async throws {}
    func finish(ownedIDs: Set<String>) async {}
    func updates() -> AsyncStream<Void> { AsyncStream { $0.finish() } }
}
@MainActor
final class MacAddOnTests: XCTestCase {
    func testDisabledSalesCannotChargeAndUnsignedOwnershipCannotGrantAccess() async {
        let client = MacFakeStore()
        let store = AddOnStore(client: client, salesEnabled: false, listenForUpdates: false)
        client.verification.uncertain = [AddOnProduct.widgetStudio.rawValue]
        await store.refresh()
        await store.loadProducts()
        await store.buy(.widgetStudio)
        XCTAssertFalse(store.owns(.widgetStudio))
        XCTAssertEqual(client.purchaseCalls, 0)
    }
    func testPendingPurchaseCannotRepeatAndVerifiedRevocationRemovesAccess() async {
        let client = MacFakeStore()
        let store = AddOnStore(client: client, salesEnabled: true, listenForUpdates: false)
        await store.refresh()
        await store.loadProducts()
        await store.buy(.widgetStudio)
        await store.buy(.widgetStudio)
        XCTAssertEqual(client.purchaseCalls, 1)
        client.verification.owned = [AddOnProduct.widgetStudio.rawValue]
        await store.refresh()
        XCTAssertTrue(store.owns(.widgetStudio))
        client.verification = AddOnVerification()
        await store.refresh()
        XCTAssertFalse(store.owns(.widgetStudio))
    }
}
