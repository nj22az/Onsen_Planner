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
            await store.refreshEntitlements()
            if store.productState != .ready { await store.loadProducts() }
            selectAvailableProduct()
        }
        .onChange(of: store.products) { _, _ in selectAvailableProduct() }
        .onChange(of: store.isPro) { _, active in
            if active { dismiss() }
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
                    .frame(width: 44, height: 44)
                    .background(colors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
            }

            Spacer()

            Text("VECKA PRO")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(colors.primary)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
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
                icon: "paintpalette.fill",
                tint: JohoColors.pink,
                title: "Premium themes",
                subtitle: "Artisan palettes — Wagashi, Kincha, Vermilion & Sometsuke"
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
        if store.productState == .loading || store.productState == .idle {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 120)
        } else if store.productState == .unavailable {
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

            Button("Retry loading products") { Task { await store.loadProducts() } }
                .font(JohoFont.bodySmallBold)
                .johoTouchTarget()

            Text("Your planner data is unchanged. If you purchased before, restore below.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: 2)
    }

    private func productButton(_ product: ProOffering) -> some View {
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
                            JohoPill(text: "YEARLY", style: .whiteOnBlack, size: .small)
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
            .background(colors.surface)
            .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: isSelected ? 2 : 1.5)
        }
        .buttonStyle(.plain)
    }

    private func title(for kind: VeckaProduct?, product: ProOffering) -> String {
        switch kind {
        case .proYearly: return "YEARLY"
        case .proMonthly: return "MONTHLY"
        case .proLifetime: return "LIFETIME"
        case nil: return product.displayName
        }
    }

    private func subtitle(for kind: VeckaProduct?, product: ProOffering) -> String {
        product.detail
    }

    private func selectAvailableProduct() {
        if store.product(for: selectedProduct) == nil,
           let first = store.products.first,
           let kind = VeckaProduct(rawValue: first.id) {
            selectedProduct = kind
        }
    }

    // MARK: - Footer (CTA + Restore + Legal)

    private var footerSection: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            if store.salesEnabled && store.productState == .ready && !store.products.isEmpty {
                buyButton
            }

            if store.purchaseState == .pending || store.entitlementState == .unavailable || store.entitlementState == .checking {
                Text(store.entitlementState == .checking ? "Checking purchase access…" : "Purchase access can be checked again without buying twice.")
                    .font(JohoFont.caption)
                Button("Check access") { Task { await store.refreshEntitlements() } }
                    .font(JohoFont.bodySmallBold)
                    .johoTouchTarget()
            }
            if let message = store.statusMessage {
                Text(message).font(JohoFont.bodySmall)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            if let error = store.lastError {
                Text(error).font(JohoFont.bodySmall)
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
        .disabled(!store.canPurchase || store.product(for: selectedProduct) == nil)
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
        .disabled(store.purchaseInFlight)
        .johoTouchTarget()
    }

    /// App Review requires subscription terms on the paywall surface.
    private var legalText: some View {
        VStack(spacing: 4) {
            Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in App Store settings.")
                .font(JohoFont.caption)
                .foregroundStyle(colors.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: JohoDimensions.spacingMD) {
                if let policy = ReleaseFeatures.privacyPolicyURL {
                    Link("Privacy Policy", destination: policy)
                    Text("·")
                }

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
