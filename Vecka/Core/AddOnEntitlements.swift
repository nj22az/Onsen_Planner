import Foundation

/// Product IDs are independent of legacy planner Pro. No persisted flag grants access.
enum AddOnProduct: String, CaseIterable, Sendable {
    case widgetStudio = "Johansson.Vecka.addon.widgetstudio"
}

struct AddOnVerification: Equatable, Sendable {
    var owned: Set<String> = []
    var uncertain: Set<String> = []
}

struct AddOnEntitlements: Equatable, Sendable {
    private(set) var owned: Set<String> = []
    mutating func reconcile(_ result: AddOnVerification, knownIDs: Set<String>) {
        // Preserve only this session's verified access for a specifically uncertain product.
        owned = result.owned.intersection(knownIDs).union(owned.intersection(result.uncertain).intersection(knownIDs))
    }
    func contains(_ product: AddOnProduct) -> Bool { owned.contains(product.rawValue) }
}
