import SwiftUI

struct FavoritesView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(
                        title: "Saved picks",
                        subtitle: "Meals that reliably work for you."
                    )
                    .padding(.top, 12)

                    if !store.entitlement.isPlus {
                        HStack(spacing: 10) {
                            Image(systemName: "bookmark.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.accent)
                            Text("\(store.favorites.count)/5 saved")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.ink)
                            Spacer()
                            if store.favorites.count >= 5 {
                                Text("LIMIT REACHED")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.warning)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(AppTheme.warning.opacity(0.1)))
                            }
                        }
                        .padding(12)
                        .cardStyle(fill: AppTheme.accentSoft.opacity(0.4))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(store.favorites.count) of 5 saved meals\(store.favorites.count >= 5 ? ", limit reached" : "")")
                    }

                    if store.favoriteItems.isEmpty {
                        VStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.mutedInk.opacity(0.06))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "bookmark")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundStyle(AppTheme.mutedInk.opacity(0.35))
                            }

                            VStack(spacing: 6) {
                                Text("Nothing saved yet")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                    .foregroundStyle(AppTheme.ink)

                                Text("Run a search and bookmark anything\nthat feels dependable.")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(AppTheme.mutedInk)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
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
                .padding(.bottom, 30)
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
    }
}
