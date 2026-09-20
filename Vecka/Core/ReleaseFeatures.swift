import Foundation

/// Change these only after completing docs/RELEASE_CHECKLIST.md.
/// They are build-time decisions, never remote flags or restored preferences.
enum ReleaseFeatures {
    static let cloudSyncEnabled = false
    static let proSalesEnabled = false

    // Supply the actual hosted policy before enabling Pro sales.
    static let privacyPolicyURL: URL? = nil
}
