import AppKit
import SwiftUI

struct WeekMenuView: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let week = ISOWeekCalendar.week(for: context.date)
            Text("week.widget_label \(week.number)")
            Text(verbatim: week.start.formatted(.dateTime.month(.abbreviated).day()) + " – " + week.end.formatted(.dateTime.month(.abbreviated).day()))
            Divider()
            Button("mac.open_app") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            SettingsLink { Text("week.settings") }
            Divider()
            Button("mac.quit") { NSApp.terminate(nil) }
        }
    }
}
