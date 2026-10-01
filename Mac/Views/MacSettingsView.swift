import SwiftUI
import WidgetKit

struct MacSettingsView: View {
    @Environment(AddOnStore.self) private var addOns
    @AppStorage(WeekAppearance.storageKey, store: WeekAppearance.defaults) private var theme = "apple"
    @AppStorage("mac.showMenuBarWeek") private var showMenuBar = true
    var body: some View {
        Form {
            Section("week.appearance") {
                Picker("week.theme", selection: $theme) {
                    ForEach(WeekAppearance.allCases) { style in Text(style.localizedTitle).tag(style.rawValue) }
                }.accessibilityIdentifier("week-theme-picker")
                Toggle("mac.menu_bar", isOn: $showMenuBar)
            }
            Section("week.widgets") {
                Text("mac.widget_instructions")
                Button("week.refresh_widgets") { WidgetCenter.shared.reloadAllTimelines() }
            }
            Section("week.addons") {
                Button("week.restore") { Task { await addOns.restore() } }.disabled(addOns.isBusy)
                if let message = addOns.message { Text(message).font(.footnote) }
            }
            Section("week.about") {
                Text("week.offline")
                Text("mac.planner_scope").font(.footnote).foregroundStyle(.secondary)
                if let policy = ReleaseFeatures.privacyPolicyURL { Link("week.privacy", destination: policy) }
            }
        }
        .formStyle(.grouped).frame(minWidth: 440, idealWidth: 500)
        .padding(12).tint(WeekAppearance.resolve(theme).tint)
        .onChange(of: theme) { _, _ in WidgetCenter.shared.reloadAllTimelines() }
    }
}
