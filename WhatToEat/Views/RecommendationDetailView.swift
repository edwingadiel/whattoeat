import SwiftUI

struct RecommendationDetailView: View {
    @ObservedObject var store: AppStore
    let result: RecommendationResult
    @State private var submittedFeedback: FeedbackReason?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Hero header
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(result.restaurant.name.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .tracking(0.8)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppTheme.teal))

                        if result.isNearMatch {
                            Text("CLOSE FIT")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.warning)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.warning.opacity(0.12)))
                        }
                    }

                    Text(result.item.name)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text(result.item.servingDescription)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppTheme.mutedInk)
                }
                .padding(.top, 12)

                // MARK: - Why this works
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(AppTheme.accent)
                            .font(.subheadline)
                        Text("Why this works")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }
                    Text(result.explanation)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                }
                .padding(18)
                .cardStyle()

                // MARK: - Nutrition grid
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(AppTheme.teal)
                            .font(.subheadline)
                        Text("Nutrition")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }

                    HStack(spacing: 8) {
                        MetricChip(title: "Calories", value: "\(result.item.calories)", color: AppTheme.accent)
                        MetricChip(title: "Protein", value: "\(result.item.protein)g", color: AppTheme.teal)
                    }

                    if result.premiumFieldsLocked {
                        Button {
                            store.requestAdvancedMacros()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(AppTheme.gold)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Unlock full macros")
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .foregroundStyle(AppTheme.ink)
                                    Text("See carbs, fat, and more with Plus.")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(AppTheme.mutedInk)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.mutedInk)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppTheme.goldSoft)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 8) {
                            MetricChip(title: "Carbs", value: "\(result.item.carbs)g", color: AppTheme.ink)
                            MetricChip(title: "Fat", value: "\(result.item.fat)g", color: AppTheme.ink)
                        }
                    }
                }
                .padding(18)
                .cardStyle()

                // MARK: - Modifications
                if !result.item.modifications.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(AppTheme.teal)
                                .font(.subheadline)
                            Text("Suggested swaps")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                        }

                        ForEach(result.item.modifications) { modification in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(modification.modificationName)
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .foregroundStyle(AppTheme.ink)
                                    Text("\(formattedDelta(modification.calorieDelta)) cal  \(formattedDelta(modification.proteinDelta))g protein")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(AppTheme.mutedInk)
                                }
                                Spacer()
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.mutedInk)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppTheme.tealSoft.opacity(0.5))
                            )
                        }
                    }
                    .padding(18)
                    .cardStyle()
                }

                // MARK: - Feedback
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: submittedFeedback != nil ? "hand.thumbsup.fill" : "bubble.left.fill")
                            .foregroundStyle(submittedFeedback != nil ? AppTheme.teal : AppTheme.accent)
                            .font(.subheadline)
                        Text(submittedFeedback != nil ? "Thanks for the feedback!" : "How's this pick?")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }

                    if submittedFeedback == nil {
                        FlowLayout(items: FeedbackReason.allCases) { reason in
                            PillButton(title: reason.title, isSelected: false) {
                                withAnimation(.spring(response: 0.35)) {
                                    submittedFeedback = reason
                                }
                                store.submitFeedback(for: result.id, recommendationID: result.servedID, reason: reason)
                            }
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.teal)
                            Text(submittedFeedback?.title ?? "")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.tealSoft.opacity(0.6))
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(18)
                .cardStyle()

                // MARK: - Save button
                if store.favorites.contains(result.id) {
                    SecondaryButton(title: "Remove from Saved", color: AppTheme.warning) {
                        store.toggleFavorite(itemID: result.id)
                    }
                } else {
                    GradientButton(title: "Save This Pick", gradient: AppTheme.tealGradient) {
                        store.toggleFavorite(itemID: result.id)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.trackRecommendationOpened(result: result)
        }
    }

    private func formattedDelta(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}
