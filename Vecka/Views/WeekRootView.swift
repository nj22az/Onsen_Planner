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
