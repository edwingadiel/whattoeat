import SwiftUI

struct OnboardingView: View {
    @ObservedObject var store: AppStore
    @StateObject private var viewModel: OnboardingViewModel

    init(store: AppStore) {
        self.store = store
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(store: store))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // MARK: - Welcome hero
                VStack(alignment: .leading, spacing: 10) {
                    Text("WhatToEat")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .accessibilityAddTraits(.isHeader)

                    Text("Fast restaurant picks that\nstay inside your macros.")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.mutedInk)
                        .lineSpacing(2)
                }
                .padding(.top, 40)

                // MARK: - Value props
                HStack(spacing: 10) {
                    valueProp(icon: "bolt.fill", text: "3 picks in\nseconds", color: AppTheme.accent)
                    valueProp(icon: "target", text: "Calorie &\nprotein fit", color: AppTheme.teal)
                    valueProp(icon: "heart.fill", text: "Learns what\nyou like", color: AppTheme.gold)
                }

                // MARK: - Goal
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.fill")
                            .foregroundStyle(AppTheme.accent)
                            .font(.subheadline)
                        Text("Your goal")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }

                    HStack(spacing: 8) {
                        ForEach(NutritionGoal.allCases) { goal in
                            PillButton(title: goal.title, isSelected: viewModel.goal == goal) {
                                viewModel.goal = goal
                            }
                        }
                    }
                }
                .padding(20)
                .cardStyle()

                // MARK: - Targets
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(AppTheme.accent)
                            .font(.subheadline)
                        Text("Default meal target")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }

                    HStack(spacing: 12) {
                        LabeledTextField(label: "Calories", placeholder: "550", text: $viewModel.calorieTarget, keyboardType: .numberPad)
                        LabeledTextField(label: "Protein (g)", placeholder: "35", text: $viewModel.proteinTarget, keyboardType: .numberPad)
                    }
                }
                .padding(20)
                .cardStyle()

                // MARK: - Diet
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(AppTheme.teal)
                            .font(.subheadline)
                        Text("Diet flags")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }
                    FlowLayout(items: DietFlag.allCases) { flag in
                        PillButton(title: flag.title, isSelected: viewModel.selectedDietFlags.contains(flag)) {
                            if viewModel.selectedDietFlags.contains(flag) {
                                viewModel.selectedDietFlags.remove(flag)
                            } else {
                                viewModel.selectedDietFlags.insert(flag)
                            }
                        }
                    }
                }
                .padding(20)
                .cardStyle()

                // MARK: - Dislikes
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .foregroundStyle(AppTheme.warning)
                            .font(.subheadline)
                        Text("Never suggest")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }
                    Text("Comma-separated: mayo, tuna, bacon...")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.mutedInk)
                    TextField("Disliked foods", text: $viewModel.dislikedFoods, axis: .vertical)
                        .font(.system(.body, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.surfaceElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                        .accessibilityLabel("Foods to never suggest")
                        .accessibilityHint("Enter foods separated by commas")
                }
                .padding(20)
                .cardStyle()

                // MARK: - CTA
                GradientButton(title: "Start Finding Meals") {
                    viewModel.submit()
                }
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 20)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
    }

    private func valueProp(icon: String, text: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(color.opacity(0.12))
                )

            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text.replacingOccurrences(of: "\n", with: " "))
    }
}
