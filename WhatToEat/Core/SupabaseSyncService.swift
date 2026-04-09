import Foundation
import Supabase

actor SupabaseSyncService: RemoteUserSyncing {
    private let client: SupabaseClient

    init?(configuration: SupabaseConfiguration?) {
        guard let configuration else {
            return nil
        }

        client = SupabaseClient(
            supabaseURL: configuration.url,
            supabaseKey: configuration.anonKey
        )
    }

    func bootstrap(localProfile: UserProfile) async throws -> RemoteBootstrapSnapshot {
        let userID = try await ensureAnonymousUserID()
        let remoteProfile = try await fetchProfile(userID: userID)
        let favoriteItemIDs = try await fetchFavorites(userID: userID)
        let historyEntries = try await fetchHistory(userID: userID)
        let feedbackEntries = try await fetchFeedback(userID: userID)

        if remoteProfile == nil {
            var seededProfile = localProfile
            seededProfile.userID = userID
            try await saveProfile(seededProfile)
        }

        return RemoteBootstrapSnapshot(
            userID: userID,
            profile: remoteProfile,
            favoriteItemIDs: favoriteItemIDs,
            historyEntries: historyEntries,
            feedbackEntries: feedbackEntries
        )
    }

    func saveProfile(_ profile: UserProfile) async throws {
        let row = ProfileRow(profile: profile)
        try await client
            .from("profiles")
            .upsert(row, onConflict: "user_id")
            .execute()
    }

    func replaceFavorites(userID: String, itemIDs: [String]) async throws {
        try await client
            .from("favorites")
            .delete()
            .eq("user_id", value: userID)
            .execute()

        guard !itemIDs.isEmpty else {
            return
        }

        let rows = itemIDs.map { FavoriteRow(userID: userID, restaurantItemID: $0) }
        try await client
            .from("favorites")
            .insert(rows)
            .execute()
    }

    func saveHistoryEntry(userID: String, entry: SearchHistoryEntry) async throws {
        let row = QueryRow(userID: userID, entry: entry)
        try await client
            .from("queries")
            .upsert(row, onConflict: "id")
            .execute()
    }

    func saveFeedbackEntry(userID: String, entry: UserFeedback) async throws {
        let row = FeedbackRow(userID: userID, entry: entry)
        try await client
            .from("feedback")
            .upsert(row, onConflict: "id")
            .execute()
    }

    func saveServedRecommendations(_ recommendations: [ServedRecommendation]) async throws {
        guard !recommendations.isEmpty else { return }
        let rows = recommendations.map(ServedRecommendationRow.init)
        try await client
            .from("recommendations_served")
            .insert(rows)
            .execute()
    }

    func currentUserID() async throws -> String {
        try await ensureAnonymousUserID()
    }

    func fetchProfileForDebug(userID: String) async throws -> UserProfile? {
        try await fetchProfile(userID: userID)
    }

    func fetchFavoritesForDebug(userID: String) async throws -> [String] {
        try await fetchFavorites(userID: userID)
    }

    func fetchHistoryForDebug(userID: String) async throws -> [SearchHistoryEntry] {
        try await fetchHistory(userID: userID)
    }

    func fetchFeedbackForDebug(userID: String) async throws -> [UserFeedback] {
        try await fetchFeedback(userID: userID)
    }

    private func ensureAnonymousUserID() async throws -> String {
        if let currentUser = await client.auth.currentUser {
            return stringify(currentUser.id)
        }

        _ = try await client.auth.signInAnonymously()

        guard let currentUser = await client.auth.currentUser else {
            throw NSError(
                domain: "WhatToEat.Supabase",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Supabase anonymous sign-in succeeded without a user."]
            )
        }

        return stringify(currentUser.id)
    }

    private func fetchProfile(userID: String) async throws -> UserProfile? {
        do {
            let row: ProfileRow = try await client
                .from("profiles")
                .select()
                .eq("user_id", value: userID)
                .single()
                .execute()
                .value
            return row.userProfile
        } catch {
            return nil
        }
    }

    private func fetchFavorites(userID: String) async throws -> [String] {
        let rows: [FavoriteRow] = try await client
            .from("favorites")
            .select("user_id,restaurant_item_id")
            .eq("user_id", value: userID)
            .execute()
            .value
        return rows.map(\.restaurantItemID)
    }

    private func fetchHistory(userID: String) async throws -> [SearchHistoryEntry] {
        let rows: [QueryRow] = try await client
            .from("queries")
            .select()
            .eq("user_id", value: userID)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.compactMap(\.historyEntry)
    }

    private func fetchFeedback(userID: String) async throws -> [UserFeedback] {
        let rows: [FeedbackRow] = try await client
            .from("feedback")
            .select()
            .eq("user_id", value: userID)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.compactMap(\.feedbackEntry)
    }

    private func stringify<T>(_ value: T) -> String {
        if let uuid = value as? UUID {
            return uuid.uuidString.lowercased()
        }
        return String(describing: value).lowercased()
    }
}

