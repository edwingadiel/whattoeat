import SwiftUI

struct PaywallView: View {
    @ObservedObject var store: AppStore
    let reason: PaywallReason
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()

                Text("Eat within your macros without overthinking it.")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(reason.title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.teal)

                Text("Get faster, more precise food picks based on calories, protein, carbs, and fats.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AppTheme.mutedInk)

                VStack(alignment: .leading, spacing: 12) {
                    paywallBullet("Unlimited searches")
                    paywallBullet("Unlimited favorites and full history")
                    paywallBullet("Carbs and fat targeting")
                    paywallBullet("Advanced controls for more precise picks")
                }
                .padding(20)
                .cardStyle()

                Button {
                    store.purchasePlus()
                    dismiss()
                    store.dismissPaywall()
                } label: {
                    Text("Start Plus • $3.99/month")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(AppTheme.accent)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                    store.dismissPaywall()
                } label: {
                    Text("Continue Free")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(24)
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                        store.dismissPaywall()
                    }
                }
            }
        }
    }

    private func paywallBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(AppTheme.accent)
                .frame(width: 8, height: 8)
                .padding(.top, 7)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.ink)
        }
    }
}
