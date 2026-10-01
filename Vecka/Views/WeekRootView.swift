import SwiftUI
import SwiftData
import WidgetKit

/// The core utility remains usable when a saved planner cannot open.
struct WeekRootView: View {
    let persistence: AppPersistence
    @Environment(NavigationManager.self) private var navigation
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(WeekAppearance.storageKey, store: WeekAppearance.defaults) private var theme = "apple"
    @State private var tab = 0
    @State private var displayedDate: Date?
    @State private var lookupDate = Date()
    @State private var showPlanner = false

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    List {
                        WeekSummarySection(date: displayedDate ?? context.date, now: context.date)
                        Section {
                            HStack {
                                Button("week.previous", systemImage: "chevron.left") { moveWeek(-1) }
                                    .accessibilityIdentifier("previous-week")
                                Spacer()
                                Button("week.today") { displayedDate = nil }
                                    .accessibilityIdentifier("show-today")
                                Spacer()
                                Button("week.next", systemImage: "chevron.right") { moveWeek(1) }
                                    .accessibilityIdentifier("next-week")
                            }
                            .buttonStyle(.borderless)
                        }
                        Section {
                            NavigationLink("week.add_widget") { WidgetSetupView() }
                        }
                    }
                    .navigationTitle("week.title")
                    .accessibilityIdentifier("week-home")
                }
            }
            .tabItem { Label("week.tab", systemImage: "calendar") }.tag(0)

            NavigationStack {
                List {
                    Section {
                        DatePicker("week.choose_date", selection: $lookupDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .accessibilityIdentifier("week-date-picker")
                    }
                    WeekSummarySection(date: lookupDate, now: Date())
                }
                .navigationTitle("week.lookup")
                .accessibilityIdentifier("week-lookup")
            }
            .tabItem { Label("week.lookup", systemImage: "magnifyingglass") }.tag(1)

            NavigationStack {
                Form {
                    Section("week.appearance") {
                        Picker("week.theme", selection: $theme) {
                            ForEach(WeekAppearance.allCases) { style in
                                Text(verbatim: style.title).tag(style.rawValue)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .accessibilityIdentifier("week-theme-picker")
                        Text("week.theme_footer").font(.footnote).foregroundStyle(.secondary)
                    }
                    Section("week.widgets") {
                        NavigationLink("week.add_widget") { WidgetSetupView() }
                        Button("week.refresh_widgets") { WidgetCenter.shared.reloadTimelines(ofKind: "VeckaWidget") }
                    }
                    Section("week.saved_planner") {
                        Button("week.open_planner") { openPlanner() }
                        Text("week.planner_footer").font(.footnote).foregroundStyle(.secondary)
                    }
                    Section("week.about") {
                        Text("week.iso_explanation")
                        Text("week.offline").foregroundStyle(.secondary)
                        if let policy = ReleaseFeatures.privacyPolicyURL {
                            Link("week.privacy", destination: policy)
                        }
                    }
                }
                .navigationTitle("week.settings")
            }
            .tabItem { Label("week.settings", systemImage: "gearshape") }.tag(2)
        }
        .tint(WeekAppearance.resolve(theme).tint)
        .onAppear {
            if WeekAppearance(rawValue: theme) == nil { theme = "apple" }
        }
        .onChange(of: theme) { _, _ in WidgetCenter.shared.reloadTimelines(ofKind: "VeckaWidget") }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { WidgetCenter.shared.reloadTimelines(ofKind: "VeckaWidget") }
        }
        .onChange(of: navigation.shouldNavigateToPage) { _, requested in
            guard requested else { return }
            if navigation.targetPage == .landing && navigation.factIdToShow == nil {
                displayedDate = ISOWeekCalendar.calendar().isDateInToday(navigation.targetDate) ? nil : navigation.targetDate
                tab = 0
                navigation.shouldNavigateToPage = false
                navigation.shouldScrollToWeek = false
            } else {
                openPlanner()
            }
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

    private func moveWeek(_ amount: Int) {
        displayedDate = ISOWeekCalendar.calendar().date(byAdding: .weekOfYear, value: amount, to: displayedDate ?? Date()) ?? displayedDate
    }

    private func openPlanner() {
        persistence.open()
        showPlanner = true
    }
}

struct WeekSummarySection: View {
    let date: Date
    let now: Date
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 64

    private var week: ISOWeek { ISOWeekCalendar.week(for: date) }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("week.number_label").font(.headline).foregroundStyle(.secondary)
                Text(week.number, format: .number.grouping(.never))
                    .font(.system(size: numberSize, weight: .semibold))
                    .foregroundStyle(.tint)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("week-number")
                Text(verbatim: week.start.formatted(.dateTime.month(.abbreviated).day()) + " – " + week.end.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.subheadline)
                Text("week.iso_year \(String(week.year))").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("week-summary")
        }
        Section("week.days") {
            ForEach(week.days, id: \.self) { day in
                HStack {
                    Text(day, format: .dateTime.weekday(.wide))
                    Spacer()
                    Text(day, format: .dateTime.month(.abbreviated).day()).foregroundStyle(.secondary)
                    if ISOWeekCalendar.calendar().isDate(day, inSameDayAs: now) {
                        Image(systemName: IconCatalog.checkmarkCircleFill)
                            .foregroundStyle(.tint)
                            .accessibilityLabel(Text("week.today"))
                    }
                }
            }
        }
    }
}

struct WidgetSetupView: View {
    var body: some View {
        List {
            Section("week.home_screen") {
                Text("week.home_instructions")
            }
            Section("week.lock_screen") {
                Text("week.lock_instructions")
            }
            Section {
                Text("week.widget_footer").foregroundStyle(.secondary)
            }
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
