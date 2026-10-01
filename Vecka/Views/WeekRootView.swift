import SwiftUI
import SwiftData
import WidgetKit

/// Week content has no database, permission or purchase dependency.
struct WeekRootView: View {
    let persistence: AppPersistence
    @Environment(NavigationManager.self) private var navigation
    @Environment(AddOnStore.self) private var addOns
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var widthClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage(WeekAppearance.storageKey, store: WeekAppearance.defaults) private var theme = "apple"
    @State private var tab = 0
    @State private var displayedDate: Date?
    @State private var lookupDate = Date()
    @State private var sheet: UtilitySheet?
    @State private var showPlanner = false
    @State private var pendingPlanner = false
    private var appearance: WeekAppearance { WeekAppearance.resolve(theme) }
    private enum UtilitySheet: String, Identifiable {
        case lookup, settings, addOns
        var id: String { rawValue }
    }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    ScrollView {
                        let date = displayedDate ?? context.date
                        if widthClass == .regular && !typeSize.isAccessibilitySize {
                            HStack(alignment: .top, spacing: 32) {
                                weekOverview(date: date, now: context.date).frame(maxWidth: 380)
                                WeekMonthView(date: date, now: context.date) { displayedDate = $0 }
                                    .frame(maxWidth: 520)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: appearance.sectionSpacing) {
                                weekOverview(date: date, now: context.date)
                                WeekMonthView(date: date, now: context.date) { displayedDate = $0 }
                            }
                        }
                    }
                    .contentMargins(20, for: .scrollContent)
                    .navigationTitle("week.title")
                    .navigationBarTitleDisplayMode(.inline)
                    .accessibilityIdentifier("week-home")
                }
                .toolbar { utilityToolbar }
            }
            .tabItem { Label("week.tab", systemImage: "calendar") }.tag(0)
            NavigationStack {
                WidgetGalleryView(appearance: appearance) { sheet = .addOns }
                    .toolbar { utilityToolbar }
            }
            .tabItem { Label("week.widgets", systemImage: "square.grid.2x2") }.tag(1)
        }
        .tint(appearance.tint)
        .task { await addOns.refresh() }
        .onAppear { if WeekAppearance(rawValue: theme) == nil { theme = "apple" } }
        .onChange(of: theme) { _, _ in reloadWidgets() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                reloadWidgets()
                Task { await addOns.refresh() }
            }
        }
        .onChange(of: navigation.shouldNavigateToPage) { _, requested in
            guard requested else { return }
            if navigation.targetPage == .landing && navigation.factIdToShow == nil {
                displayedDate = ISOWeekCalendar.calendar().isDateInToday(navigation.targetDate) ? nil : navigation.targetDate
                tab = 0
                sheet = nil
                showPlanner = false
                navigation.shouldNavigateToPage = false
                navigation.shouldScrollToWeek = false
            } else {
                if sheet != nil { pendingPlanner = true; sheet = nil }
                else { openPlanner() }
            }
        }
        .sheet(item: $sheet, onDismiss: {
            if pendingPlanner { pendingPlanner = false; openPlanner() }
        }) { destination in
            NavigationStack {
                switch destination {
                case .lookup:
                    DateLookupView(date: $lookupDate, appearance: appearance) {
                        displayedDate = lookupDate
                        tab = 0
                        sheet = nil
                    }
                case .settings:
                    settings
                case .addOns:
                    AddOnShopView()
                }
            }
            .tint(appearance.tint)
        }
        .sheet(isPresented: $showPlanner) {
            if let container = persistence.container {
                LegacyPlannerView(container: container)
            } else {
                NavigationStack {
                    StorageRecoveryView(persistence: persistence)
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("week.done") { showPlanner = false } } }
                }
            }
        }
    }

    @ViewBuilder
    private func weekOverview(date: Date, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            WeekHeroView(date: date, appearance: appearance)
            let controls = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 4))
            controls {
                Button("week.previous", systemImage: "chevron.left") { moveWeek(-1) }
                    .frame(maxWidth: .infinity, minHeight: 44).accessibilityIdentifier("previous-week")
                Button("week.today") { displayedDate = nil }
                    .frame(maxWidth: .infinity, minHeight: 44).accessibilityIdentifier("show-today")
                Button("week.next", systemImage: "chevron.right") { moveWeek(1) }
                    .frame(maxWidth: .infinity, minHeight: 44).accessibilityIdentifier("next-week")
            }
            .font(.subheadline)
            .buttonStyle(.borderless)
            WeekDayStrip(week: ISOWeekCalendar.week(for: date), now: now)
        }
    }

    @ToolbarContentBuilder
    private var utilityToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                lookupDate = displayedDate ?? Date()
                sheet = .lookup
            } label: { Label("week.lookup", systemImage: "magnifyingglass") }
            .accessibilityIdentifier("open-date-lookup")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("week.settings", systemImage: "gearshape") { sheet = .settings }
                Button("week.addons", systemImage: "plus.circle") { sheet = .addOns }
            } label: { Label("week.menu", systemImage: "ellipsis.circle") }
            .accessibilityIdentifier("utility-menu")
        }
    }

    private var settings: some View {
        Form {
            Section("week.appearance") {
                Picker("week.theme", selection: $theme) {
                    ForEach(WeekAppearance.allCases) { style in Text(style.localizedTitle).tag(style.rawValue) }
                }
                .pickerStyle(.navigationLink)
                .accessibilityIdentifier("week-theme-picker")
                Text("week.theme_footer").font(.footnote).foregroundStyle(.secondary)
            }
            Section("week.widgets") {
                NavigationLink("week.add_widget") { WidgetSetupView() }
                Button("week.refresh_widgets") { reloadWidgets() }
            }
            Section("week.addons") {
                NavigationLink("week.addons") { AddOnShopView() }
                Button("week.restore") { Task { await addOns.restore() } }
                    .disabled(addOns.isBusy)
                if let message = addOns.message { Text(message).font(.footnote) }
            }
            Section("week.saved_planner") {
                Button("week.open_planner") {
                    pendingPlanner = true
                    sheet = nil
                }
                Text("week.planner_footer").font(.footnote).foregroundStyle(.secondary)
            }
            Section("week.about") {
                Text("week.iso_explanation")
                Text("week.offline").foregroundStyle(.secondary)
                if let policy = ReleaseFeatures.privacyPolicyURL { Link("week.privacy", destination: policy) }
            }
        }
        .navigationTitle("week.settings")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("week.done") { sheet = nil } } }
    }

    private func moveWeek(_ amount: Int) {
        displayedDate = ISOWeekCalendar.calendar().date(byAdding: .weekOfYear, value: amount, to: displayedDate ?? Date()) ?? displayedDate
    }
    private func reloadWidgets() { WidgetCenter.shared.reloadAllTimelines() }
    private func openPlanner() { persistence.open(); showPlanner = true }
}

