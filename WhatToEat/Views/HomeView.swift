import SwiftUI

struct HomeView: View {
    @ObservedObject var store: AppStore
    @StateObject private var viewModel: HomeViewModel

    init(store: AppStore, prefillQuery: RecommendationQuery? = nil) {
        self.store = store
        _viewModel = StateObject(wrappedValue: HomeViewModel(store: store, prefillQuery: prefillQuery))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Hero
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What are you\ntrying to hit?")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("Three strong picks — no menu scrolling.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                    .padding(.top, 12)

                    // MARK: - Offline banner
                    if !store.syncStatus.isHealthy, let error = store.lastSyncError {
                        OfflineBanner(message: error) {
                            store.retrySync()
                        } onDismiss: {
                            store.dismissSyncError()
                        }
                    }

                    // MARK: - Search error
                    if let error = viewModel.searchError {
                        InlineErrorBanner(message: error) {
                            viewModel.dismissError()
                        }
                    }

                    // MARK: - Targets
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(AppTheme.accent)
                                .font(.subheadline)
                            Text("Targets")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                        }

                        HStack(alignment: .top, spacing: 12) {
                            LabeledTextField(label: "Calories", placeholder: "550", text: $viewModel.targetCalories, keyboardType: .numberPad, validationError: viewModel.calorieError)
                            LabeledTextField(label: "Protein (g)", placeholder: "35", text: $viewModel.targetProtein, keyboardType: .numberPad, validationError: viewModel.proteinError)
                        }
                    }
                    .padding(20)
                    .cardStyle()
                    .animation(.easeOut(duration: 0.2), value: viewModel.calorieError)
                    .animation(.easeOut(duration: 0.2), value: viewModel.proteinError)

                    // MARK: - Advanced macros
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundStyle(store.entitlement.isPlus ? AppTheme.teal : AppTheme.gold)
                                    .font(.subheadline)
                                Text("Advanced macros")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                            }
                            Spacer()
                            if !store.entitlement.isPlus {
                                Text("PLUS")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.gold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill(AppTheme.goldSoft)
                                    )
                            }
                        }

                        if store.entitlement.isPlus {
                            HStack(spacing: 12) {
                                LabeledTextField(label: "Carbs (g)", placeholder: "—", text: $viewModel.targetCarbs, keyboardType: .numberPad)
                                LabeledTextField(label: "Fat (g)", placeholder: "—", text: $viewModel.targetFat, keyboardType: .numberPad)
                            }
                        } else {
                            Button(action: viewModel.askForAdvancedMacros) {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Unlock carbs and fat targeting")
                                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                                            .foregroundStyle(AppTheme.ink)
                                        Text("Full macro precision when you need more control.")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(AppTheme.mutedInk)
                                    }
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .font(.body)
                                        .foregroundStyle(AppTheme.gold)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(AppTheme.goldSoft)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                    .cardStyle()

                    // MARK: - Context
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(AppTheme.teal)
                                .font(.subheadline)
                            Text("Scenario")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                        }
                        FlowLayout(items: MealContext.allCases) { context in
                            ContextPillButton(
                                context: context,
                                isSelected: viewModel.selectedContext == context
                            ) {
                                viewModel.selectedContext = viewModel.selectedContext == context ? nil : context
                            }
                        }
                    }
                    .padding(20)
                    .cardStyle()

                    // MARK: - Restaurants
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 6) {
                            Image(systemName: "storefront.fill")
                                .foregroundStyle(AppTheme.teal)
                                .font(.subheadline)
                            Text("Where")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                        }
                        Text("Leave blank to search all chains.")
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

                    // MARK: - Search CTA
                    VStack(spacing: 8) {
                        GradientButton(title: store.searchesRemainingToday == 0 && !store.entitlement.isPlus
                                       ? "Upgrade to keep searching"
                                       : "Find My Best Options") {
                            if store.searchesRemainingToday == 0 && !store.entitlement.isPlus {
                                store.activePaywallReason = .dailySearchLimit
                            } else {
                                viewModel.runSearch()
                            }
                        }

                        if !store.entitlement.isPlus {
                            let remaining = store.searchesRemainingToday
                            HStack(spacing: 4) {
                                Image(systemName: remaining == 0 ? "exclamationmark.circle.fill" : "sparkle")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(remaining == 0 ? AppTheme.warning : AppTheme.mutedInk)
                                Text(remaining == 0
                                     ? "Daily limit reached"
                                     : "\(remaining) search\(remaining == 1 ? "" : "es") left today")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(remaining == 0 ? AppTheme.warning : AppTheme.mutedInk)
                            }
                            .transition(.opacity)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(remaining == 0
                                ? "Daily search limit reached"
                                : "\(remaining) searches remaining today")
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationDestination(item: $viewModel.latestResponse) { response in
                ResultsView(store: store, response: response)
            }
        }
    }
}
