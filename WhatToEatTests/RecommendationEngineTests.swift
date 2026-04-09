import XCTest
@testable import WhatToEat

final class RecommendationEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeItem(
        id: String = "test_item",
        restaurantID: String = "test",
        name: String = "Test Item",
        calories: Int = 500,
        protein: Int = 35,
        carbs: Int = 40,
        fat: Int = 14,
        contexts: [MealContext] = [.lunch],
        tags: [String] = ["high-protein"],
        popularityPrior: Double = 0.7,
        modifications: [ItemModification] = []
    ) -> RestaurantItem {
        RestaurantItem(
            id: id,
            restaurantID: restaurantID,
            name: name,
            category: "Entree",
            servingDescription: "Test serving",
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            sodium: nil,
            sourceVersion: "v1",
            active: true,
            contexts: contexts,
            tags: tags,
            popularityPrior: popularityPrior,
            sourceURL: "https://example.com",
            modifications: modifications
        )
    }

    private let testRestaurant = Restaurant(id: "test", name: "Test", region: "US", active: true)

    private func makeEngine(items: [RestaurantItem]) -> RecommendationEngine {
        RecommendationEngine(
            catalog: RestaurantCatalog(restaurants: [testRestaurant], items: items)
        )
    }

    // MARK: - Original tests

    func testExactMatchReturnsHighProteinOptionFirst() {
        let catalog = RestaurantCatalog.fallback
        let engine = RecommendationEngine(catalog: catalog)
        let profile = UserProfile.default(userID: "test")
        let query = RecommendationQuery(
            targetCalories: 550,
            targetProtein: 40,
            targetCarbs: nil,
            targetFat: nil,
            context: .postWorkout,
            restaurantIDs: []
        )

        let response = engine.recommend(
            query: query,
            profile: profile,
            favorites: [],
            feedback: [],
            isPlus: false
        )

        XCTAssertEqual(response.topRecommendations.first?.item.name, "Chicken Burrito Bowl")
        XCTAssertFalse(response.topRecommendations.isEmpty)
    }

    func testExpandedToleranceProducesGuidance() {
        let catalog = RestaurantCatalog.fallback
        let engine = RecommendationEngine(catalog: catalog)
        let profile = UserProfile.default(userID: "test")
        let query = RecommendationQuery(
            targetCalories: 300,
            targetProtein: 50,
            targetCarbs: nil,
            targetFat: nil,
            context: .breakfast,
            restaurantIDs: []
        )

        let response = engine.recommend(
            query: query,
            profile: profile,
            favorites: [],
            feedback: [],
            isPlus: false
        )

        XCTAssertTrue(response.usedExpandedTolerance)
        XCTAssertNotNil(response.guidance)
    }

    func testVegetarianFlagFiltersMeatItems() {
        let items = [
            makeItem(id: "veg", name: "Veg Bowl", protein: 20, tags: ["vegetarian"]),
            makeItem(id: "meat", name: "Chicken Bowl", protein: 35, tags: ["high-protein"]),
        ]

        let engine = makeEngine(items: items)
        var profile = UserProfile.default(userID: "test")
        profile.dietFlags = [.vegetarian]

        let query = RecommendationQuery(
            targetCalories: 500,
            targetProtein: 20,
            targetCarbs: nil,
            targetFat: nil,
            context: .lunch,
            restaurantIDs: []
        )

        let response = engine.recommend(
            query: query,
            profile: profile,
            favorites: [],
            feedback: [],
            isPlus: false
        )

        XCTAssertEqual(response.topRecommendations.count, 1)
        XCTAssertEqual(response.topRecommendations.first?.item.id, "veg")
    }

    // MARK: - New scoring tests

    func testProteinDensityBoostsHighDensityItems() {
        // Both items match the target similarly, but one has much better protein density
        let highDensity = makeItem(id: "high_d", name: "Grilled Nuggets", calories: 400, protein: 35)
        let lowDensity = makeItem(id: "low_d", name: "Pasta Bowl", calories: 400, protein: 35, carbs: 60, fat: 8)

        let engine = makeEngine(items: [highDensity, lowDensity])
        let profile = UserProfile.default(userID: "test")
        let query = RecommendationQuery(
            targetCalories: 400, targetProtein: 35,
            targetCarbs: nil, targetFat: nil, context: nil, restaurantIDs: []
        )

        let response = engine.recommend(query: query, profile: profile, favorites: [], feedback: [], isPlus: false)

        // Both have same cal/protein match — density and satiety should differentiate
        XCTAssertEqual(response.topRecommendations.count, 2,
                       "Both items should match the query")
        // High density has better protein/cal ratio AND better satiety (lower carbs)
        let firstID = response.topRecommendations.first?.item.id
        XCTAssertEqual(firstID, "high_d",
                       "Higher protein density item should rank first when other scores are equal")
    }

    func testContextFilteringWithNewContexts() {
        let driveThruItem = makeItem(id: "dt", name: "Drive-Thru Burger", contexts: [.driveThru, .lunch])
        let mealPrepItem = makeItem(id: "mp", name: "Prep Bowl", contexts: [.mealPrep, .dinner])

        let engine = makeEngine(items: [driveThruItem, mealPrepItem])
        let profile = UserProfile.default(userID: "test")

        let driveThruQuery = RecommendationQuery(
            targetCalories: 500, targetProtein: 35,
            targetCarbs: nil, targetFat: nil, context: .driveThru, restaurantIDs: []
        )

        let response = engine.recommend(query: driveThruQuery, profile: profile, favorites: [], feedback: [], isPlus: false)

        XCTAssertEqual(response.topRecommendations.first?.item.id, "dt",
                       "Drive-thru context should favor drive-thru tagged items")
    }

    func testFeedbackWeightingPenalizesWouldNotEat() {
        let liked = makeItem(id: "liked", name: "Liked Item")
        let disliked = makeItem(id: "disliked", name: "Disliked Item", protein: 36)

        let engine = makeEngine(items: [liked, disliked])
        let profile = UserProfile.default(userID: "test")

        let feedback = [
            UserFeedback(id: UUID(), itemID: "liked", recommendationID: nil, reason: .goodPick, createdAt: Date()),
            UserFeedback(id: UUID(), itemID: "disliked", recommendationID: nil, reason: .wouldNotEat, createdAt: Date()),
        ]

        let query = RecommendationQuery(
            targetCalories: 500, targetProtein: 35,
            targetCarbs: nil, targetFat: nil, context: nil, restaurantIDs: []
        )

        let response = engine.recommend(query: query, profile: profile, favorites: [], feedback: feedback, isPlus: false)

        XCTAssertEqual(response.topRecommendations.first?.item.id, "liked",
                       "'Would not eat' feedback should push item down in ranking")
    }

    func testNoResultsProducesEmptyGuidance() {
        let engine = makeEngine(items: [
            makeItem(calories: 1000, protein: 80)
        ])
        let profile = UserProfile.default(userID: "test")

        let query = RecommendationQuery(
            targetCalories: 300, targetProtein: 20,
            targetCarbs: nil, targetFat: nil, context: nil, restaurantIDs: []
        )

        let response = engine.recommend(query: query, profile: profile, favorites: [], feedback: [], isPlus: false)

        XCTAssertTrue(response.topRecommendations.isEmpty)
        XCTAssertNotNil(response.guidance)
    }

    func testFavoritesBoostRanking() {
        let fav = makeItem(id: "fav_item", name: "Favorite", protein: 34)
        let notFav = makeItem(id: "not_fav", name: "Not Favorite", protein: 36)

        let engine = makeEngine(items: [fav, notFav])
        let profile = UserProfile.default(userID: "test")

        let query = RecommendationQuery(
            targetCalories: 500, targetProtein: 35,
            targetCarbs: nil, targetFat: nil, context: nil, restaurantIDs: []
        )

        let response = engine.recommend(
            query: query, profile: profile,
            favorites: ["fav_item"],
            feedback: [],
            isPlus: false
        )

        XCTAssertEqual(response.topRecommendations.first?.item.id, "fav_item",
                       "Favorited items should rank higher even with slightly less protein")
    }

    func testDislikedFoodsFilter() {
        let items = [
            makeItem(id: "good", name: "Grilled Chicken"),
            makeItem(id: "bad", name: "Mayo Chicken Wrap"),
        ]

        let engine = makeEngine(items: items)
        var profile = UserProfile.default(userID: "test")
        profile.dislikedFoods = ["mayo"]

        let query = RecommendationQuery(
            targetCalories: 500, targetProtein: 35,
            targetCarbs: nil, targetFat: nil, context: nil, restaurantIDs: []
        )

        let response = engine.recommend(query: query, profile: profile, favorites: [], feedback: [], isPlus: false)

        XCTAssertFalse(response.topRecommendations.contains(where: { $0.item.id == "bad" }),
                       "Items containing disliked foods should be filtered out")
    }
}
