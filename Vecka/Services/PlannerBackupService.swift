import Foundation
import SwiftData

enum PlannerBackupError: LocalizedError {
    case unsupportedVersion, tooLarge, duplicateRecords, invalidRule

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: return "This backup needs a newer version of Onsen Planner. Nothing was changed."
        case .tooLarge: return "This backup is too large to open on this device. Nothing was changed."
        case .duplicateRecords: return "This backup contains conflicting record identifiers. Nothing was changed."
        case .invalidRule: return "This backup contains an invalid holiday rule. Nothing was changed."
        }
    }
}

@MainActor
enum PlannerBackupService {
    static let maximumBytes = 100 * 1024 * 1024

    static func encode(context: ModelContext, defaults: UserDefaults = .standard) throws -> Data {
        try context.save()
        let backup = try PlannerBackup(context: context, defaults: defaults)
        try validate(backup)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(backup)
        guard data.count <= maximumBytes else { throw PlannerBackupError.tooLarge }
        return data
    }

    static func decode(_ data: Data) throws -> PlannerBackup {
        guard data.count <= maximumBytes else { throw PlannerBackupError.tooLarge }
        // Check the version before decoding any version-dependent record shape.
        struct Header: Decodable { let formatVersion: Int }
        guard try JSONDecoder().decode(Header.self, from: data).formatVersion == 1 else {
            throw PlannerBackupError.unsupportedVersion
        }
        let backup = try JSONDecoder().decode(PlannerBackup.self, from: data)
        try validate(backup)
        return backup
    }

    static func read(_ url: URL) throws -> PlannerBackup {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        if let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > maximumBytes {
            throw PlannerBackupError.tooLarge
        }
        return try decode(Data(contentsOf: url))
    }

    static func validate(_ backup: PlannerBackup) throws {
        guard backup.formatVersion == 1 else { throw PlannerBackupError.unsupportedVersion }
        func unique<T: Hashable>(_ ids: [T]) throws {
            guard Set(ids).count == ids.count else { throw PlannerBackupError.duplicateRecords }
        }
        try unique(backup.memos.map(\.id))
        try unique(backup.contacts.map(\.id))
        try unique(backup.holidays.map(\.id))
        try unique(backup.holidayHistory.map(\.id))
        try unique(backup.calendarRules.map(\.id))
        try unique(backup.clocks.map(\.id))
        try unique(backup.quirkyFacts.map(\.id))
        try unique(backup.calendarFacts.map(\.id))
        try unique(backup.contacts.flatMap { $0.phoneNumbers.map(\.id) })
        try unique(backup.contacts.flatMap { $0.emailAddresses.map(\.id) })
        try unique(backup.contacts.flatMap { $0.postalAddresses.map(\.id) })
        try unique(backup.contacts.flatMap { $0.dates.map(\.id) })
        try unique(backup.contacts.flatMap { $0.socialProfiles.map(\.id) })
        try unique(backup.contacts.flatMap { $0.urlAddresses.map(\.id) })
        try unique(backup.contacts.flatMap { $0.relations.map(\.id) })
        for rule in backup.holidays where rule.makeModel().validationError != nil {
            throw PlannerBackupError.invalidRule
        }
    }

    /// Add missing records only. Existing records are never overwritten/deleted.
    /// A separate context and one save keep failed imports out of the live UI.
    @discardableResult
    static func restore(_ backup: PlannerBackup, into container: ModelContainer,
                        defaults: UserDefaults = .standard) throws -> Int {
        try validate(backup)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        var inserted = 0
        func insertMissing<T: PersistentModel, ID: Hashable, Record>(
            _ records: [Record], id: (Record) -> ID, modelID: (T) -> ID,
            make: (Record) -> T
        ) throws {
            var existing = Set(try context.fetch(FetchDescriptor<T>()).map(modelID))
            for record in records where existing.insert(id(record)).inserted {
                context.insert(make(record))
                inserted += 1
            }
        }
        do {
            try insertMissing(backup.contacts, id: { $0.id }, modelID: { (m: Contact) in m.id }, make: { $0.makeModel() })
            try insertMissing(backup.memos, id: { $0.id }, modelID: { (m: Memo) in m.id }, make: { $0.makeModel() })
            try insertMissing(backup.holidays, id: { $0.id }, modelID: { (m: HolidayRule) in m.id }, make: { $0.makeModel() })
            try insertMissing(backup.holidayHistory, id: { $0.id }, modelID: { (m: HolidayChangeLog) in m.id }, make: { $0.makeModel() })
            try insertMissing(backup.calendarRules, id: { $0.id }, modelID: { (m: CalendarRule) in m.id }, make: { $0.makeModel() })
            try insertMissing(backup.clocks, id: { $0.id }, modelID: { (m: WorldClock) in m.id }, make: { $0.makeModel() })
            try insertMissing(backup.quirkyFacts, id: { $0.id }, modelID: { (m: QuirkyFact) in m.id }, make: { $0.makeModel() })
            try insertMissing(backup.calendarFacts, id: { $0.id }, modelID: { (m: CalendarFact) in m.id }, make: { $0.makeModel() })

            var countdowns: [CustomCountdown] = []
            if let data = defaults.data(forKey: "customCountdowns") {
                countdowns = try JSONDecoder().decode([CustomCountdown].self, from: data)
            }
            for event in backup.countdowns where !countdowns.contains(event) { countdowns.append(event) }
            // Perform every fallible conversion before committing any records.
            let countdownData = try JSONEncoder().encode(countdowns)
            try context.save()
            defaults.set(countdownData, forKey: "customCountdowns")
        } catch {
            context.rollback()
            throw error
        }
        HolidayManager.shared.calculateAndCacheHolidays(context: container.mainContext)
        NotificationCenter.default.post(name: .plannerBackupRestored, object: nil)
        return inserted
    }
}

extension Notification.Name {
    static let plannerBackupRestored = Notification.Name("plannerBackupRestored")
}
