import SwiftUI

struct PaywallView: View {
    @ObservedObject var store: AppStore
    let reason: PaywallReason
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: PurchaseProduct = .plusAnnual
    @State private var didAppear = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // MARK: - Hero
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentGradient)
                                .frame(width: 88, height: 88)
                                .shadow(color: AppTheme.accent.opacity(0.35), radius: 20, y: 8)

                            Image(systemName: "bolt.shield.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(didAppear ? 1 : 0.6)
                        .opacity(didAppear ? 1 : 0)

                        Text("Unlock your\nfull potential")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                            .multilineTextAlignment(.center)
                            .opacity(didAppear ? 1 : 0)
                            .offset(y: didAppear ? 0 : 10)

                        Text(reason.title)
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(AppTheme.teal)
                            .multilineTextAlignment(.center)
                            .opacity(didAppear ? 1 : 0)
                    }
                    .padding(.top, 20)

                    // MARK: - Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        benefitRow(icon: "infinity", title: "Unlimited searches", subtitle: "No daily limits, search as much as you want")
                        benefitRow(icon: "bookmark.fill", title: "Unlimited favorites", subtitle: "Save every meal that works for you")
                        benefitRow(icon: "chart.bar.fill", title: "Full macro targeting", subtitle: "Dial in carbs and fat, not just calories and protein")
                        benefitRow(icon: "sparkles", title: "Smarter picks", subtitle: "More precise recommendations that learn from you")
                    }
                    .padding(20)
                    .cardStyle()

                    // MARK: - Pricing cards
                    VStack(spacing: 12) {
                        ForEach(store.offerings, id: \.product) { offering in
                            PricingCard(
                                offering: offering,
                                isSelected: selectedProduct == offering.product,
                                isBestValue: offering.product == .plusAnnual
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedProduct = offering.product
                                }
                            }
                        }
                    }

                    // MARK: - Error
                    if let error = store.purchaseError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppTheme.warning)
                                .font(.subheadline)
                            Text(error)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(AppTheme.warning)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.warning.opacity(0.08))
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // MARK: - Purchase CTA
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await store.purchase(selectedProduct)
                                if store.entitlement.isPlus {
                                    dismiss()
                                    store.dismissPaywall()
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if store.isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(ctaText)
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous)
                                    .fill(AppTheme.accentGradient)
                                    .opacity(store.isPurchasing ? 0.5 : 1)
                                    .shadow(color: AppTheme.accent.opacity(store.isPurchasing ? 0 : 0.35), radius: 12, y: 6)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isPurchasing)

                        Button {
                            Task {
                                await store.restorePurchases()
                                if store.entitlement.isPlus {
                                    dismiss()
                                    store.dismissPaywall()
                                }
                            }
                        } label: {
                            Text("Restore Purchases")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(AppTheme.mutedInk)
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isPurchasing)

                        Button {
                            dismiss()
                            store.dismissPaywall()
                        } label: {
                            Text("Continue Free")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(AppTheme.mutedInk.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }

                    // MARK: - Legal
                    Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(AppTheme.mutedInk.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                }
                .padding(.horizontal, 24)
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                        store.dismissPaywall()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.mutedInk.opacity(0.5))
                    }
                }
            }
            .task {
                await store.loadOfferings()
                withAnimation(.easeOut(duration: 0.5)) {
                    didAppear = true
                }
            }
        }
    }

    private var ctaText: String {
        let offering = store.offerings.first { $0.product == selectedProduct }
            ?? (selectedProduct == .plusAnnual ? .defaultAnnual : .defaultMonthly)
        return "Start Plus  \(offering.localizedPrice)/\(offering.localizedPeriod)"
    }

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(AppTheme.accentGradient)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let offering: ProductOffering
    let isSelected: Bool
    let isBestValue: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Radio
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 12, height: 12)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(offering.product == .plusAnnual ? "Annual" : "Monthly")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)

                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(AppTheme.tealGradient)
                                )
                        }
                    }

                    if offering.product == .plusAnnual {
                        Text("Save ~37% compared to monthly")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(AppTheme.teal)
                    }
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 0) {
                    Text(offering.localizedPrice)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text("/\(offering.localizedPeriod)")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(AppTheme.mutedInk)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .fill(isSelected ? AppTheme.accentSoft.opacity(0.5) : Color.white.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent.opacity(0.5) : AppTheme.border, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? AppTheme.accent.opacity(0.1) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }
}
