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
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? AppTheme.ink : AppTheme.surfaceElevated)
                        .shadow(color: isSelected ? AppTheme.ink.opacity(0.3) : .clear, radius: 6, y: 2)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isSelected ? .clear : AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: isSelected)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select")
    }
}

struct MetricChip: View {
    let title: String
    let value: String
    var color: Color = AppTheme.teal

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.mutedInk)
                .tracking(0.5)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct RecommendationCard: View {
    let result: RecommendationResult
    let isFavorite: Bool
    let onFavorite: () -> Void
    var rankLabel: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(result.restaurant.name.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.teal)
                            .tracking(0.8)

                        if let rank = rankLabel {
                            Text(rank)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.accent)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(AppTheme.accentSoft)
                                )
                        }

                        if result.isNearMatch {
                            Text("CLOSE FIT")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.warning)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(AppTheme.warning.opacity(0.12))
                                )
                        }
                    }

                    Text(result.item.name)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)

                    Text(result.explanation)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.mutedInk)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundStyle(isFavorite ? AppTheme.accent : AppTheme.mutedInk)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isFavorite ? AppTheme.accentSoft : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.35), value: isFavorite)
                .accessibilityLabel(isFavorite ? "Remove from saved" : "Save this pick")
                .accessibilityHint("Double tap to \(isFavorite ? "remove from" : "add to") saved meals")
            }

            HStack(spacing: 8) {
                MetricChip(title: "Cal", value: "\(result.item.calories)", color: AppTheme.accent)
                MetricChip(title: "Protein", value: "\(result.item.protein)g", color: AppTheme.teal)
                if result.premiumFieldsLocked {
                    MetricChip(title: "Macros", value: "Plus", color: AppTheme.gold)
                } else {
                    MetricChip(title: "C / F", value: "\(result.item.carbs)g / \(result.item.fat)g", color: AppTheme.ink)
                }
            }
        }
        .padding(18)
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(rankLabel.map { "Rank \($0), " } ?? "")\(result.item.name) from \(result.restaurant.name). \(result.item.calories) calories, \(result.item.protein) grams protein")
    }
}

struct ContextPillButton: View {
    let context: MealContext
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: context.icon)
                    .font(.system(size: 11, weight: .bold))
                Text(context.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? Color.white : AppTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? AppTheme.teal : AppTheme.surfaceElevated)
                    .shadow(color: isSelected ? AppTheme.teal.opacity(0.3) : .clear, radius: 6, y: 2)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? .clear : AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: isSelected)
        .accessibilityLabel("\(context.title) scenario")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select")
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
    }
}

struct GradientButton: View {
    let title: String
    var gradient: LinearGradient = AppTheme.accentGradient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous)
                        .fill(gradient)
                        .shadow(color: AppTheme.accent.opacity(0.35), radius: 12, y: 6)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct SecondaryButton: View {
    let title: String
    var color: Color = AppTheme.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous)
                        .fill(color.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct OfflineBanner: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.subheadline)
                .foregroundStyle(AppTheme.warning)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Working offline")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(message)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Button(action: onRetry) {
                        Text("Retry")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Retry sync")

                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss offline notice")
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.warning.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.warning.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

struct InlineErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.warning)
                .font(.subheadline)

            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.mutedInk)
                    .padding(6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.warning.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var validationError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.mutedInk)
                .tracking(0.5)
            TextField(placeholder, text: $text)
                .font(.system(.body, design: .rounded))
                .keyboardType(keyboardType)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(validationError != nil ? AppTheme.warning : AppTheme.border, lineWidth: validationError != nil ? 1.5 : 1)
                )
                .accessibilityLabel(label)
                .accessibilityValue(text.isEmpty ? placeholder : text)
            if let error = validationError {
                Text(error)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.warning)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
