import SwiftUI

struct WeekActions {
    let previous: () -> Void
    let next: () -> Void
    let today: () -> Void
    let lookup: () -> Void
}
private struct WeekActionsKey: FocusedValueKey { typealias Value = WeekActions }
extension FocusedValues {
    var weekActions: WeekActions? {
        get { self[WeekActionsKey.self] }
        set { self[WeekActionsKey.self] = newValue }
    }
}
struct WeekCommands: Commands {
    @FocusedValue(\.weekActions) private var actions
    var body: some Commands {
        CommandMenu("week.tab") {
            Button("week.previous") { actions?.previous() }.keyboardShortcut(.leftArrow, modifiers: .command).disabled(actions == nil)
            Button("week.next") { actions?.next() }.keyboardShortcut(.rightArrow, modifiers: .command).disabled(actions == nil)
            Button("week.today") { actions?.today() }.keyboardShortcut("t", modifiers: .command).disabled(actions == nil)
            Divider()
            Button("week.lookup") { actions?.lookup() }.keyboardShortcut("f", modifiers: .command).disabled(actions == nil)
        }
    }
}
