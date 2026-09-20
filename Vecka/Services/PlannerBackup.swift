import Foundation
import SwiftData

/// Portable, versioned user-data snapshot. StoreKit state is never exported.
/// Scalar fields are explicit so schema changes require a reviewed backup change.
struct PlannerBackup: Codable {
    let formatVersion: Int
    let createdAt: Date
    let memos: [MemoBackupRecord]
    let contacts: [ContactBackupRecord]
    let holidays: [HolidayRuleBackupRecord]
    let holidayHistory: [HolidayChangeLogBackupRecord]
    let calendarRules: [CalendarRuleBackupRecord]
    let clocks: [WorldClockBackupRecord]
    let quirkyFacts: [QuirkyFactBackupRecord]
    let calendarFacts: [CalendarFactBackupRecord]
    let countdowns: [CustomCountdown]

    @MainActor
    init(context: ModelContext, defaults: UserDefaults = .standard) throws {
        formatVersion = 1
        createdAt = Date()
        memos = try context.fetch(FetchDescriptor<Memo>()).map(MemoBackupRecord.init)
        contacts = try context.fetch(FetchDescriptor<Contact>()).map(ContactBackupRecord.init)
        holidays = try context.fetch(FetchDescriptor<HolidayRule>()).map(HolidayRuleBackupRecord.init)
        holidayHistory = try context.fetch(FetchDescriptor<HolidayChangeLog>()).map(HolidayChangeLogBackupRecord.init)
        calendarRules = try context.fetch(FetchDescriptor<CalendarRule>()).map(CalendarRuleBackupRecord.init)
        clocks = try context.fetch(FetchDescriptor<WorldClock>()).map(WorldClockBackupRecord.init)
        quirkyFacts = try context.fetch(FetchDescriptor<QuirkyFact>()).map(QuirkyFactBackupRecord.init)
        calendarFacts = try context.fetch(FetchDescriptor<CalendarFact>()).map(CalendarFactBackupRecord.init)
        if let data = defaults.data(forKey: "customCountdowns") {
            countdowns = try JSONDecoder().decode([CustomCountdown].self, from: data)
        } else {
            countdowns = []
        }
    }
}

struct MemoBackupRecord: Codable {
    let id: UUID
    let text: String
    let date: Date
    let priorityRaw: String?
    let createdAt: Date
    let memoTypeRaw: String?
    let amount: Double?
    let currency: String?
    let place: String?
    let person: String?
    let linkedContactID: UUID?
    let scheduledAt: Date?
    let duration: TimeInterval?
    let symbolName: String?
    let pinnedToDashboard: Bool?
    let color: String?
    let photoData: Data?
    let isCountdown: Bool?
    let isSystemCountdown: Bool?
    let tripEndDate: Date?
    let tripPurpose: String?

    @MainActor
    init(_ model: Memo) {
        id = model.id
        text = model.text
        date = model.date
        priorityRaw = model.priorityRaw
        createdAt = model.createdAt
        memoTypeRaw = model.memoTypeRaw
        amount = model.amount
        currency = model.currency
        place = model.place
        person = model.person
        linkedContactID = model.linkedContactID
        scheduledAt = model.scheduledAt
        duration = model.duration
        symbolName = model.symbolName
        pinnedToDashboard = model.pinnedToDashboard
        color = model.color
        photoData = model.photoData
        isCountdown = model.isCountdown
        isSystemCountdown = model.isSystemCountdown
        tripEndDate = model.tripEndDate
        tripPurpose = model.tripPurpose
    }

    @MainActor
    func makeModel() -> Memo {
        let model = Memo(text: text, date: date)
        model.id = id
        model.text = text
        model.date = date
        model.priorityRaw = priorityRaw
        model.createdAt = createdAt
        model.memoTypeRaw = memoTypeRaw
        model.amount = amount
        model.currency = currency
        model.place = place
        model.person = person
        model.linkedContactID = linkedContactID
        model.scheduledAt = scheduledAt
        model.duration = duration
        model.symbolName = symbolName
        model.pinnedToDashboard = pinnedToDashboard
        model.color = color
        model.photoData = photoData
        model.isCountdown = isCountdown
        model.isSystemCountdown = isSystemCountdown
        model.tripEndDate = tripEndDate
        model.tripPurpose = tripPurpose
        return model
    }
}

