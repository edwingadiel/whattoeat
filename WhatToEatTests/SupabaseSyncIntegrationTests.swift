import XCTest
@testable import WhatToEat

final class SupabaseSyncIntegrationTests: XCTestCase {
    func testLocalSupabaseBootstrapAndFavoritesSync() async throws {
        let configuration = try XCTUnwrap(loadLocalSupabaseConfiguration())
        let service = try XCTUnwrap(SupabaseSyncService(configuration: configuration))

        let bootstrapSnapshot = try await service.bootstrap(localProfile: UserProfile.default(userID: "local-placeholder"))
        let userID = bootstrapSnapshot.userID
        XCTAssertFalse(userID.isEmpty)

        let updatedProfile = UserProfile(
            userID: userID,
            goal: .cut,
            calorieTargetDefault: 610,
            proteinTargetDefault: 46,
            dietFlags: [.glutenAware],
            dislikedFoods: ["mayo"]
        )

        try await service.saveProfile(updatedProfile)
        try await service.replaceFavorites(
            userID: userID,
            itemIDs: ["chipotle_chicken_bowl", "cfa_grilled_nuggets_12"]
        )

        let historyEntry = SearchHistoryEntry(
            id: UUID(),
            query: RecommendationQuery(
                targetCalories: 610,
                targetProtein: 46,
                targetCarbs: nil,
                targetFat: nil,
                context: .postWorkout,
                restaurantIDs: []
            ),
            topResultName: "Chicken Burrito Bowl",
            createdAt: Date()
        )
        try await service.saveHistoryEntry(userID: userID, entry: historyEntry)

        let served = [
            ServedRecommendation(
                id: UUID(),
                queryID: historyEntry.id,
                restaurantItemID: "chipotle_chicken_bowl",
                finalScore: 0.87,
                explanationShort: "Close to target with strong protein.",
                rankPosition: 1
            ),
            ServedRecommendation(
                id: UUID(),
                queryID: historyEntry.id,
                restaurantItemID: "cfa_grilled_nuggets_12",
                finalScore: 0.72,
                explanationShort: "Good post-workout option.",
                rankPosition: 2
            )
        ]
        try await service.saveServedRecommendations(served)

        let feedbackEntry = UserFeedback(
            id: UUID(),
            itemID: "chipotle_chicken_bowl",
            recommendationID: served.first?.id,
            reason: .goodPick,
            createdAt: Date()
        )

        let remoteProfile = try await service.fetchProfileForDebug(userID: userID)
        let remoteFavorites = try await service.fetchFavoritesForDebug(userID: userID)
        let remoteHistory = try await service.fetchHistoryForDebug(userID: userID)
        let remoteFeedback = try await service.fetchFeedbackForDebug(userID: userID)

        XCTAssertEqual(remoteProfile, updatedProfile)
        XCTAssertEqual(Set(remoteFavorites), Set(["chipotle_chicken_bowl", "cfa_grilled_nuggets_12"]))
        XCTAssertEqual(remoteHistory.first?.topResultName, "Chicken Burrito Bowl")
        XCTAssertEqual(remoteHistory.first?.query.context, .postWorkout)
        XCTAssertEqual(remoteFeedback.first?.itemID, "chipotle_chicken_bowl")
        XCTAssertEqual(remoteFeedback.first?.reason, .goodPick)
    }

    private func loadLocalSupabaseConfiguration() -> SupabaseConfiguration? {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let envURL = repoRoot.appendingPathComponent(".env.local")

        guard let contents = try? String(contentsOf: envURL) else {
            return nil
        }

        let entries = contents
            .split(separator: "\n")
            .reduce(into: [String: String]()) { partialResult, line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return }
                let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return }
                partialResult[parts[0]] = parts[1]
            }

        guard
            let urlString = entries["SUPABASE_URL"],
            let anonKey = entries["SUPABASE_ANON_KEY"],
            let url = URL(string: urlString)
        else {
            return nil
        }

        return SupabaseConfiguration(url: url, anonKey: anonKey)
    }
}