private struct ProfileRow: Codable {
    let userID: String
    let goal: String
    let calorieTargetDefault: Int
    let proteinTargetDefault: Int
    let dietFlags: [String]
    let dislikedFoods: [String]

    init(profile: UserProfile) {
        userID = profile.userID
        goal = profile.goal.rawValue
        calorieTargetDefault = profile.calorieTargetDefault
        proteinTargetDefault = profile.proteinTargetDefault
        dietFlags = profile.dietFlags.map(\.rawValue)
        dislikedFoods = profile.dislikedFoods
    }

    var userProfile: UserProfile {
        UserProfile(
            userID: userID,
            goal: NutritionGoal(rawValue: goal) ?? .maintenance,
            calorieTargetDefault: calorieTargetDefault,
            proteinTargetDefault: proteinTargetDefault,
            dietFlags: dietFlags.compactMap(DietFlag.init(rawValue:)),
            dislikedFoods: dislikedFoods
        )
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case goal
        case calorieTargetDefault = "calorie_target_default"
        case proteinTargetDefault = "protein_target_default"
        case dietFlags = "diet_flags"
        case dislikedFoods = "disliked_foods"
    }
}

private struct FavoriteRow: Codable {
    let userID: String
    let restaurantItemID: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case restaurantItemID = "restaurant_item_id"
    }
}

private struct QueryRow: Codable {
    let id: UUID
    let userID: String
    let targetCalories: Int
    let targetProtein: Int
    let targetCarbs: Int?
    let targetFat: Int?
    let context: String?
    let topResultName: String
    let createdAt: Date

    init(userID: String, entry: SearchHistoryEntry) {
        id = entry.id
        self.userID = userID
        targetCalories = entry.query.targetCalories
        targetProtein = entry.query.targetProtein
        targetCarbs = entry.query.targetCarbs
        targetFat = entry.query.targetFat
        context = entry.query.context?.rawValue
        topResultName = entry.topResultName
        createdAt = entry.createdAt
    }

    var historyEntry: SearchHistoryEntry? {
        SearchHistoryEntry(
            id: id,
            query: RecommendationQuery(
                targetCalories: targetCalories,
                targetProtein: targetProtein,
                targetCarbs: targetCarbs,
                targetFat: targetFat,
                context: context.flatMap(MealContext.init(rawValue:)),
                restaurantIDs: []
            ),
            topResultName: topResultName,
            createdAt: createdAt
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case targetCalories = "target_calories"
        case targetProtein = "target_protein"
        case targetCarbs = "target_carbs_nullable"
        case targetFat = "target_fat_nullable"
        case context
        case topResultName = "top_result_name"
        case createdAt = "created_at"
    }
}

private struct FeedbackRow: Codable {
    let id: UUID
    let userID: String
    let recommendationID: UUID?
    let restaurantItemID: String
    let sentiment: String
    let reason: String
    let createdAt: Date

    init(userID: String, entry: UserFeedback) {
        id = entry.id
        self.userID = userID
        recommendationID = entry.recommendationID
        restaurantItemID = entry.itemID
        sentiment = entry.reason == .goodPick ? "positive" : "negative"
        reason = entry.reason.rawValue
        createdAt = entry.createdAt
    }

    var feedbackEntry: UserFeedback? {
        guard let parsedReason = FeedbackReason(rawValue: reason) else {
            return nil
        }

        return UserFeedback(
            id: id,
            itemID: restaurantItemID,
            recommendationID: recommendationID,
            reason: parsedReason,
            createdAt: createdAt
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case recommendationID = "recommendation_id"
        case restaurantItemID = "restaurant_item_id"
        case sentiment
        case reason
        case createdAt = "created_at"
    }
}

private struct ServedRecommendationRow: Codable {
    let id: UUID
    let queryID: UUID
    let restaurantItemID: String
    let finalScore: Double
    let explanationShort: String
    let rankPosition: Int

    init(_ recommendation: ServedRecommendation) {
        id = recommendation.id
        queryID = recommendation.queryID
        restaurantItemID = recommendation.restaurantItemID
        finalScore = recommendation.finalScore
        explanationShort = recommendation.explanationShort
        rankPosition = recommendation.rankPosition
    }

    enum CodingKeys: String, CodingKey {
        case id
        case queryID = "query_id"
        case restaurantItemID = "restaurant_item_id"
        case finalScore = "final_score"
        case explanationShort = "explanation_short"
        case rankPosition = "rank_position"
    }
}
