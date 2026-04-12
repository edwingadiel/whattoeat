import SwiftUI

struct ResultsView: View {
    @ObservedObject var store: AppStore
    let response: RecommendationResponse
    @State private var visibleCards: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                headerSection
                resultsSection
                alternatesSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(response.topRecommendations.isEmpty ? "No strong matches" : "Your top picks")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 8) {
                queryStat(icon: "flame.fill", text: "\(response.query.targetCalories) cal", color: AppTheme.accent)
                queryStat(icon: "bolt.fill", text: "\(response.query.targetProtein)g protein", color: AppTheme.teal)
                if let context = response.query.context {
                    queryStat(icon: "clock.fill", text: context.title, color: AppTheme.ink)
                }
            }

            if let guidance = response.guidance {
                guidanceBanner(guidance)
            }
        }
        .padding(.top, 12)
    }

    private func guidanceBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppTheme.warning)
                .font(.subheadline)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.warning)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.warning.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tip: \(text)")
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsSection: some View {
        if response.topRecommendations.isEmpty {
            emptyResultsCard
        } else {
            ForEach(Array(response.topRecommendations.enumerated()), id: \.element.id) { index, result in
                resultLink(result: result, rankLabel: "#\(index + 1)", delay: Double(index) * 0.1)
            }
        }
    }

    // MARK: - Alternates

    @ViewBuilder
    private var alternatesSection: some View {
        if !response.alternateRecommendations.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                alternatesHeader
                ForEach(Array(response.alternateRecommendations.enumerated()), id: \.element.id) { index, result in
                    let delay = Double(response.topRecommendations.count + index) * 0.1
                    resultLink(result: result, rankLabel: nil, delay: delay)
                }
            }
        }
    }

    private var alternatesHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.branch")
                .foregroundStyle(AppTheme.mutedInk)
                .font(.subheadline)
            Text("Also worth trying")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.top, 4)
    }

    // MARK: - Shared

    private func resultLink(result: RecommendationResult, rankLabel: String?, delay: Double) -> some View {
        NavigationLink {
            RecommendationDetailView(store: store, result: result)
        } label: {
            RecommendationCard(
                result: result,
                isFavorite: store.favorites.contains(result.id),
                onFavorite: { store.toggleFavorite(itemID: result.id) },
                rankLabel: rankLabel
            )
        }
        .buttonStyle(.plain)
        .opacity(visibleCards.contains(result.id) ? 1 : 0)
        .offset(y: visibleCards.contains(result.id) ? 0 : 16)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(delay)) {
                _ = visibleCards.insert(result.id)
            }
        }
    }

    private var emptyResultsCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AppTheme.warning.opacity(0.08))
                    .frame(width: 72, height: 72)
                Image(systemName: "fork.knife")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(AppTheme.warning.opacity(0.5))
            }

            Text("Nothing quite fits")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text("Try bumping calories up, lowering protein\na bit, or removing restaurant filters.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.mutedInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .cardStyle()
    }

    private func queryStat(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(color.opacity(0.1))
        )
    }
}
