import XCTest
import SwiftData
@testable import Vecka

@MainActor
final class StorageRecoveryTests: XCTestCase {
    private func memoryContainer() throws -> ModelContainer {
        let schema = AppPersistence.schema
        return try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        ])
    }

    func testBackupRoundTripPreservesPhotosContactGraphAndLinkedMemo() throws {
        let source = try memoryContainer()
        let contact = Contact(givenName: "Test", familyName: "Person")
        contact.phoneNumberItems = [ContactPhoneNumber(label: "mobile", value: "123")]
        contact.dateItems = [ContactDate(label: "anniversary", value: Date(timeIntervalSince1970: 100))]
        contact.imageData = Data([4, 5, 6])
        source.mainContext.insert(contact)
        let memo = Memo.expense("Receipt", amount: 35, currency: "SEK")
        memo.linkedContactID = contact.id
        memo.photoData = Data([1, 2, 3])
        source.mainContext.insert(memo)
        source.mainContext.insert(CalendarFact(id: "backup-fact", type: "static", condition: "always",
                                               textTemplate: "Week {weekOfYear}", icon: "calendar",
                                               colorSemantic: "purple", explanation: "Test template"))
        let suite = "backup-test-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try JSONEncoder().encode([CustomCountdown(name: "Travel", date: Date(), isAnnual: false)]), forKey: "customCountdowns")
        let data = try PlannerBackupService.encode(context: source.mainContext, defaults: defaults)
        let backup = try PlannerBackupService.decode(data)
        let target = try memoryContainer()
        try PlannerBackupService.restore(backup, into: target, defaults: defaults)
        let restored = try XCTUnwrap(target.mainContext.fetch(FetchDescriptor<Memo>()).first)
        XCTAssertEqual(restored.id, memo.id)
        XCTAssertEqual(restored.linkedContactID, contact.id)
        XCTAssertEqual(restored.photoData, memo.photoData)
        XCTAssertEqual(restored.amount, 35)
        let restoredContact = try XCTUnwrap(target.mainContext.fetch(FetchDescriptor<Contact>()).first)
        XCTAssertEqual(restoredContact.phoneNumberItems.first?.value, "123")
        XCTAssertEqual(restoredContact.phoneNumberItems.first?.contact?.id, restoredContact.id)
        XCTAssertEqual(restoredContact.dateItems.count, 1)
        XCTAssertEqual(restoredContact.imageData, contact.imageData)
        XCTAssertEqual(backup.countdowns.count, 1)
        XCTAssertEqual(try target.mainContext.fetch(FetchDescriptor<CalendarFact>()).first?.textTemplate,
                       "Week {weekOfYear}")
    }

    func testRestoreIsRepeatableAndNeverOverwritesExistingEdits() throws {
        let container = try memoryContainer()
        let memo = Memo(text: "Original")
        container.mainContext.insert(memo)
        let backup = try PlannerBackupService.decode(PlannerBackupService.encode(context: container.mainContext))
        memo.text = "Newer edit"
        try container.mainContext.save()
        XCTAssertEqual(try PlannerBackupService.restore(backup, into: container), 0)
        XCTAssertEqual(try PlannerBackupService.restore(backup, into: container), 0)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<Memo>()), 1)
        XCTAssertEqual(memo.text, "Newer edit")
    }

    func testInvalidBackupIsRejectedBeforeAnyRestore() throws {
        XCTAssertThrowsError(try PlannerBackupService.decode(Data("{\"formatVersion\":99}".utf8)))
        XCTAssertThrowsError(try PlannerBackupService.decode(Data("broken".utf8)))
        let container = try memoryContainer()
        container.mainContext.insert(Memo(text: "Keep"))
        let data = try PlannerBackupService.encode(context: container.mainContext)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let memos = try XCTUnwrap(json["memos"] as? [[String: Any]])
        json["memos"] = memos + memos
        XCTAssertThrowsError(try PlannerBackupService.decode(JSONSerialization.data(withJSONObject: json)))
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<Memo>()), 1)
    }

    func testNilContactRelationshipsAreSafeToReadAndEdit() throws {
        let container = try memoryContainer()
        let contact = Contact()
        contact.phoneNumbers = nil
        contact.emailAddresses = nil
        contact.postalAddresses = nil
        contact.dates = nil
        contact.socialProfiles = nil
        contact.urlAddresses = nil
        contact.relations = nil
        container.mainContext.insert(contact)
        XCTAssertTrue(contact.phoneNumberItems.isEmpty)
        XCTAssertTrue(contact.toVCard().contains("BEGIN:VCARD"))
        contact.phoneNumberItems.append(ContactPhoneNumber(label: "home", value: "456"))
        try container.mainContext.save()
        XCTAssertEqual(contact.phoneNumberItems.first?.contact?.id, contact.id)
    }

    func testOpeningFailurePreservesFilesAndNeverCreatesMemoryStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("default.store")
        let original = Data("unreadable-store-do-not-delete".utf8)
        try original.write(to: url)
        let suite = "storage-test-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var attempts: [URL] = []
        let persistence = AppPersistence(defaults: defaults, storeURL: url, cloudEnabled: true) { configuration in
            XCTAssertFalse(configuration.isStoredInMemoryOnly)
            attempts.append(configuration.url)
            throw CocoaError(.fileReadCorruptFile)
        }
        persistence.open()
        XCTAssertNil(persistence.container)
        XCTAssertNotNil(persistence.errorMessage)
        XCTAssertEqual(attempts, [url, url])
        XCTAssertEqual(try Data(contentsOf: url), original)
        let copy = directory.appendingPathComponent("PlannerRecovery")
            .appendingPathComponent(StoreCheckpoint.schemaRevision + "-default.store")
            .appendingPathComponent("default.store")
        XCTAssertEqual(try Data(contentsOf: copy), original)
    }

    func testSavedDataSurvivesContainerReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let schema = AppPersistence.schema
        let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("planner.store"), cloudKitDatabase: .none)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            container.mainContext.insert(Memo(text: "Saved before closing"))
            try container.mainContext.save()
        }
        let reopened = try ModelContainer(for: schema, configurations: [config])
        XCTAssertEqual(try reopened.mainContext.fetch(FetchDescriptor<Memo>()).first?.text, "Saved before closing")
    }
}
