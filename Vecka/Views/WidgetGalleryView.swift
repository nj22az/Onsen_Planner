import SwiftUI

struct WidgetGalleryView: View {
    let appearance: WeekAppearance
    let openAddOns: () -> Void
    @Environment(AddOnStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("week.gallery_intro").font(.subheadline).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Text("week.home_screen").font(.headline)
                    Text("week.gallery_free").font(.caption).foregroundStyle(.secondary)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) { smallPreview; mediumPreview }
                        VStack(alignment: .leading, spacing: 16) { smallPreview; mediumPreview }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("week.widget_label \(ISOWeekCalendar.week(for: Date()).number)").font(.title2)
                        WeekMonthView(date: Date(), now: Date())
                    }.padding(16).background(.background, in: RoundedRectangle(cornerRadius: 20))
                    Text("week.gallery_large").font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("week.lock_screen").font(.headline)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 24) { lockCircular; lockRectangular }
                        VStack(alignment: .leading, spacing: 16) { lockCircular; lockRectangular }
                    }
                    Text("week.widget_label \(ISOWeekCalendar.week(for: Date()).number)").font(.caption)
                    Text("week.gallery_lock").font(.caption).foregroundStyle(.secondary)
                }
                NavigationLink("week.add_widget") { WidgetSetupView() }.buttonStyle(.borderedProminent)
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Text("week.studio_title").font(.headline)
                    Text(store.owns(.widgetStudio) ? "week.purchase_owned" : "week.studio_intro").font(.subheadline).foregroundStyle(.secondary)
                    WeekStudioContent(date: Date(), layout: .minimal).frame(minHeight: 160)
                        .padding(16).background(.background, in: RoundedRectangle(cornerRadius: 20))
                    Button("week.addons", action: openAddOns).buttonStyle(.bordered)
                }
            }.padding(20).frame(maxWidth: 760, alignment: .leading).frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("week.widgets")
        .accessibilityIdentifier("widget-gallery")
    }
    private var smallPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("week.number_label").font(.subheadline).foregroundStyle(.secondary)
            Text(ISOWeekCalendar.week(for: Date()).number, format: .number.grouping(.never)).font(.largeTitle.weight(.semibold))
            Text(Date(), format: .dateTime.month(.abbreviated).day()).font(.caption)
            Text("week.iso_year \(String(ISOWeekCalendar.week(for: Date()).year))").font(.caption2).foregroundStyle(.secondary)
        }.padding(16).frame(minWidth: 140, minHeight: 150, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
    private var mediumPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("week.widget_label \(ISOWeekCalendar.week(for: Date()).number)").font(.title2.weight(.semibold))
            Text(Date(), format: .dateTime.month(.wide).year()).font(.headline)
            WeekDayStrip(week: ISOWeekCalendar.week(for: Date()), now: Date())
        }.padding(16).frame(minWidth: 240, minHeight: 150, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
    private var lockCircular: some View {
        VStack(spacing: 2) {
            Text("week.short").font(.caption2)
            Text(ISOWeekCalendar.week(for: Date()).number, format: .number.grouping(.never)).font(.title2.weight(.semibold))
        }.padding(12).background(.background, in: Circle())
    }
    private var lockRectangular: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("week.widget_label \(ISOWeekCalendar.week(for: Date()).number)").font(.headline)
            Text(Date(), format: .dateTime.month(.abbreviated).day()).font(.caption)
        }
    }
}

struct AddOnShopView: View {
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
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("week.done") { dismiss() } } }
        .task { await store.refresh(); await store.loadProducts() }
        .accessibilityIdentifier("addon-shop")
    }
}
