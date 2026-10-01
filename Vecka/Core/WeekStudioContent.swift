import SwiftUI
import AppIntents

/// Parameters are stored per widget by WidgetKit, separately from the app presentation.
enum WeekStudioLayout: String, AppEnum {
    case editorial, minimal
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "week.studio_layout"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .editorial: "week.studio_editorial", .minimal: "week.studio_minimal"
    ]
}

enum WeekStudioColour: String, AppEnum {
    case blue, burgundy, teal, charcoal
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "week.studio_colour"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .blue: "week.studio_blue", .burgundy: "week.studio_burgundy",
        .teal: "week.studio_teal", .charcoal: "week.studio_charcoal"
    ]
    var appearance: WeekAppearance {
        switch self {
        case .blue: return .apple
        case .burgundy: return .muji
        case .teal: return .note
        case .charcoal: return .kinto
        }
    }
}

struct WeekStudioContent: View {
    let date: Date
    let layout: WeekStudioLayout
    var showDate = true
    var showYear = true
    var compact = false
    private var week: ISOWeek { ISOWeekCalendar.week(for: date) }
    var body: some View {
        Group {
            switch layout {
            case .editorial:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("week.short").font(.caption).foregroundStyle(.secondary)
                            number
                        }
                        if !compact { VStack(alignment: .leading, spacing: 8) { metadata } }
                    }
                    if compact { metadata }
                }
            case .minimal:
                VStack(spacing: 8) { number; Text("week.number_label").font(.caption); metadata }
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: layout == .minimal ? .center : .leading)
        .accessibilityElement(children: .combine)
    }
    private var number: some View {
        Text(week.number, format: .number.grouping(.never))
            .font(.system(size: compact ? 58 : 64, weight: layout == .minimal ? .regular : .semibold,
                          design: layout == .minimal ? .serif : .default))
            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6).foregroundStyle(.tint)
    }
    @ViewBuilder private var metadata: some View {
        if showDate {
            Text(verbatim: week.start.formatted(.dateTime.month(.abbreviated).day()) + " – " + week.end.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption).fixedSize(horizontal: false, vertical: true)
        }
        if showYear { Text("week.iso_year \(String(week.year))").font(.caption2).foregroundStyle(.secondary) }
    }
}
