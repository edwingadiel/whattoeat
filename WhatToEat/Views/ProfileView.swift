import SwiftUI

struct ProfileView: View {
    @ObservedObject var store: AppStore
    @StateObject private var viewModel: ProfileViewModel

    init(store: AppStore) {
        self.store = store
        _viewModel = StateObject(wrappedValue: ProfileViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your profile")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                        Text("Keep the app light, fast, and useful.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(viewModel.planName)
                                .font(.system(.title3, design: .rounded, weight: .bold))
                            Spacer()
                            Text(viewModel.isPlus ? "ACTIVE" : "FREE")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(viewModel.isPlus ? AppTheme.teal : AppTheme.gold)
                        }

                        Text(viewModel.isPlus ? "Unlimited searches, unlimited saves, and full macro controls." : "5 searches per day, 5 saved meals, and calorie + protein matching.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppTheme.mutedInk)

                        if !viewModel.isPlus {
                            Button(action: viewModel.purchase) {
                                Text("Upgrade to Plus for $3.99/mo")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(AppTheme.accent)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: viewModel.restore) {
                            Text("Restore Purchases")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.ink)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .cardStyle(fill: viewModel.isPlus ? AppTheme.tealSoft : Color.white.opacity(0.78))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Defaults")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        Text("Goal: \(store.profile.goal.title)")
                        Text("Meal target: \(store.profile.calorieTargetDefault) calories, \(store.profile.proteinTargetDefault)g protein")
                        if !store.profile.dislikedFoods.isEmpty {
                            Text("Dislikes: \(store.profile.dislikedFoods.joined(separator: ", "))")
                        }
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .padding(20)
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Backend")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        Text(store.remoteSyncEnabled ? "Supabase connected through anonymous auth." : "Running in local-only mode until Supabase keys are configured.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(store.remoteSyncEnabled ? AppTheme.teal : AppTheme.mutedInk)
                    }
                    .padding(20)
                    .cardStyle(fill: store.remoteSyncEnabled ? AppTheme.tealSoft : Color.white.opacity(0.78))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent searches")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        if store.visibleHistory.isEmpty {
                            Text("Your search history will show up here.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(AppTheme.mutedInk)
                        } else {
                            ForEach(store.visibleHistory) { entry in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.topResultName)
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    Text("\(entry.query.targetCalories) cal • \(entry.query.targetProtein)g protein")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(AppTheme.mutedInk)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding(20)
                    .cardStyle()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
    }
}
