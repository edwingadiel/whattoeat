import SwiftUI

struct HomeView: View {
    @ObservedObject var store: AppStore
    @StateObject private var viewModel: HomeViewModel

    init(store: AppStore) {
        self.store = store
        _viewModel = StateObject(wrappedValue: HomeViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What are you trying to hit for this meal?")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                        Text("Get three strong picks instead of scrolling through entire menus.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Targets")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        TextField("Calories", text: $viewModel.targetCalories)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        TextField("Protein (g)", text: $viewModel.targetProtein)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(20)
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Advanced macros")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                            Spacer()
                            if !store.entitlement.isPlus {
                                Text("Plus")
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                    .foregroundStyle(AppTheme.gold)
                            }
                        }

                        if store.entitlement.isPlus {
                            TextField("Carbs (g)", text: $viewModel.targetCarbs)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            TextField("Fat (g)", text: $viewModel.targetFat)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Button(action: viewModel.askForAdvancedMacros) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Unlock carbs and fat targeting")
                                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                                            .foregroundStyle(AppTheme.ink)
                                        Text("Use full macro precision when you need more control.")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(AppTheme.mutedInk)
                                    }
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(AppTheme.gold)
                                }
                                .padding(14)
                                .cardStyle(fill: AppTheme.tealSoft.opacity(0.9))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Context")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        FlowLayout(items: MealContext.allCases) { context in
                            PillButton(title: context.title, isSelected: viewModel.selectedContext == context) {
                                viewModel.selectedContext = viewModel.selectedContext == context ? nil : context
                            }
                        }
                    }
                    .padding(20)
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Restaurants")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        Text("Leave blank to search every launch chain.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.mutedInk)

                        FlowLayout(items: store.activeRestaurants) { restaurant in
                            PillButton(
                                title: restaurant.name,
                                isSelected: viewModel.selectedRestaurantIDs.contains(restaurant.id)
                            ) {
                                viewModel.toggleRestaurant(restaurant.id)
                            }
                        }
                    }
                    .padding(20)
                    .cardStyle()

                    Button(action: viewModel.runSearch) {
                        Text("Find My Best Options")
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

                    VStack(alignment: .leading, spacing: 10) {
                        Text(store.entitlement.isPlus ? "Plus is active" : "Free plan")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        Text(store.entitlement.isPlus ? "Unlimited searches and full macro targeting are unlocked." : "Free includes 5 searches a day and 5 saved meals.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                    .padding(16)
                    .cardStyle(fill: store.entitlement.isPlus ? AppTheme.tealSoft : Color.white.opacity(0.72))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationDestination(item: $viewModel.latestResponse) { response in
                ResultsView(store: store, response: response)
            }
        }
    }
}