struct ContactBackupRecord: Codable {
    let id: UUID
    let createdAt: Date
    let modifiedAt: Date
    let givenName: String
    let familyName: String
    let middleName: String?
    let namePrefix: String?
    let nameSuffix: String?
    let nickname: String?
    let organizationName: String?
    let departmentName: String?
    let jobTitle: String?
    let phoneNumbers: [ContactPhoneNumberBackupRecord]
    let emailAddresses: [ContactEmailAddressBackupRecord]
    let postalAddresses: [ContactPostalAddressBackupRecord]
    let birthday: Date?
    let birthdayKnown: Bool
    let dates: [ContactDateBackupRecord]
    let socialProfiles: [ContactSocialProfileBackupRecord]
    let urlAddresses: [ContactURLBackupRecord]
    let note: String?
    let imageData: Data?
    let symbolName: String?
    let relations: [ContactRelationBackupRecord]
    let cnContactIdentifier: String?
    let groupRawValue: String

    @MainActor
    init(_ model: Contact) {
        id = model.id
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
        givenName = model.givenName
        familyName = model.familyName
        middleName = model.middleName
        namePrefix = model.namePrefix
        nameSuffix = model.nameSuffix
        nickname = model.nickname
        organizationName = model.organizationName
        departmentName = model.departmentName
        jobTitle = model.jobTitle
        phoneNumbers = (model.phoneNumbers ?? []).map(ContactPhoneNumberBackupRecord.init)
        emailAddresses = (model.emailAddresses ?? []).map(ContactEmailAddressBackupRecord.init)
        postalAddresses = (model.postalAddresses ?? []).map(ContactPostalAddressBackupRecord.init)
        birthday = model.birthday
        birthdayKnown = model.birthdayKnown
        dates = (model.dates ?? []).map(ContactDateBackupRecord.init)
        socialProfiles = (model.socialProfiles ?? []).map(ContactSocialProfileBackupRecord.init)
        urlAddresses = (model.urlAddresses ?? []).map(ContactURLBackupRecord.init)
        note = model.note
        imageData = model.imageData
        symbolName = model.symbolName
        relations = (model.relations ?? []).map(ContactRelationBackupRecord.init)
        cnContactIdentifier = model.cnContactIdentifier
        groupRawValue = model.groupRawValue
    }

    @MainActor
    func makeModel() -> Contact {
        let model = Contact(givenName: givenName, familyName: familyName)
        model.id = id
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        model.givenName = givenName
        model.familyName = familyName
        model.middleName = middleName
        model.namePrefix = namePrefix
        model.nameSuffix = nameSuffix
        model.nickname = nickname
        model.organizationName = organizationName
        model.departmentName = departmentName
        model.jobTitle = jobTitle
        model.phoneNumbers = phoneNumbers.map { $0.makeModel() }
        model.emailAddresses = emailAddresses.map { $0.makeModel() }
        model.postalAddresses = postalAddresses.map { $0.makeModel() }
        model.birthday = birthday
        model.birthdayKnown = birthdayKnown
        model.dates = dates.map { $0.makeModel() }
        model.socialProfiles = socialProfiles.map { $0.makeModel() }
        model.urlAddresses = urlAddresses.map { $0.makeModel() }
        model.note = note
        model.imageData = imageData
        model.symbolName = symbolName
        model.relations = relations.map { $0.makeModel() }
        model.cnContactIdentifier = cnContactIdentifier
        model.groupRawValue = groupRawValue
        return model
    }
}

struct ContactPhoneNumberBackupRecord: Codable {
    let id: UUID
    let label: String
    let value: String

    @MainActor
    init(_ model: ContactPhoneNumber) {
        id = model.id
        label = model.label
        value = model.value
    }

    @MainActor
    func makeModel() -> ContactPhoneNumber {
        let model = ContactPhoneNumber(label: label, value: value)
        model.id = id
        model.label = label
        model.value = value
        return model
    }
}

struct ContactEmailAddressBackupRecord: Codable {
    let id: UUID
    let label: String
    let value: String

    @MainActor
    init(_ model: ContactEmailAddress) {
        id = model.id
        label = model.label
        value = model.value
    }

    @MainActor
    func makeModel() -> ContactEmailAddress {
        let model = ContactEmailAddress(label: label, value: value)
        model.id = id
        model.label = label
        model.value = value
        return model
    }
}

struct ContactPostalAddressBackupRecord: Codable {
    let id: UUID
    let label: String
    let street: String
    let city: String
    let state: String
    let postalCode: String
    let country: String
    let isoCountryCode: String

    @MainActor
    init(_ model: ContactPostalAddress) {
        id = model.id
        label = model.label
        street = model.street
        city = model.city
        state = model.state
        postalCode = model.postalCode
        country = model.country
        isoCountryCode = model.isoCountryCode
    }

    @MainActor
    func makeModel() -> ContactPostalAddress {
        let model = ContactPostalAddress(label: label)
        model.id = id
        model.label = label
        model.street = street
        model.city = city
        model.state = state
        model.postalCode = postalCode
        model.country = country
        model.isoCountryCode = isoCountryCode
        return model
    }
}

