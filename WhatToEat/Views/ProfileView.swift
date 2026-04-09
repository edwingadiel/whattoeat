import SwiftUI

struct ProfileView: View {
    @ObservedObject var store: AppStore
    @StateObject private var viewModel: ProfileViewModel
    @State private var selectedHistoryEntry: SearchHistoryEntry?

    init(store: AppStore) {
        self.store = store
        _viewModel = StateObject(wrappedValue: ProfileViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(
                        title: "Your profile",
                        subtitle: "Keep it light, fast, and useful."
                    )
                    .padding(.top, 12)

                    // MARK: - Sync status
                    syncStatusBanner

                    // MARK: - Subscription card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.isPlus ? "checkmark.seal.fill" : "sparkle")
                                    .font(.title3)
                                    .foregroundStyle(viewModel.isPlus ? AppTheme.teal : AppTheme.gold)
                                Text(viewModel.planName)
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                            }
                            Spacer()
                            Text(viewModel.isPlus ? "ACTIVE" : "FREE")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(viewModel.isPlus ? AppTheme.teal : AppTheme.gold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(viewModel.isPlus ? AppTheme.tealSoft : AppTheme.goldSoft)
                                )
                        }

                        if viewModel.isPlus {
                            Text("Unlimited searches, unlimited saves, and full macro controls.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(AppTheme.mutedInk)

                            if let expires = store.entitlement.expiresAt {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.teal)
                                    Text("Renews \(expires.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(AppTheme.mutedInk)
                                }
                            }
                        } else {
                            Text("5 searches per day, 5 saved meals, and calorie + protein matching.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(AppTheme.mutedInk)

                            GradientButton(title: "Upgrade to Plus") {
                                store.activePaywallReason = .advancedMacros
                            }
                        }

                        Button {
                            Task { await store.restorePurchases() }
                        } label: {
                            HStack(spacing: 6) {
                                if viewModel.isPurchasing {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text("Restore Purchases")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(AppTheme.mutedInk)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isPurchasing)
                    }
                    .padding(20)
                    .cardStyle(fill: viewModel.isPlus ? AppTheme.tealSoft.opacity(0.5) : Color.white.opacity(0.82))

                    // MARK: - Defaults
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .foregroundStyle(AppTheme.teal)
                                .font(.subheadline)
                            Text("Defaults")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                        }

                        profileRow(label: "Goal", value: store.profile.goal.title)
                        profileRow(label: "Meal target", value: "\(store.profile.calorieTargetDefault) cal, \(store.profile.proteinTargetDefault)g protein")
                        if !store.profile.dietFlags.isEmpty {
                            profileRow(label: "Diet", value: store.profile.dietFlags.map(\.title).joined(separator: ", "))
                        }
                        if !store.profile.dislikedFoods.isEmpty {
                            profileRow(label: "Dislikes", value: store.profile.dislikedFoods.joined(separator: ", "))
                        }
                    }
                    .padding(20)
                    .cardStyle()

                    // MARK: - Usage
                    if !store.entitlement.isPlus {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 6) {
                                Image(systemName: "gauge.with.needle.fill")
                                    .foregroundStyle(AppTheme.accent)
                                    .font(.subheadline)
                                Text("Today's usage")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                            }