struct WeekHeroView: View {
    let date: Date
    let appearance: WeekAppearance
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 72
    private var week: ISOWeek { ISOWeekCalendar.week(for: date) }

    var body: some View {
        Group {
            switch appearance {
            case .apple:
                VStack(alignment: .leading, spacing: 8) { label; number; range; year }
            case .muji:
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 24) {
                        number
                        VStack(alignment: .leading, spacing: 8) { label; range; year }
                    }
                    VStack(alignment: .leading, spacing: 12) { label; number; range; year }
                }
            case .note:
                VStack(alignment: .leading, spacing: 12) { range.font(.headline); label; number; year }
            case .kinto:
                VStack(alignment: .center, spacing: 16) { label; number; range; year }
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: appearance == .kinto ? .center : .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("week.widget_label \(week.number)"))
        .accessibilityValue(Text(verbatim: week.start.formatted(.dateTime.month(.wide).day()) + " – " + week.end.formatted(.dateTime.month(.wide).day().year()) + ", " + String(localized: "week.iso_year \(String(week.year))")))
        .accessibilityIdentifier("week-summary")
    }
    private var label: some View { Text("week.number_label").font(.subheadline).foregroundStyle(.secondary) }
    private var number: some View {
        Text(week.number, format: .number.grouping(.never))
            .font(.system(size: numberSize, weight: appearance == .kinto ? .regular : .semibold))
            .monospacedDigit()
            .accessibilityIdentifier("week-number")
    }
    private var range: some View {
        Text(verbatim: week.start.formatted(.dateTime.month(.abbreviated).day()) + " – " + week.end.formatted(.dateTime.month(.abbreviated).day().year()))
            .font(.subheadline).fixedSize(horizontal: false, vertical: true)
    }
    private var year: some View { Text("week.iso_year \(String(week.year))").font(.caption).foregroundStyle(.secondary) }
}

