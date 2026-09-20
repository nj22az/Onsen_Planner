import SwiftUI

extension View {
    func plannerSaveError(_ message: Binding<String?>) -> some View {
        alert("Changes could not be saved", isPresented: Binding(
            get: { message.wrappedValue != nil },
            set: { if !$0 { message.wrappedValue = nil } }
        )) {
            Button("OK", role: .cancel) { message.wrappedValue = nil }
        } message: {
            Text(message.wrappedValue ?? "Please try again. Your draft is still open.")
        }
    }
}
