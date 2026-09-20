import Foundation
import SwiftData
import Observation

/// Persistent storage must open successfully before the editable planner mounts.
@MainActor
@Observable
final class AppPersistence {
    private(set) var container: ModelContainer?
    private(set) var errorMessage: String?
    private(set) var isOpening = false
    private(set) var localOnly = true

    static var schema: Schema {
        Schema([
            HolidayRule.self, HolidayChangeLog.self, CalendarRule.self,
            Contact.self, ContactPhoneNumber.self, ContactEmailAddress.self,
            ContactPostalAddress.self, ContactDate.self, ContactSocialProfile.self,
            ContactURL.self, ContactRelation.self, WorldClock.self,
            QuirkyFact.self, CalendarFact.self, Memo.self,
            AppConfiguration.self, ValidationRule.self, AlgorithmParameter.self,
            UITheme.self, TypographyScale.self, SpacingScale.self, IconCatalogItem.self
        ])
    }

    private let defaults: UserDefaults
    private let storeURL: URL
    private let cloudEnabled: Bool
    private let makeContainer: (ModelConfiguration) throws -> ModelContainer
    private static let selectedStoreKey = "planner.recoveredStore"

    init(defaults: UserDefaults = .standard, storeURL: URL? = nil,
         cloudEnabled: Bool = ReleaseFeatures.cloudSyncEnabled,
         makeContainer: ((ModelConfiguration) throws -> ModelContainer)? = nil) {
        self.defaults = defaults
        self.storeURL = storeURL ?? ModelConfiguration(schema: Self.schema, cloudKitDatabase: .none).url
        self.cloudEnabled = cloudEnabled
        self.makeContainer = makeContainer ?? { configuration in
            try ModelContainer(for: Self.schema, configurations: [configuration])
        }
    }

    private var activeURL: URL {
        // Only internally generated filenames are accepted, never arbitrary paths.
        if let filename = defaults.string(forKey: Self.selectedStoreKey),
           filename.hasPrefix("recovered-"), filename.hasSuffix(".store"),
           !filename.contains("/"), !filename.contains("..") {
            return storeURL.deletingLastPathComponent().appendingPathComponent(filename)
        }
        return storeURL
    }

    func open() {
        guard container == nil, !isOpening else { return }
        isOpening = true
        defer { isOpening = false }
        errorMessage = nil
        do {
            // The store is closed here. Preserve SQLite/WAL/attachments before
            // SwiftData attempts this schema upgrade; failure stops the upgrade.
            try StoreCheckpoint.preserveClosedStore(at: activeURL)
            if cloudEnabled {
                do {
                    container = try makeContainer(ModelConfiguration(
                        schema: Self.schema, url: activeURL, cloudKitDatabase: .automatic
                    ))
                    localOnly = false
                    return
                } catch {
                    Log.w("Cloud storage could not open; trying the same store locally.")
                }
            }
            container = try makeContainer(ModelConfiguration(
                schema: Self.schema, url: activeURL, cloudKitDatabase: .none
            ))
            localOnly = true
        } catch {
            Log.e("Persistent storage could not open: \(error.localizedDescription)")
            errorMessage = "Your saved planner could not be opened. Its files have been kept. Retry, or restore a backup into a separate planner."
        }
    }

    /// Recovery never replaces or deletes the failed store. Switch only after
    /// decoding, validating and saving the entire backup in a fresh store.
    func recover(from backup: PlannerBackup) throws {
        guard container == nil else { return }
        try PlannerBackupService.validate(backup)
        let url = storeURL.deletingLastPathComponent()
            .appendingPathComponent("recovered-\(UUID().uuidString).store")
        let recovered = try makeContainer(ModelConfiguration(
            schema: Self.schema, url: url, cloudKitDatabase: .none
        ))
        try PlannerBackupService.restore(backup, into: recovered, defaults: defaults)
        defaults.set(url.lastPathComponent, forKey: Self.selectedStoreKey)
        container = recovered
        localOnly = true
        errorMessage = nil
    }
}

enum StoreCheckpoint {
    // Bump whenever the persisted schema changes, before opening a new version.
    static let schemaRevision = "2026-09-reliability-v1"

    static func preserveClosedStore(at url: URL, fileManager: FileManager = .default) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        let directory = url.deletingLastPathComponent()
        let backup = directory.appendingPathComponent("PlannerRecovery", isDirectory: true)
            .appendingPathComponent(schemaRevision + "-" + url.lastPathComponent, isDirectory: true)
        guard !fileManager.fileExists(atPath: backup.appendingPathComponent("complete").path) else { return }
        let staging = backup.deletingLastPathComponent().appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        do {
            for name in [url.lastPathComponent, url.lastPathComponent + "-wal", url.lastPathComponent + "-shm",
                         "." + url.lastPathComponent + "_SUPPORT", url.lastPathComponent + "_SUPPORT",
                         "." + url.deletingPathExtension().lastPathComponent + "_SUPPORT",
                         url.deletingPathExtension().lastPathComponent + "_SUPPORT"] {
                let source = directory.appendingPathComponent(name)
                if fileManager.fileExists(atPath: source.path) {
                    try fileManager.copyItem(at: source, to: staging.appendingPathComponent(name))
                }
            }
            try Data(schemaRevision.utf8).write(to: staging.appendingPathComponent("complete"), options: .atomic)
            try fileManager.moveItem(at: staging, to: backup)
        } catch {
            try? fileManager.removeItem(at: staging) // Only our incomplete copy.
            throw error
        }
    }
}
