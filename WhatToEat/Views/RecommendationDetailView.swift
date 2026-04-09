import SwiftUI

struct RecommendationDetailView: View {
    @ObservedObject var store: AppStore
    let result: RecommendationResult
    @State private var submittedFeedback: FeedbackReason?
    @State private var showModifiedNutrition = false
    @State private var selectedModIDs: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroHeader
                whySection
                nutritionGrid
                modificationsSection
                feedbackSection
                saveButton
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

    // MARK: - Hero

    private var heroHeader: some View {
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

            // Protein density badge
            let density = proteinDensity
            if density >= 0.07 {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("HIGH PROTEIN DENSITY")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.5)
                }
                .foregroundStyle(AppTheme.teal)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(AppTheme.tealSoft)
                )
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Why

    private var whySection: some View {
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
    }

    // MARK: - Nutrition

    private var nutritionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(AppTheme.teal)
                    .font(.subheadline)
                Text(showModifiedNutrition ? "Modified nutrition" : "Nutrition")
                    .font(.system(.headline, design: .rounded, weight: .bold))

                if showModifiedNutrition {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedModIDs.removeAll()
                            showModifiedNutrition = false
                        }
                    } label: {
                        Text("Reset")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }

            let cals = modifiedCalories
            let prot = modifiedProtein
            let carb = modifiedCarbs
            let fat = modifiedFat

            HStack(spacing: 8) {
                MetricChip(title: "Calories", value: "\(cals)", color: AppTheme.accent)
                MetricChip(title: "Protein", value: "\(prot)g", color: AppTheme.teal)
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
                    MetricChip(title: "Carbs", value: "\(carb)g", color: AppTheme.ink)
                    MetricChip(title: "Fat", value: "\(fat)g", color: AppTheme.ink)
                }
            }
        }
        .padding(18)
        .cardStyle()
    }

    // MARK: - Modifications (Smart Suggestions)

    @ViewBuilder
    private var modificationsSection: some View {
        if !result.item.modifications.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(AppTheme.teal)
                        .font(.subheadline)
                    Text("Make it better")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                }

                Text("Tap a swap to see how it changes the macros.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.mutedInk)

                ForEach(result.item.modifications) { modification in
                    modificationRow(modification)
                }
            }
            .padding(18)
            .cardStyle()
        }
    }

    private func modificationRow(_ mod: ItemModification) -> some View {
        let isActive = selectedModIDs.contains(mod.id)

        return Button {
            withAnimation(.spring(response: 0.35)) {
                if isActive {
                    selectedModIDs.remove(mod.id)
                } else {
                    selectedModIDs.insert(mod.id)
                }
                showModifiedNutrition = !selectedModIDs.isEmpty
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isActive ? AppTheme.teal : AppTheme.tealSoft.opacity(0.5))
                        .frame(width: 28, height: 28)

                    Image(systemName: isActive ? "checkmark" : "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isActive ? .white : AppTheme.teal)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(mod.modificationName)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)

                    HStack(spacing: 8) {
                        modDelta("Cal", mod.calorieDelta, color: AppTheme.accent)
                        modDelta("Prot", mod.proteinDelta, color: AppTheme.teal)
                        if !result.premiumFieldsLocked {
                            modDelta("Carbs", mod.carbsDelta, color: AppTheme.mutedInk)
                            modDelta("Fat", mod.fatDelta, color: AppTheme.mutedInk)
                        }
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? AppTheme.tealSoft : AppTheme.tealSoft.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isActive ? AppTheme.teal.opacity(0.4) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func modDelta(_ label: String, _ value: Int, color: Color) -> some View {
        let text = value >= 0 ? "+\(value)" : "\(value)"
        let deltaColor = value > 0 ? AppTheme.mutedInk : value < 0 ? AppTheme.teal : AppTheme.mutedInk

        return HStack(spacing: 2) {
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(deltaColor)
            Text(label.lowercased())
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.mutedInk)
        }
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
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
    }

    // MARK: - Save

    @ViewBuilder
    private var saveButton: some View {
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

    // MARK: - Computed nutrition with mods

    private var proteinDensity: Double {
        guard result.item.calories > 0 else { return 0 }
        return Double(result.item.protein) / Double(result.item.calories)
    }

    private var modifiedCalories: Int {
        result.item.calories + selectedMods.reduce(0) { $0 + $1.calorieDelta }
    }

    private var modifiedProtein: Int {
        result.item.protein + selectedMods.reduce(0) { $0 + $1.proteinDelta }
    }

    private var modifiedCarbs: Int {
        result.item.carbs + selectedMods.reduce(0) { $0 + $1.carbsDelta }
    }

    private var modifiedFat: Int {
        result.item.fat + selectedMods.reduce(0) { $0 + $1.fatDelta }
    }

    private var selectedMods: [ItemModification] {
        result.item.modifications.filter { selectedModIDs.contains($0.id) }
    }
}
