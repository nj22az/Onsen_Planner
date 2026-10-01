import SwiftUI

struct MacDateLookupView: View {
    @Binding var date: Date
    let appearance: WeekAppearance
    let apply: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("week.lookup").font(.title2)
            DatePicker("week.choose_date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical).accessibilityIdentifier("week-date-picker")
            WeekHeroView(date: date, appearance: appearance)
            HStack {
                Spacer()
                Button("week.cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("week.show_week", action: apply).keyboardShortcut(.defaultAction)
            }
        }.padding(24).frame(minWidth: 340, idealWidth: 400)
    }
}
