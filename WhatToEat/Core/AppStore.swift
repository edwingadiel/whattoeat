import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var profile: UserProfile
    @Published var entitlement: UserEntitlement
    @Published var favorites: Set<String>
    @Published var feedbackEntries: [UserFeedback]
    @Published var history: [SearchHistoryEntry]
    @Published var hasCompletedOnboarding: Bool
    @Published var activePaywallReason: PaywallReason?
    @Published var offerings: [ProductOffering] = [.defaultMonthly, .defaultAnnual]
    @Published var isPurchasing = false
    @Published var purchaseError: String?
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncError: String?

    var remoteSyncEnabled: Bool { syncCoordinator.isRemoteSyncEnabled }
    var analyticsEnabled: Bool { environment.analytics is PostHogAnalyticsService }
    var crashReportingEnabled: Bool { environment.crashReporter is SentryCrashReporter }
    var subscriptionsEnabled: Bool { environment.subscriptions is RevenueCatSubscriptionService }

    let catalog: RestaurantCatalog
    let engine: RecommendationEngine

    private let environment: AppEnvironment
    private let persistence = LocalPersistenceStore()
    private let syncCoordinator: SyncCoordinator
    private var hasBootstrappedRemote = false

    init(environment: AppEnvironment) {
        self.environment = environment
        self.syncCoordinator = SyncCoordinator(
            remoteSync: environment.remoteSync,
            crashReporter: environment.crashReporter
        )

        let userID = environment.auth.anonymousUserID()
        self.profile = persistence.loadProfile(for: userID) ?? UserProfile.default(userID: userID)
        self.entitlement = environment.subscriptions.currentEntitlement()
        self.favorites = Set(persistence.loadFavorites())
        self.feedbackEntries = persistence.loadFeedback()
        self.history = persistence.loadHistory()
        self.hasCompletedOnboarding = persistence.loadHasCompletedOnboarding()

        do {
            let catalog = try environment.catalog.loadCatalog()
            self.catalog = catalog
            self.engine = RecommendationEngine(catalog: catalog)
        } catch {
            environment.crashReporter.capture("Failed to load seed catalog: \(error.localizedDescription)")
            let fallback = RestaurantCatalog.fallback
            self.catalog = fallback
            self.engine = RecommendationEngine(catalog: fallback)
        }
    }

    static func live() -> AppStore {
        AppStore(environment: AppEnvironmentFactory.live())
    }

    var activeRestaurants: [Restaurant] {
        catalog.activeRestaurants
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        guard !hasBootstrappedRemote else { return }
        hasBootstrappedRemote = true

        identifyUser()

        syncStatus = .syncing

        guard let snapshot = await syncCoordinator.bootstrap(localProfile: profile) else {
            // Bootstrap returned nil — sync disabled or network failure
            if remoteSyncEnabled {
                syncStatus = .offline
                lastSyncError = "Can't reach the cloud. Your changes are saved locally and will sync when you're back online."
            } else {
                syncStatus = .idle
            }
            return
        }

        identifyUser()

        if snapshot.userID != profile.userID {
            profile.userID = snapshot.userID
            persistence.saveProfile(profile)
        }

        if let remoteProfile = snapshot.profile {
            profile = remoteProfile
            persistence.saveProfile(remoteProfile)
        }

        if !snapshot.favoriteItemIDs.isEmpty {
            favorites = Set(snapshot.favoriteItemIDs)
            persistence.saveFavorites(Array(favorites))
        }

        if !snapshot.historyEntries.isEmpty {
            history = mergeHistory(local: history, remote: snapshot.historyEntries)
            persistence.saveHistory(history)
        }

        if !snapshot.feedbackEntries.isEmpty {
            feedbackEntries = mergeFeedback(local: feedbackEntries, remote: snapshot.feedbackEntries)
            persistence.saveFeedback(feedbackEntries)
        }

        await syncCoordinator.seedRemoteStateIfNeeded(
            snapshot: snapshot,
            userID: profile.userID,
            favorites: Array(favorites),
            history: history,
            feedback: feedbackEntries
        )

        syncStatus = .synced
        lastSyncError = nil
    }

    func dismissSyncError() {
        lastSyncError = nil
        if case .failed = syncStatus {
            syncStatus = .idle
        } else if case .offline = syncStatus {
            syncStatus = .idle
        }
    }

    func retrySync() {
        hasBootstrappedRemote = false
        Task { await bootstrap() }
    }

    // MARK: - Computed

    var visibleHistory: [SearchHistoryEntry] {
        entitlement.isPlus ? history : Array(history.prefix(5))
    }

    var favoriteItems: [RecommendationResult] {
        favorites.compactMap { id in
            guard let item = catalog.items.first(where: { $0.id == id }),
                  let restaurant = catalog.restaurant(for: item.restaurantID) else {
                return nil
            }
            return RecommendationResult(
                id: item.id,
                restaurant: restaurant,
                item: item,
                explanation: "Saved because it consistently fits your plan.",
                score: item.popularityPrior * 100,
                isNearMatch: false,
                premiumFieldsLocked: !entitlement.isPlus,
                servedID: nil
            )
        }
        .sorted { $0.restaurant.name < $1.restaurant.name }
    }

    var searchesUsedToday: Int {
        persistence.loadSearchesToday().count
    }

    var searchesRemainingToday: Int {
        entitlement.isPlus ? .max : max(0, 5 - searchesUsedToday)
    }

    // MARK: - Profile

    func saveProfile(_ updated: UserProfile) {
        profile = updated
        hasCompletedOnboarding = true
        persistence.saveProfile(updated)
        persistence.saveHasCompletedOnboarding(true)
        environment.analytics.track("onboarding_completed", properties: [
            "goal": updated.goal.rawValue,
            "calorie_target": "\(updated.calorieTargetDefault)",
            "protein_target": "\(updated.proteinTargetDefault)",
            "diet_flags": updated.dietFlags.map(\.rawValue).joined(separator: ","),
            "has_dislikes": updated.dislikedFoods.isEmpty ? "false" : "true"
        ])

        syncCoordinator.syncProfile(updated)
    }

    // MARK: - Search

    func search(query: RecommendationQuery) -> RecommendationResponse? {
        let todayCount = persistence.loadSearchesToday().count
        guard entitlement.isPlus || todayCount < 5 else {
            activePaywallReason = .dailySearchLimit
            environment.analytics.track("paywall_viewed", properties: ["reason": PaywallReason.dailySearchLimit.rawValue])
            return nil
        }

        var response = engine.recommend(
            query: query,
            profile: profile,
            favorites: favorites,
            feedback: feedbackEntries,
            isPlus: entitlement.isPlus
        )

        let topResult = response.topRecommendations.first?.item.name ?? "No top result"
        let historyEntry = SearchHistoryEntry(
            id: UUID(),
            query: query,
            topResultName: topResult,
            createdAt: Date()
        )

        let allResults = response.topRecommendations + response.alternateRecommendations
        var servedRecords: [ServedRecommendation] = []
        var taggedTop = response.topRecommendations
        var taggedAlternates = response.alternateRecommendations

        for (index, result) in allResults.enumerated() {
            let served = ServedRecommendation(
                id: UUID(),
                queryID: historyEntry.id,
                restaurantItemID: result.item.id,
                finalScore: result.score,
                explanationShort: result.explanation,
                rankPosition: index + 1
            )
            servedRecords.append(served)

            if index < taggedTop.count {
                taggedTop[index].servedID = served.id
            } else {
                taggedAlternates[index - taggedTop.count].servedID = served.id
            }
        }

        response = RecommendationResponse(
            query: response.query,
            topRecommendations: taggedTop,
            alternateRecommendations: taggedAlternates,
            guidance: response.guidance,
            usedExpandedTolerance: response.usedExpandedTolerance
        )

        history.insert(historyEntry, at: 0)
        persistence.saveHistory(history)
        persistence.recordSearch(Date())
        syncCoordinator.syncHistoryEntry(userID: profile.userID, entry: historyEntry)
        syncCoordinator.syncServedRecommendations(servedRecords)

        environment.analytics.track("query_submitted", properties: [
            "target_calories": "\(query.targetCalories)",
            "target_protein": "\(query.targetProtein)",
            "context": query.context?.rawValue ?? "none",
            "restaurant_filter_count": "\(query.restaurantIDs.count)",
            "is_plus": "\(entitlement.isPlus)"
        ])
        environment.analytics.track("recommendations_viewed", properties: [
            "top_count": "\(response.topRecommendations.count)",
            "alternate_count": "\(response.alternateRecommendations.count)",
            "used_expanded_tolerance": "\(response.usedExpandedTolerance)",
            "top_result": response.topRecommendations.first?.item.name ?? "none"
        ])

        return response
    }

    // MARK: - Favorites

    func toggleFavorite(itemID: String) {
        if favorites.contains(itemID) {
            favorites.remove(itemID)
            persistence.saveFavorites(Array(favorites))
            syncCoordinator.syncFavorites(userID: profile.userID, itemIDs: Array(favorites))
            return
        }

        guard entitlement.isPlus || favorites.count < 5 else {
            activePaywallReason = .favoritesLimit
            environment.analytics.track("paywall_viewed", properties: ["reason": PaywallReason.favoritesLimit.rawValue])
            return
        }

        favorites.insert(itemID)
        persistence.saveFavorites(Array(favorites))
        environment.analytics.track("favorite_added", properties: ["item_id": itemID])
        syncCoordinator.syncFavorites(userID: profile.userID, itemIDs: Array(favorites))
    }

    // MARK: - Feedback

    func submitFeedback(for itemID: String, recommendationID: UUID? = nil, reason: FeedbackReason) {
        let entry = UserFeedback(id: UUID(), itemID: itemID, recommendationID: recommendationID, reason: reason, createdAt: Date())
        feedbackEntries.insert(entry, at: 0)
        persistence.saveFeedback(feedbackEntries)
        syncCoordinator.syncFeedbackEntry(userID: profile.userID, entry: entry)
        environment.analytics.track("feedback_submitted", properties: [
            "reason": reason.rawValue,
            "item_id": itemID,
            "has_recommendation_id": recommendationID != nil ? "true" : "false"
        ])
    }

    func trackRecommendationOpened(result: RecommendationResult) {
        environment.analytics.track("recommendation_opened", properties: [
            "item_id": result.item.id,
            "item_name": result.item.name,
            "restaurant": result.restaurant.name,
            "is_near_match": "\(result.isNearMatch)",
            "is_favorite": "\(favorites.contains(result.id))"
        ])
    }

    // MARK: - Paywall

    func requestAdvancedMacros() {
        guard !entitlement.isPlus else { return }
        activePaywallReason = .advancedMacros
        environment.analytics.track("paywall_viewed", properties: ["reason": PaywallReason.advancedMacros.rawValue])
    }

    func dismissPaywall() {
        activePaywallReason = nil
        purchaseError = nil
    }

    // MARK: - Purchases

    func loadOfferings() async {
        let fetched = await environment.subscriptions.fetchOfferings()
        offerings = fetched
    }

    func purchase(_ product: PurchaseProduct) async {
        isPurchasing = true
        purchaseError = nil

        do {
            let newEntitlement = try await environment.subscriptions.purchase(product)
            entitlement = newEntitlement
            environment.analytics.track("subscription_started", properties: [
                "plan": newEntitlement.planName,
                "period": newEntitlement.periodType ?? "unknown"
            ])
        } catch let error as PurchaseError {
            switch error {
            case .cancelled:
                break
            default:
                purchaseError = error.localizedDescription
                environment.crashReporter.capture("Purchase failed: \(error.localizedDescription)")
            }
        } catch {
            purchaseError = error.localizedDescription
        }

        isPurchasing = false
    }

    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil

        do {
            let restored = try await environment.subscriptions.restorePurchases()
            entitlement = restored
            if restored.isPlus {
                environment.analytics.track("subscription_restored", properties: ["plan": restored.planName])
            }
        } catch {
            purchaseError = error.localizedDescription
        }

        isPurchasing = false
    }

    // MARK: - Private

    private func identifyUser() {
        let userID = profile.userID
        if let posthog = environment.analytics as? PostHogAnalyticsService {
            posthog.identify(userID: userID, properties: [
                "goal": profile.goal.rawValue,
                "plan": entitlement.planName,
                "is_plus": entitlement.isPlus ? "true" : "false"
            ])
        }
        if let sentry = environment.crashReporter as? SentryCrashReporter {
            sentry.identify(userID: userID)
        }
    }

    private func mergeHistory(local: [SearchHistoryEntry], remote: [SearchHistoryEntry]) -> [SearchHistoryEntry] {
        let merged = Dictionary((local + remote).map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
        return merged.values.sorted { $0.createdAt > $1.createdAt }
    }

    private func mergeFeedback(local: [UserFeedback], remote: [UserFeedback]) -> [UserFeedback] {
        let merged = Dictionary((local + remote).map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
        return merged.values.sorted { $0.createdAt > $1.createdAt }
    }
}
