import SwiftUI

struct ResultsView: View {
    @ObservedObject var store: AppStore
    let response: RecommendationResponse

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top picks")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("\(response.query.targetCalories) cal • \(response.query.targetProtein)g protein")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.mutedInk)
                    if let guidance = response.guidance {
                        Text(guidance)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppTheme.warning)
                    }
                }
                .padding(.top, 20)

                ForEach(response.topRecommendations) { result in
                    NavigationLink {
                        RecommendationDetailView(store: store, result: result)
                    } label: {
                        RecommendationCard(result: result, isFavorite: store.favorites.contains(result.id)) {
                            store.toggleFavorite(itemID: result.id)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if !response.alternateRecommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Alternates")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        ForEach(response.alternateRecommendations) { result in
                            NavigationLink {
                                RecommendationDetailView(store: store, result: result)
                            } label: {
                                RecommendationCard(result: result, isFavorite: store.favorites.contains(result.id)) {
                                    store.toggleFavorite(itemID: result.id)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}