                            HStack(spacing: 12) {
                                usageGauge(
                                    label: "Searches",
                                    used: store.searchesUsedToday,
                                    limit: 5,
                                    color: AppTheme.accent
                                )
                                usageGauge(
                                    label: "Saved",
                                    used: store.favorites.count,
                                    limit: 5,
                                    color: AppTheme.teal
                                )
                            }
                        }
                        .padding(20)
                        .cardStyle()
                    }

                    // MARK: - Integrations dashboard
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 6) {
                            Image(systemName: "cable.connector.horizontal")
                                .foregroundStyle(AppTheme.teal)
                                .font(.subheadline)
                            Text("Integrations")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            integrationTile(
                                icon: "cloud.fill",
                                name: "Supabase",
                                active: store.remoteSyncEnabled
                            )
                            integrationTile(
                                icon: "chart.line.uptrend.xyaxis",
                                name: "PostHog",
                                active: store.analyticsEnabled
                            )
                            integrationTile(
                                icon: "shield.checkered",
                                name: "Sentry",
                                active: store.crashReportingEnabled
                            )
                            integrationTile(
                                icon: "creditcard.fill",
                                name: "RevenueCat",
                                active: store.subscriptionsEnabled
                            )
                        }
                    }
                    .padding(20)
                    .cardStyle()

                    // MARK: - Recent searches
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(AppTheme.accent)
                                .font(.subheadline)
                            Text("Recent searches")
                                .font(.system(.headline, design: .rounded, weight: .bold))

                            Spacer()

                            if !store.visibleHistory.isEmpty && !store.entitlement.isPlus {
                                Text("\(store.visibleHistory.count) of \(store.history.count)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.mutedInk)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(AppTheme.mutedInk.opacity(0.08)))
                            }
                        }

                        if store.visibleHistory.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32))
                                    .foregroundStyle(AppTheme.mutedInk.opacity(0.3))
                                Text("No searches yet")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(AppTheme.ink)
                                Text("Your search history will appear here\nafter your first query.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(AppTheme.mutedInk)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            ForEach(store.visibleHistory) { entry in
                                Button {
                                    selectedHistoryEntry = entry
                                } label: {
                                    historyRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }

                            if !store.entitlement.isPlus && store.history.count > 5 {
                                Button {
                                    store.activePaywallReason = .advancedFilters
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.gold)
                                        Text("Unlock full history with Plus")
                                            .font(.system(.caption, design: .rounded, weight: .bold))
                                            .foregroundStyle(AppTheme.gold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(AppTheme.goldSoft)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                    .cardStyle()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationDestination(item: $selectedHistoryEntry) { entry in
                HomeView(store: store, prefillQuery: entry.query)
            }
        }
    }

    // MARK: - Sync Status Banner

    @ViewBuilder
    private var syncStatusBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: store.remoteSyncEnabled ? "checkmark.icloud.fill" : "icloud.slash")
                .font(.subheadline)
                .foregroundStyle(store.remoteSyncEnabled ? AppTheme.teal : AppTheme.mutedInk.opacity(0.5))

            VStack(alignment: .leading, spacing: 1) {
                Text(store.remoteSyncEnabled ? "Synced" : "Local only")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(store.remoteSyncEnabled
                     ? "Your data is backed up to the cloud."
                     : "Data stays on this device only.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(AppTheme.mutedInk)
            }

            Spacer()

            Circle()
                .fill(store.remoteSyncEnabled ? AppTheme.teal : AppTheme.mutedInk.opacity(0.25))
                .frame(width: 8, height: 8)
        }
        .padding(14)
        .cardStyle(fill: store.remoteSyncEnabled ? AppTheme.tealSoft.opacity(0.4) : Color.white.opacity(0.6))
    }

    // MARK: - History Row

    private func historyRow(entry: SearchHistoryEntry) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppTheme.accent.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.topResultName)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)

                HStack(spacing: 6) {
                    Text("\(entry.query.targetCalories) cal")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                    Text("\(entry.query.targetProtein)g protein")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.teal)
                    if let context = entry.query.context {
                        Text(context.title)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(relativeTimestamp(entry.createdAt))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.mutedInk)

                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.accent.opacity(0.6))
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Usage Gauge

    private func usageGauge(label: String, used: Int, limit: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.mutedInk)
                    .tracking(0.5)
                Spacer()
                Text("\(used)/\(limit)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(used >= limit ? AppTheme.warning : color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.12))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(used >= limit ? AppTheme.warning : color)
                        .frame(width: geo.size.width * CGFloat(min(used, limit)) / CGFloat(limit), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.06))
        )
    }

    // MARK: - Integration Tile

    private func integrationTile(icon: String, name: String, active: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(active ? AppTheme.teal : AppTheme.mutedInk.opacity(0.4))
                .frame(width: 30, height: 30)
                .background(
                    Circle().fill(active ? AppTheme.tealSoft : AppTheme.mutedInk.opacity(0.06))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text(active ? "Connected" : "Not configured")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(active ? AppTheme.teal : AppTheme.mutedInk.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(active ? AppTheme.tealSoft.opacity(0.3) : AppTheme.mutedInk.opacity(0.03))
        )
    }

    private func profileRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.mutedInk)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
        }
    }

    private func relativeTimestamp(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 172800 { return "Yesterday" }
        if interval < 604800 { return "\(Int(interval / 86400))d ago" }

        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}