struct ContactDateBackupRecord: Codable {
    let id: UUID
    let label: String
    let value: Date

    @MainActor
    init(_ model: ContactDate) {
        id = model.id
        label = model.label
        value = model.value
    }

    @MainActor
    func makeModel() -> ContactDate {
        let model = ContactDate(label: label, value: value)
        model.id = id
        model.label = label
        model.value = value
        return model
    }
}

struct ContactSocialProfileBackupRecord: Codable {
    let id: UUID
    let label: String
    let service: String
    let username: String
    let url: String?

    @MainActor
    init(_ model: ContactSocialProfile) {
        id = model.id
        label = model.label
        service = model.service
        username = model.username
        url = model.url
    }

    @MainActor
    func makeModel() -> ContactSocialProfile {
        let model = ContactSocialProfile(label: label, service: service, username: username)
        model.id = id
        model.label = label
        model.service = service
        model.username = username
        model.url = url
        return model
    }
}

struct ContactURLBackupRecord: Codable {
    let id: UUID
    let label: String
    let value: String

    @MainActor
    init(_ model: ContactURL) {
        id = model.id
        label = model.label
        value = model.value
    }

    @MainActor
    func makeModel() -> ContactURL {
        let model = ContactURL(label: label, value: value)
        model.id = id
        model.label = label
        model.value = value
        return model
    }
}

struct ContactRelationBackupRecord: Codable {
    let id: UUID
    let label: String
    let name: String

    @MainActor
    init(_ model: ContactRelation) {
        id = model.id
        label = model.label
        name = model.name
    }

    @MainActor
    func makeModel() -> ContactRelation {
        let model = ContactRelation(label: label, name: name)
        model.id = id
        model.label = label
        model.name = name
        return model
    }
}

struct HolidayRuleBackupRecord: Codable {
    let id: String
    let name: String
    let region: String
    let isBankHoliday: Bool
    let titleOverride: String?
    let symbolName: String?
    let iconColor: String?
    let userModifiedAt: Date?
    let notes: String?
    let localName: String?
    let isSystemDefault: Bool
    let isEnabled: Bool
    let originalDefaultJSON: String?
    let type: HolidayRuleType
    let month: Int?
    let day: Int?
    let daysOffset: Int?
    let weekday: Int?
    let ordinal: Int?
    let dayRangeStart: Int?
    let dayRangeEnd: Int?

    @MainActor
    init(_ model: HolidayRule) {
        id = model.id
        name = model.name
        region = model.region
        isBankHoliday = model.isBankHoliday
        titleOverride = model.titleOverride
        symbolName = model.symbolName
        iconColor = model.iconColor
        userModifiedAt = model.userModifiedAt
        notes = model.notes
        localName = model.localName
        isSystemDefault = model.isSystemDefault
        isEnabled = model.isEnabled
        originalDefaultJSON = model.originalDefaultJSON
        type = model.type
        month = model.month
        day = model.day
        daysOffset = model.daysOffset
        weekday = model.weekday
        ordinal = model.ordinal
        dayRangeStart = model.dayRangeStart
        dayRangeEnd = model.dayRangeEnd
    }

    @MainActor
    func makeModel() -> HolidayRule {
        let model = HolidayRule(name: name, region: region, isBankHoliday: isBankHoliday, type: type, month: month, day: day, daysOffset: daysOffset, weekday: weekday, ordinal: ordinal, dayRangeStart: dayRangeStart, dayRangeEnd: dayRangeEnd)
        model.id = id
        model.name = name
        model.region = region
        model.isBankHoliday = isBankHoliday
        model.titleOverride = titleOverride
        model.symbolName = symbolName
        model.iconColor = iconColor
        model.userModifiedAt = userModifiedAt
        model.notes = notes
        model.localName = localName
        model.isSystemDefault = isSystemDefault
        model.isEnabled = isEnabled
        model.originalDefaultJSON = originalDefaultJSON
        model.type = type
        model.month = month
        model.day = day
        model.daysOffset = daysOffset
        model.weekday = weekday
        model.ordinal = ordinal
        model.dayRangeStart = dayRangeStart
        model.dayRangeEnd = dayRangeEnd
        return model
    }
}

struct HolidayChangeLogBackupRecord: Codable {
    let id: UUID
    let timestamp: Date
    let action: HolidayChangeAction
    let source: HolidayChangeSource
    let ruleId: String
    let ruleName: String
    let region: String
    let beforeJSON: String?
    let afterJSON: String?
    let changeDescription: String
    let appVersion: String?
    let notes: String?

