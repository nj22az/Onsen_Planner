import SwiftUI

struct AddOnShopView: View {
    var showsDismissButton = true
    @Environment(AddOnStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var layout: WeekStudioLayout = .minimal
    @State private var colour: WeekStudioColour = .blue
    @State private var showDate = true
    @State private var showYear = true
    var body: some View {
        Form {
            Section {
                Text("week.studio_title").font(.title2)
                Text("week.studio_description")
                WeekStudioContent(date: Date(), layout: layout, showDate: showDate, showYear: showYear)
                    .tint(colour.appearance.tint).frame(minHeight: 170)
                Picker("week.studio_layout", selection: $layout) {
                    Text("week.studio_editorial").tag(WeekStudioLayout.editorial)
                    Text("week.studio_minimal").tag(WeekStudioLayout.minimal)
                }
                Picker("week.studio_colour", selection: $colour) {
                    Text("week.studio_blue").tag(WeekStudioColour.blue)
                    Text("week.studio_burgundy").tag(WeekStudioColour.burgundy)
                    Text("week.studio_teal").tag(WeekStudioColour.teal)
                    Text("week.studio_charcoal").tag(WeekStudioColour.charcoal)
                }
                Toggle("week.studio_show_date", isOn: $showDate)
                Toggle("week.studio_show_year", isOn: $showYear)
                Text("week.studio_preview_footer").font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                if store.owns(.widgetStudio) {
                    Label("week.purchase_owned", systemImage: "checkmark.circle")
                    Text("week.studio_owned_help")
                } else if !store.salesEnabled {
                    Text("week.studio_not_for_sale")
                } else if let offering = store.offerings.first(where: { $0.id == AddOnProduct.widgetStudio.rawValue }) {
                    Button {
                        Task { await store.buy(.widgetStudio) }
                    } label: {
                        HStack { Text("week.purchase_once"); Spacer(); Text(verbatim: offering.displayPrice) }
                    }.disabled(!store.canPurchase(.widgetStudio))
                } else {
                    Text("week.purchase_unavailable")
                    Button("week.purchase_retry") { Task { await store.loadProducts() } }
                }
                if store.checking || store.isBusy { ProgressView() }
                if store.pendingIDs.contains(AddOnProduct.widgetStudio.rawValue) { Text("week.purchase_pending") }
                if let message = store.message { Text(message).font(.footnote).accessibilityAddTraits(.updatesFrequently) }
                Button("week.restore") { Task { await store.restore() } }.disabled(store.isBusy)
                Button("week.check_access") { Task { await store.refresh() } }.disabled(store.isBusy)
            }
            Section {
                Text("week.studio_free_footer").font(.footnote).foregroundStyle(.secondary)
                if let policy = ReleaseFeatures.privacyPolicyURL { Link("week.privacy", destination: policy) }
            }
        }
        .navigationTitle("week.addons")
        .toolbar {
            if showsDismissButton {
                ToolbarItem(placement: .confirmationAction) { Button("week.done") { dismiss() } }
            }
        }
        .task { await store.refresh(); await store.loadProducts() }
        .accessibilityIdentifier("addon-shop")
    }
}
