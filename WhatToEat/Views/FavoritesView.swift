import SwiftUI

struct FavoritesView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saved picks")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                        Text("Keep a short list of meals that reliably work.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                    .padding(.top, 20)

                    if store.favoriteItems.isEmpty {
                        Text("Nothing saved yet. Run a search and bookmark anything that feels dependable.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.mutedInk)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                    } else {
                        ForEach(store.favoriteItems) { result in
                            NavigationLink {
                                RecommendationDetailView(store: store, result: result)
                            } label: {
                                RecommendationCard(result: result, isFavorite: true) {
                                    store.toggleFavorite(itemID: result.id)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
    }
}
