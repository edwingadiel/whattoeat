import SwiftUI

struct RecommendationDetailView: View {
    @ObservedObject var store: AppStore
    let result: RecommendationResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.restaurant.name.uppercased())
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.teal)
                    Text(result.item.name)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text(result.item.servingDescription)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppTheme.mutedInk)
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Why this works")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Text(result.explanation)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                }
                .padding(20)
                .cardStyle()

                HStack(spacing: 10) {
                    MetricChip(title: "Calories", value: "\(result.item.calories)")
                    MetricChip(title: "Protein", value: "\(result.item.protein)g")
                }

                if result.premiumFieldsLocked {
                    Button {
                        store.requestAdvancedMacros()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plus unlocks carbs and fat")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.ink)
                            Text("Use full macro precision and save more meals.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(AppTheme.mutedInk)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .cardStyle(fill: AppTheme.tealSoft)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 10) {
                        MetricChip(title: "Carbs", value: "\(result.item.carbs)g")
                        MetricChip(title: "Fat", value: "\(result.item.fat)g")
                    }
                }

                if !result.item.modifications.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested swaps")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        ForEach(result.item.modifications) { modification in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(modification.modificationName)
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                Text("\(formattedDelta(modification.calorieDelta)) cal • \(formattedDelta(modification.proteinDelta))g protein")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(AppTheme.mutedInk)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle(fill: Color.white.opacity(0.72))
                        }
                    }
                    .padding(20)
                    .cardStyle()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Feedback")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    FlowLayout(items: FeedbackReason.allCases) { reason in
                        PillButton(title: reason.title, isSelected: false) {
                            store.submitFeedback(for: result.id, reason: reason)
                        }
                    }
                }
                .padding(20)
                .cardStyle()

                Button {
                    store.toggleFavorite(itemID: result.id)
                } label: {
                    Text(store.favorites.contains(result.id) ? "Remove from Saved" : "Save This Pick")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(AppTheme.ink)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedDelta(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}
