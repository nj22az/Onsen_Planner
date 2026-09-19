//
//  PaywallView.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) — Say More With Less
//  Vecka Pro paywall. Renders gracefully in three states:
//    1. Loading        → spinner while App Store products are fetched
//    2. Ready          → product buttons with live prices
//    3. Unavailable    → products not configured / offline; purchase
//                        disabled, Restore still offered
//
//  Presented as a sheet from gated features (exports, event/trip limits)
//  and from Settings → Vecka Pro.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    @Environment(StoreManager.self) private var store

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// Which product the CTA will buy; flagship yearly is preselected.
    @State private var selectedProduct: VeckaProduct = .proYearly
    @State private var showErrorAlert = false

    var body: some View {
        VStack(spacing: 0) {
            headerRow

            JohoDivider()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: JohoDimensions.spacingLG) {
                    heroSection
                    featuresCard
                    productsSection
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingMD)
                .padding(.bottom, JohoDimensions.spacingXL)
            }

            Spacer(minLength: 0)

            footerSection
        }
        .background(colors.canvas)
        .presentationBackground(colors.canvas)
        .presentationDragIndicator(.visible)
        .task {
            // Cheap retry if the launch-time fetch failed or was still running.
            if !store.productsLoaded {
                await store.loadProducts()
            }
        }
        .alert("Purchase Unavailable", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(store.lastError ?? "Something went wrong. Please try again.")
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: IconCatalog.xmark)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)
                    .frame(width: 32, height: 32)
                    .background(colors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
            }

            Spacer()

            Text("VECKA PRO")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(colors.primary)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.vertical, JohoDimensions.spacingMD)
        .background(colors.surface)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: IconCatalog.star)
                .font(.system(size: 44, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(width: 88, height: 88)
                .background(JohoColors.yellow.opacity(JohoDimensions.opacityMedium))
                .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: 2)

            Text("少なくして、多くを。")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)

            Text("Do more with Pro")
                .font(JohoFont.headlineSmall)
                .foregroundStyle(colors.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Feature List

    private var featuresCard: some View {
        VStack(spacing: 0) {
            featureRow(
                icon: "infinity",
                tint: JohoColors.cyan,
                title: "Unlimited events & trips",
                subtitle: "No \(ProLimits.freeEventLimit)-event or \(ProLimits.freeTripLimit)-trip caps"
            )

            JohoDivider(weight: 1.5)

            featureRow(
                icon: "doc.text.fill",
                tint: JohoColors.purple,
                title: "PDF & CSV export",
                subtitle: "Week, month and custom reports"
            )

            JohoDivider(weight: 1.5)

            featureRow(
                icon: "sparkles",
                tint: JohoColors.pink,
                title: "Everything that comes next",
                subtitle: "Premium themes, sync and more join Pro"
            )
        }
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: 2)
    }

    private func featureRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            Image(systemName: icon)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .frame(width: 40, height: 40)
                .background(tint.opacity(JohoDimensions.opacityMedium))
                .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)

                Text(subtitle)
                    .font(JohoFont.caption)
                    .foregroundStyle(colors.secondary)
            }

            Spacer()

            Image(systemName: IconCatalog.checkmark)
                .font(JohoFont.labelBold)
                .foregroundStyle(colors.primary)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingMD)
    }

    // MARK: - Products

    @ViewBuilder
    private var productsSection: some View {
        if !store.productsLoaded {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 120)
        } else if store.products.isEmpty {
            fallbackCard
        } else {
            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(store.products, id: \.id) { product in
                    productButton(product)
                }
            }
        }
    }

    /// Shown when the App Store has no products configured yet (pre-release
    /// builds) or the fetch failed. Purchase is disabled but Restore stays
    /// available so testers are never stuck.
    private var fallbackCard: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            Text("Pro products aren't available right now.")
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .multilineTextAlignment(.center)

            Text("If you purchased before, restore below — otherwise check your connection and try again.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: 2)
    }

    private func productButton(_ product: Product) -> some View {
        let isSelected = selectedProduct.rawValue == product.id
        let kind = VeckaProduct(rawValue: product.id)

        return Button {
            selectedProduct = kind ?? .proYearly
            HapticManager.selection()
        } label: {
            HStack(spacing: JohoDimensions.spacingMD) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title(for: kind, product: product))
                            .font(JohoFont.bodySmallBold)
                            .foregroundStyle(colors.primary)

                        if kind == .proYearly {
                            JohoPill(text: "BEST VALUE", style: .whiteOnBlack, size: .small)
                        }
                    }

                    Text(subtitle(for: kind, product: product))
                        .font(JohoFont.caption)
                        .foregroundStyle(colors.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)
                    .monospacedDigit()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(isSelected ? JohoColors.yellow.opacity(JohoDimensions.opacityLight) : colors.surface)
            .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: isSelected ? 2 : 1.5)
        }
        .buttonStyle(.plain)
    }

    private func title(for kind: VeckaProduct?, product: Product) -> String {
        switch kind {
        case .proYearly: return "YEARLY"
        case .proMonthly: return "MONTHLY"
        case .proLifetime: return "LIFETIME"
        case nil: return product.displayName
        }
    }

    private func subtitle(for kind: VeckaProduct?, product: Product) -> String {
        switch kind {
        case .proYearly:
            if let intro = product.subscription?.introductoryOffer {
                return "\(subscriptionPeriodDescription(intro.period)) free trial, then \(product.displayPrice)/year"
            }
            return "\(product.displayPrice) per year"
        case .proMonthly:
            return "\(product.displayPrice) per month"
        case .proLifetime:
            return "One payment, Pro forever"
        case nil:
            return product.description
        }
    }

    /// StoreKit's `Product.SubscriptionPeriod` has no built-in localized
    /// rendering — format it ourselves ("7-day", "1-month", ...).
    private func subscriptionPeriodDescription(_ period: Product.SubscriptionPeriod) -> String {
        let unit: String
        switch period.unit {
        case .day:   unit = period.value == 1 ? "day" : "days"
        case .week:  unit = period.value == 1 ? "week" : "weeks"
        case .month: unit = period.value == 1 ? "month" : "months"
        case .year:  unit = period.value == 1 ? "year" : "years"
        @unknown default: unit = "period"
        }
        return "\(period.value)-\(unit)"
    }

    // MARK: - Footer (CTA + Restore + Legal)

    private var footerSection: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            if store.productsLoaded && !store.products.isEmpty {
                buyButton
            }

            restoreRow

            legalText
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.vertical, JohoDimensions.spacingMD)
        .background(colors.canvas)
    }

    private var buyButton: some View {
        Button {
            guard let product = store.product(for: selectedProduct) else { return }
            Task {
                let success = await store.purchase(product)
                if success {
                    HapticManager.notification(.success)
                    dismiss()
                } else if store.lastError != nil {
                    showErrorAlert = true
                }
            }
        } label: {
            HStack {
                if store.purchaseInFlight {
                    ProgressView()
                        .tint(colors.primaryInverted)
                } else {
                    Image(systemName: IconCatalog.checkmark)
                        .font(JohoFont.bodySmallBold)
                    Text(selectedProduct == .proLifetime ? "GET PRO FOREVER" : "CONTINUE")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                }
            }
            .foregroundStyle(colors.primaryInverted)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(colors.primary)
            .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: 2)
        }
        .buttonStyle(.plain)
        .disabled(store.purchaseInFlight)
    }

    private var restoreRow: some View {
        Button {
            Task {
                await store.restorePurchases()
                if store.isPro {
                    HapticManager.notification(.success)
                    dismiss()
                }
            }
        } label: {
            Text("Restore purchases")
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(colors.primary)
                .underline()
        }
        .buttonStyle(.plain)
    }

    /// App Review requires subscription terms on the paywall surface.
    private var legalText: some View {
        VStack(spacing: 4) {
            Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in App Store settings.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: JohoDimensions.spacingMD) {
                // TODO(release): point at the hosted privacy policy before App Store submission.
                Link("Privacy Policy", destination: URL(string: "https://example.com/vecka/privacy")!)

                Text("·")

                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .font(JohoFont.caption)
            .foregroundStyle(colors.secondary)
        }
    }
}

#Preview {
    PaywallView()
        .environment(StoreManager.shared)
}
