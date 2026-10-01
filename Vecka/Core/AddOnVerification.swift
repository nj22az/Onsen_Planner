import StoreKit

/// Reads StoreKit's local verified transactions, never a shared preferences Boolean.
enum AddOnVerifier {
    static func current() async -> AddOnVerification {
        let known = Set(AddOnProduct.allCases.map(\.rawValue))
        var result = AddOnVerification()
        for await verification in Transaction.currentEntitlements {
            switch verification {
            case .verified(let transaction):
                guard known.contains(transaction.productID), transaction.productType == .nonConsumable,
                      transaction.revocationDate == nil else { continue }
                result.owned.insert(transaction.productID)
            case .unverified(let transaction, _):
                if known.contains(transaction.productID) { result.uncertain.insert(transaction.productID) }
            }
        }
        return result
    }
}
