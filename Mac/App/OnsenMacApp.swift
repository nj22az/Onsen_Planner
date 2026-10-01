import AppKit
import SwiftUI

final class OnsenMacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct OnsenMacApp: App {
    @NSApplicationDelegateAdaptor(OnsenMacAppDelegate.self) private var delegate
    @State private var addOns = AddOnStore()
    @AppStorage("mac.showMenuBarWeek") private var showMenuBar = true
    var body: some Scene {
        WindowGroup("Onsen Planner", id: "main") {
            MacRootView().environment(addOns)
        }
        .defaultSize(width: 920, height: 680)
        .commands { WeekCommands() }
        Settings {
            MacSettingsView().environment(addOns)
        }
        MenuBarExtra(isInserted: $showMenuBar) {
            WeekMenuView()
        } label: {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                Text("week.widget_label \(ISOWeekCalendar.week(for: context.date).number)")
            }
        }
    }
}
