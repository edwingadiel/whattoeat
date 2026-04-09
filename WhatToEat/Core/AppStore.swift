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
    @Published var remoteSyncEnabled = false
    @Published var offerings: [ProductOffering] = [.defaultMonthly, .defaultAnnual]
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    var analyticsEnabled: Bool { environment.analytics is PostHogAnalyticsService }
    var crashReportingEnabled: Bool { environment.crashReporter is SentryCrashReporter }
    var subscriptionsEnabled: Bool { environment.subscriptions is RevenueCatSubscriptionService }

    let catalog: RestaurantCatalog
    let engine: RecommendationEngine

    private let environment: AppEnvironment
    private let persistence = LocalPersistenceStore()
    private var hasBootstrappedRemote = false

    init(environment: AppEnvironment) {
        self.environment = environment
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

    func bootstrap() async {
        guard !hasBootstrappedRemote else { return }
        hasBootstrappedRemote = true

        identifyUser()

        guard let remoteSync = environment.remoteSync else { return }

        do {
            let snapshot = try await remoteSync.bootstrap(localProfile: profile)
            remoteSyncEnabled = true
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

            await seedRemoteStateIfNeeded(using: remoteSync, snapshot: snapshot)
        } catch {
            environment.crashReporter.capture("Supabase bootstrap failed: \(error.localizedDescription)")
        }
    }

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

        if let remoteSync = environment.remoteSync {
            let profileToSave = updated
            Task {
                do {
                    try await remoteSync.saveProfile(profileToSave)
                } catch {
                    self.environment.crashReporter.capture("Failed saving remote profile: \(error.localizedDescription)")
                }
            }
        }
    }

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
        syncHistoryEntryIfPossible(historyEntry)
        syncServedRecommendationsIfPossible(servedRecords)

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

    func toggleFavorite(itemID: String) {
        if favorites.contains(itemID) {
            favorites.remove(itemID)
            persistence.saveFavorites(Array(favorites))
            syncFavoritesIfPossible()
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
        syncFavoritesIfPossible()
    }

    func submitFeedback(for itemID: String, recommendationID: UUID? = nil, reason: FeedbackReason) {
        let entry = UserFeedback(id: UUID(), itemID: itemID, recommendationID: recommendationID, reason: reason, createdAt: Date())
        feedbackEntries.insert(entry, at: 0)
        persistence.saveFeedback(feedbackEntries)
        syncFeedbackEntryIfPossible(entry)
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

    func requestAdvancedMacros() {
        guard !entitlement.isPlus else { return }
        activePaywallReason = .advancedMacros
        environment.analytics.track("paywall_viewed", properties: ["reason": PaywallReason.advancedMacros.rawValue])
    }

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

    func dismissPaywall() {
        activePaywallReason = nil
        purchaseError = nil
    }

    var searchesUsedToday: Int {
        persistence.loadSearchesToday().count
    }

    var searchesRemainingToday: Int {
        entitlement.isPlus ? .max : max(0, 5 - searchesUsedToday)
    }

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

    private func syncFavoritesIfPossible() {
        guard let remoteSync = environment.remoteSync, remoteSyncEnabled else { return }
        let currentUserID = profile.userID
        let currentFavorites = Array(favorites)

        Task {
            do {
                try await remoteSync.replaceFavorites(userID: currentUserID, itemIDs: currentFavorites)
            } catch {
                self.environment.crashReporter.capture("Failed syncing favorites: \(error.localizedDescription)")
            }
        }
    }

    private func syncHistoryEntryIfPossible(_ entry: SearchHistoryEntry) {
        guard let remoteSync = environment.remoteSync, remoteSyncEnabled else { return }
        let currentUserID = profile.userID

        Task {
            do {
                try await remoteSync.saveHistoryEntry(userID: currentUserID, entry: entry)
            } catch {
                self.environment.crashReporter.capture("Failed syncing history entry: \(error.localizedDescription)")
            }
        }
    }

    private func syncServedRecommendationsIfPossible(_ recommendations: [ServedRecommendation]) {
        guard let remoteSync = environment.remoteSync, remoteSyncEnabled else { return }

        Task {
            do {
                try await remoteSync.saveServedRecommendations(recommendations)
            } catch {
                self.environment.crashReporter.capture("Failed syncing served recommendations: \(error.localizedDescription)")
            }
        }
    }

    private func syncFeedbackEntryIfPossible(_ entry: UserFeedback) {
        guard let remoteSync = environment.remoteSync, remoteSyncEnabled else { return }
        let currentUserID = profile.userID

        Task {
            do {
                try await remoteSync.saveFeedbackEntry(userID: currentUserID, entry: entry)
            } catch {
                self.environment.crashReporter.capture("Failed syncing feedback entry: \(error.localizedDescription)")
            }
        }
    }

    private func seedRemoteStateIfNeeded(using remoteSync: any RemoteUserSyncing, snapshot: RemoteBootstrapSnapshot) async {
        do {
            if snapshot.favoriteItemIDs.isEmpty, !favorites.isEmpty {
                try await remoteSync.replaceFavorites(userID: profile.userID, itemIDs: Array(favorites))
            }

            if snapshot.historyEntries.isEmpty, !history.isEmpty {
                for entry in history {
                    try await remoteSync.saveHistoryEntry(userID: profile.userID, entry: entry)
                }
            }

            if snapshot.feedbackEntries.isEmpty, !feedbackEntries.isEmpty {
                for entry in feedbackEntries {
                    try await remoteSync.saveFeedbackEntry(userID: profile.userID, entry: entry)
                }
            }
        } catch {
            environment.crashReporter.capture("Failed seeding remote state: \(error.localizedDescription)")
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
