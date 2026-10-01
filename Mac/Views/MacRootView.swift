import SwiftUI
import WidgetKit

private enum MacDestination: String, CaseIterable, Identifiable, Hashable {
    case week, widgets, addOns
    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self {
        case .week: return "week.tab"
        case .widgets: return "week.widgets"
        case .addOns: return "week.addons"
        }
    }
    var symbol: String {
        switch self {
        case .week: return "calendar"
        case .widgets: return "square.grid.2x2"
        case .addOns: return "plus.circle"
        }
    }
}

struct MacRootView: View {
    @Environment(AddOnStore.self) private var addOns
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(WeekAppearance.storageKey, store: WeekAppearance.defaults) private var theme = "apple"
    @SceneStorage("mac.destination") private var destination = MacDestination.week.rawValue
    @SceneStorage("mac.followsToday") private var followsToday = true
    @SceneStorage("mac.selectedTimestamp") private var selectedTimestamp = Date().timeIntervalSince1970
    @State private var lookupDate = Date()
    @State private var showLookup = false
    private var selection: MacWeekSelection {
        MacWeekSelection(date: followsToday ? nil : Date(timeIntervalSince1970: selectedTimestamp))
    }
    private var appearance: WeekAppearance { WeekAppearance.resolve(theme) }
    private var destinationBinding: Binding<MacDestination?> {
        Binding(get: { MacDestination(rawValue: destination) ?? .week },
                set: { destination = ($0 ?? .week).rawValue })
    }
    var body: some View {
        NavigationSplitView {
            List(MacDestination.allCases, selection: destinationBinding) { item in
                Label(item.title, systemImage: item.symbol).tag(item)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 150, ideal: 180, max: 240)
            .safeAreaInset(edge: .bottom) {
                SettingsLink { Label("week.settings", systemImage: "gearshape") }
                    .padding().frame(maxWidth: .infinity, alignment: .leading)
            }
        } detail: {
            switch MacDestination(rawValue: destination) ?? .week {
            case .week:
                MacWeekView(selection: selection, appearance: appearance) { select($0) }
                    .navigationTitle("week.title")
                    .toolbar {
                        ToolbarItemGroup {
                            Button { move(-1) } label: { Label("week.previous", systemImage: "chevron.left") }
                                .accessibilityIdentifier("previous-week")
                            Button("week.today") { select(nil) }.accessibilityIdentifier("show-today")
                            Button { move(1) } label: { Label("week.next", systemImage: "chevron.right") }
                                .accessibilityIdentifier("next-week")
                            Button(action: lookup) { Label("week.lookup", systemImage: "magnifyingglass") }
                                .accessibilityIdentifier("open-date-lookup")
                        }
                    }
            case .widgets: MacWidgetGalleryView { destination = MacDestination.addOns.rawValue }
            case .addOns: AddOnShopView(showsDismissButton: false)
            }
        }
        .frame(minWidth: 560, minHeight: 460)
        .tint(appearance.tint)
        .focusedSceneValue(\.weekActions, WeekActions(previous: { move(-1) }, next: { move(1) },
                                                     today: { select(nil) }, lookup: lookup))
        .sheet(isPresented: $showLookup) {
            MacDateLookupView(date: $lookupDate, appearance: appearance) {
                select(lookupDate)
                showLookup = false
            }
        }
        .task { await addOns.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                WidgetCenter.shared.reloadAllTimelines()
                Task { await addOns.refresh() }
            }
        }
        .onChange(of: theme) { _, _ in WidgetCenter.shared.reloadAllTimelines() }
        .onOpenURL { url in
            var value = selection
            if value.open(url, now: Date()) {
                select(value.date)
                showLookup = false
            }
        }
    }
    private func select(_ date: Date?) {
        followsToday = date == nil
        if let date { selectedTimestamp = date.timeIntervalSince1970 }
        destination = MacDestination.week.rawValue
    }
    private func move(_ amount: Int) {
        var value = selection
        value.move(amount, now: Date())
        select(value.date)
    }
    private func lookup() { lookupDate = selection.resolved(now: Date()); showLookup = true }
}
