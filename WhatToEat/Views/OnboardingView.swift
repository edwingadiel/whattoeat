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
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WhatToEat")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("Fast restaurant picks that stay inside your macros.")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.mutedInk)
                }
                .padding(.top, 30)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Goal")
                        .font(.system(.headline, design: .rounded, weight: .bold))

                    HStack {
                        ForEach(NutritionGoal.allCases) { goal in
                            PillButton(title: goal.title, isSelected: viewModel.goal == goal) {
                                viewModel.goal = goal
                            }
                        }
                    }
                }
                .padding(20)
                .cardStyle()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Default meal target")
                        .font(.system(.headline, design: .rounded, weight: .bold))

                    TextField("Calories", text: $viewModel.calorieTarget)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)

                    TextField("Protein (g)", text: $viewModel.proteinTarget)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(20)
                .cardStyle()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Diet flags")
                        .font(.system(.headline, design: .rounded, weight: .bold))
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

                VStack(alignment: .leading, spacing: 12) {
                    Text("Anything you never want suggested?")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Text("Add comma-separated dislikes like mayo, tuna, or bacon.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.mutedInk)
                    TextField("Disliked foods", text: $viewModel.dislikedFoods, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(20)
                .cardStyle()

                Button(action: viewModel.submit) {
                    Text("Start Finding Meals")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppTheme.ink)
                        )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
    }
}