    @MainActor
    init(_ model: HolidayChangeLog) {
        id = model.id
        timestamp = model.timestamp
        action = model.action
        source = model.source
        ruleId = model.ruleId
        ruleName = model.ruleName
        region = model.region
        beforeJSON = model.beforeJSON
        afterJSON = model.afterJSON
        changeDescription = model.changeDescription
        appVersion = model.appVersion
        notes = model.notes
    }

    @MainActor
    func makeModel() -> HolidayChangeLog {
        let model = HolidayChangeLog(action: action, source: source, ruleId: ruleId, ruleName: ruleName, region: region, changeDescription: changeDescription)
        model.id = id
        model.timestamp = timestamp
        model.action = action
        model.source = source
        model.ruleId = ruleId
        model.ruleName = ruleName
        model.region = region
        model.beforeJSON = beforeJSON
        model.afterJSON = afterJSON
        model.changeDescription = changeDescription
        model.appVersion = appVersion
        model.notes = notes
        return model
    }
}

struct CalendarRuleBackupRecord: Codable {
    let id: String
    let identifier: String
    let firstWeekday: Int
    let minimumDaysInFirstWeek: Int
    let localeIdentifier: String
    let secondaryCalendarIdentifier: String?
    let isActive: Bool

    @MainActor
    init(_ model: CalendarRule) {
        id = model.id
        identifier = model.identifier
        firstWeekday = model.firstWeekday
        minimumDaysInFirstWeek = model.minimumDaysInFirstWeek
        localeIdentifier = model.localeIdentifier
        secondaryCalendarIdentifier = model.secondaryCalendarIdentifier
        isActive = model.isActive
    }

    @MainActor
    func makeModel() -> CalendarRule {
        let model = CalendarRule(regionCode: id)
        model.id = id
        model.identifier = identifier
        model.firstWeekday = firstWeekday
        model.minimumDaysInFirstWeek = minimumDaysInFirstWeek
        model.localeIdentifier = localeIdentifier
        model.secondaryCalendarIdentifier = secondaryCalendarIdentifier
        model.isActive = isActive
        return model
    }
}

struct WorldClockBackupRecord: Codable {
    let id: UUID
    let cityName: String
    let timezoneIdentifier: String
    let sortOrder: Int
    let dateCreated: Date

    @MainActor
    init(_ model: WorldClock) {
        id = model.id
        cityName = model.cityName
        timezoneIdentifier = model.timezoneIdentifier
        sortOrder = model.sortOrder
        dateCreated = model.dateCreated
    }

    @MainActor
    func makeModel() -> WorldClock {
        let model = WorldClock(cityName: cityName, timezoneIdentifier: timezoneIdentifier)
        model.id = id
        model.cityName = cityName
        model.timezoneIdentifier = timezoneIdentifier
        model.sortOrder = sortOrder
        model.dateCreated = dateCreated
        return model
    }
}

struct QuirkyFactBackupRecord: Codable {
    let id: String
    let region: String
    let category: String
    let text: String
    let explanation: String

    @MainActor
    init(_ model: QuirkyFact) {
        id = model.id
        region = model.region
        category = model.category
        text = model.text
        explanation = model.explanation
    }

    @MainActor
    func makeModel() -> QuirkyFact {
        let model = QuirkyFact(id: id, region: region, category: category, text: text)
        model.id = id
        model.region = region
        model.category = category
        model.text = text
        model.explanation = explanation
        return model
    }
}

struct CalendarFactBackupRecord: Codable {
    let id: String
    let type: String
    let condition: String
    let conditionValue: Int?
    let conditionMin: Int?
    let conditionMax: Int?
    let textTemplate: String
    let icon: String
    let colorSemantic: String
    let explanation: String

    @MainActor
    init(_ model: CalendarFact) {
        id = model.id
        type = model.type
        condition = model.condition
        conditionValue = model.conditionValue
        conditionMin = model.conditionMin
        conditionMax = model.conditionMax
        textTemplate = model.textTemplate
        icon = model.icon
        colorSemantic = model.colorSemantic
        explanation = model.explanation
    }

    @MainActor
    func makeModel() -> CalendarFact {
        let model = CalendarFact(id: id, type: type, condition: condition, textTemplate: textTemplate, icon: icon, colorSemantic: colorSemantic, explanation: explanation)
        model.id = id
        model.type = type
        model.condition = condition
        model.conditionValue = conditionValue
        model.conditionMin = conditionMin
        model.conditionMax = conditionMax
        model.textTemplate = textTemplate
        model.icon = icon
        model.colorSemantic = colorSemantic
        model.explanation = explanation
        return model
    }
}
