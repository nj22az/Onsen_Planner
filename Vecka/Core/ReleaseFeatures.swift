import Foundation

/// Change these only after completing docs/RELEASE_CHECKLIST.md.
/// They are build-time decisions, never remote flags or restored preferences.
enum ReleaseFeatures {
    static let cloudSyncEnabled = false
    static let proSalesEnabled = false

    // Published with the application source; update when data handling changes.
    static let privacyPolicyURL = URL(string: "https://github.com/nj22az/Onsen_Planner/blob/main/docs/PRIVACY.md")
}
