import SwiftUI

struct PillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : AppTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? AppTheme.ink : Color.white.opacity(0.75))
                )
        }
        .buttonStyle(.plain)
    }
}

struct MetricChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AppTheme.mutedInk)
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(fill: Color.white.opacity(0.72))
    }
}

struct RecommendationCard: View {
    let result: RecommendationResult
    let isFavorite: Bool
    let onFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.restaurant.name.uppercased())
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.teal)
                    Text(result.item.name)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(result.explanation)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.mutedInk)
                }

                Spacer()

                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundStyle(isFavorite ? AppTheme.accent : AppTheme.ink)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                MetricChip(title: "Calories", value: "\(result.item.calories)")
                MetricChip(title: "Protein", value: "\(result.item.protein)g")
                if result.premiumFieldsLocked {
                    MetricChip(title: "More", value: "Plus")
                } else {
                    MetricChip(title: "Carbs/Fat", value: "\(result.item.carbs)g / \(result.item.fat)g")
                }
            }

            if result.isNearMatch {
                Text("Closest fit")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.warning)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.7)))
            }
        }
        .padding(18)
        .cardStyle()
    }
}