struct WeekDayStrip: View {
    let week: ISOWeek
    let now: Date
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(week.days, id: \.self) { date in
                    HStack {
                        Text(date, format: .dateTime.weekday(.wide).day())
                        if ISOWeekCalendar.calendar().isDate(date, inSameDayAs: now) { Text("week.today").foregroundStyle(.tint) }
                    }
                }
            }
        } else {
            HStack(spacing: 0) {
                ForEach(week.days, id: \.self) { date in
                    let today = ISOWeekCalendar.calendar().isDate(date, inSameDayAs: now)
                    VStack(spacing: 10) {
                        Text(date, format: .dateTime.weekday(.narrow)).font(.caption).foregroundStyle(.secondary)
                        Text(date, format: .dateTime.day()).font(.body.weight(today ? .semibold : .regular))
                        Circle().fill(today ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.clear)).frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(date, format: .dateTime.weekday(.wide).month(.wide).day()))
                    .accessibilityAddTraits(today ? .isSelected : [])
                }
            }
            .padding(.vertical, 12)
        }
    }
}

struct WeekMonthView: View {
    let date: Date
    let now: Date
    var select: ((Date) -> Void)?
    @Environment(\.dynamicTypeSize) private var typeSize
    private var selected: ISOWeek { ISOWeekCalendar.week(for: date) }
    private var calendar: Calendar { ISOWeekCalendar.calendar() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(date, format: .dateTime.month(.wide).year()).font(.headline)
            if !typeSize.isAccessibilitySize {
                HStack(spacing: 0) {
                    Text("week.short").frame(maxWidth: .infinity)
                    ForEach(selected.days, id: \.self) { day in
                        Text(day, format: .dateTime.weekday(.narrow)).frame(maxWidth: .infinity)
                    }
                }
                .font(.caption).foregroundStyle(.secondary).accessibilityHidden(true)
            }
            ForEach(ISOWeekCalendar.monthWeeks(for: date), id: \.start) { week in
                Button {
                    select?(week.days.first { calendar.isDate($0, equalTo: date, toGranularity: .month) } ?? week.start)
                } label: {
                    if typeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("week.widget_label \(week.number)").font(.headline)
                            Text(verbatim: week.start.formatted(.dateTime.month(.abbreviated).day()) + " – " + week.end.formatted(.dateTime.month(.abbreviated).day()))
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                    } else {
                        HStack(spacing: 0) {
                            Text(week.number, format: .number.grouping(.never)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                            ForEach(week.days, id: \.self) { day in
                                Text(day, format: .dateTime.day())
                                    .fontWeight(calendar.isDate(day, inSameDayAs: now) ? .bold : .regular)
                                    .opacity(calendar.isDate(day, equalTo: date, toGranularity: .month) ? 1 : 0.4)
                                    .frame(maxWidth: .infinity)
                            }
                        }.font(.subheadline).monospacedDigit().frame(minHeight: 44)
                    }
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .background(week.start == selected.start ? Color.accentColor.opacity(0.08) : Color.clear)
                .accessibilityLabel(Text("week.widget_label \(week.number)"))
                .accessibilityValue(Text(verbatim: week.start.formatted(.dateTime.month(.wide).day()) + " – " + week.end.formatted(.dateTime.month(.wide).day())))
                .accessibilityAddTraits(week.start == selected.start ? .isSelected : [])
                .disabled(select == nil)
            }
        }
        .accessibilityIdentifier("week-month")
    }
}

struct DateLookupView: View {
    @Binding var date: Date
    let appearance: WeekAppearance
    let apply: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DatePicker("week.choose_date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical).accessibilityIdentifier("week-date-picker")
                WeekHeroView(date: date, appearance: appearance)
            }.padding(20)
        }
        .navigationTitle("week.lookup")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("week.cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("week.show_week", action: apply) }
        }
    }
}

struct WidgetSetupView: View {
    var body: some View {
        List {
            Section("week.home_screen") { Text("week.home_instructions") }
            Section("week.lock_screen") { Text("week.lock_instructions") }
            Section { Text("week.widget_footer").foregroundStyle(.secondary) }
        }
        .navigationTitle("week.add_widget")
        .accessibilityIdentifier("widget-setup")
    }
}
/// Existing records keep their original storage/schema and remain reachable.
private struct LegacyPlannerView: View {
    let container: ModelContainer
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearancePreference") private var preference = AppearancePreference.system.rawValue
    @Environment(StoreManager.self) private var store

    var body: some View {
        AppearanceResolver(preference: AppearancePreference(rawValue: preference) ?? .system) { mode in
            ContentView().johoColorMode(mode)
        }
        .modelContainer(container)
        .safeAreaInset(edge: .top) {
            HStack {
                Text("week.saved_planner").font(.headline)
                Spacer()
                Button("week.done") { dismiss() }
            }
            .padding()
            .background(.background)
        }
        .task { await store.refreshEntitlements() }
    }
}
