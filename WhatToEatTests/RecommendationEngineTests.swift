import XCTest
@testable import WhatToEat

final class RecommendationEngineTests: XCTestCase {
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
        let catalog = RestaurantCatalog(
            restaurants: [Restaurant(id: "test", name: "Test", region: "US", active: true)],
            items: [
                RestaurantItem(
                    id: "veg_item",
                    restaurantID: "test",
                    name: "Veg Bowl",
                    category: "Bowl",
                    servingDescription: "Veggies",
                    calories: 500,
                    protein: 20,
                    carbs: 60,
                    fat: 12,
                    sodium: nil,
                    sourceVersion: "v1",
                    active: true,
                    contexts: [.lunch],
                    tags: ["vegetarian"],
                    popularityPrior: 0.6,
                    sourceURL: "https://example.com",
                    modifications: []
                ),
                RestaurantItem(
                    id: "meat_item",
                    restaurantID: "test",
                    name: "Chicken Bowl",
                    category: "Bowl",
                    servingDescription: "Chicken",
                    calories: 500,
                    protein: 35,
                    carbs: 40,
                    fat: 14,
                    sodium: nil,
                    sourceVersion: "v1",
                    active: true,
                    contexts: [.lunch],
                    tags: ["high-protein"],
                    popularityPrior: 0.8,
                    sourceURL: "https://example.com",
                    modifications: []
                )
            ]
        )

        let engine = RecommendationEngine(catalog: catalog)
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
        XCTAssertEqual(response.topRecommendations.first?.item.id, "veg_item")
    }
}
