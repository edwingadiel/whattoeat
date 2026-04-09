import Foundation

enum MealContext: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack
    case postWorkout = "post-workout"
    case latenight
    case driveThru = "drive-thru"
    case cheap
    case noCook = "no-cook"
    case mealPrep = "meal-prep"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        case .postWorkout: "Post-Workout"
        case .latenight: "Late Night"
        case .driveThru: "Drive-Thru"
        case .cheap: "Cheap"
        case .noCook: "No Cook"
        case .mealPrep: "Meal Prep"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.fill"
        case .snack: "carrot.fill"
        case .postWorkout: "dumbbell.fill"
        case .latenight: "moon.stars.fill"
        case .driveThru: "car.fill"
        case .cheap: "dollarsign.circle.fill"
        case .noCook: "hand.raised.slash.fill"
        case .mealPrep: "takeoutbag.and.cup.and.straw.fill"
        }
    }
}

enum DietFlag: String, Codable, CaseIterable, Identifiable, Sendable {
    case vegetarian
    case dairyFree = "dairy-free"
    case glutenAware = "gluten-aware"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vegetarian: "Vegetarian"
        case .dairyFree: "Dairy-Free"
        case .glutenAware: "Gluten-Aware"
        }
    }
}

enum FeedbackReason: String, Codable, CaseIterable, Identifiable, Sendable {
    case goodPick = "good-pick"
    case tooManyCalories = "too-many-calories"
    case notEnoughProtein = "not-enough-protein"
    case wouldNotEat = "would-not-eat"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .goodPick: "Good Pick"
        case .tooManyCalories: "Too Many Calories"
        case .notEnoughProtein: "Not Enough Protein"
        case .wouldNotEat: "Wouldn't Eat This"
        }
    }
}

enum NutritionGoal: String, Codable, CaseIterable, Identifiable, Sendable {
    case cut
    case maintenance
    case gain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cut: "Cut"
        case .maintenance: "Maintain"
        case .gain: "Gain"
        }
    }
}

struct UserProfile: Codable, Equatable, Sendable {
    var userID: String
    var goal: NutritionGoal
    var calorieTargetDefault: Int
    var proteinTargetDefault: Int
    var dietFlags: [DietFlag]
    var dislikedFoods: [String]

    static func `default`(userID: String) -> UserProfile {
        UserProfile(
            userID: userID,
            goal: .maintenance,
            calorieTargetDefault: 550,
            proteinTargetDefault: 35,
            dietFlags: [],
            dislikedFoods: []
        )
    }
}

struct UserEntitlement: Codable, Equatable, Sendable {
    var isPlus: Bool
    var planName: String
    var providerCustomerID: String?
    var expiresAt: Date?
    var periodType: String?

    static let free = UserEntitlement(isPlus: false, planName: "Free", providerCustomerID: nil)
    static let plus = UserEntitlement(isPlus: true, planName: "Plus", providerCustomerID: "local-plus-user")

    var isMonthly: Bool { periodType == "monthly" }
    var isAnnual: Bool { periodType == "annual" }
}

enum PurchaseProduct: String, CaseIterable, Identifiable, Sendable {
    case plusMonthly = "whattoeat_plus_monthly"
    case plusAnnual = "whattoeat_plus_annual"

    var id: String { rawValue }
}

struct ProductOffering: Equatable, Sendable {
    let product: PurchaseProduct
    let localizedPrice: String
    let localizedPeriod: String

    static let defaultMonthly = ProductOffering(product: .plusMonthly, localizedPrice: "$3.99", localizedPeriod: "month")
    static let defaultAnnual = ProductOffering(product: .plusAnnual, localizedPrice: "$29.99", localizedPeriod: "year")
}

enum PurchaseError: Error, LocalizedError, Sendable {
    case cancelled
    case networkError
    case notConfigured
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .cancelled: "Purchase was cancelled."
        case .networkError: "Could not connect. Check your internet and try again."
        case .notConfigured: "Subscriptions are not configured yet."
        case .unknown(let detail): detail
        }
    }
}

struct Restaurant: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let region: String
    let active: Bool
}

struct ItemModification: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let modificationName: String
    let calorieDelta: Int
    let proteinDelta: Int
    let carbsDelta: Int
    let fatDelta: Int
}

struct RestaurantItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let restaurantID: String
    let name: String
    let category: String
    let servingDescription: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let sodium: Int?
    let sourceVersion: String
    let active: Bool
    let contexts: [MealContext]
    let tags: [String]
    let popularityPrior: Double
    let sourceURL: String
    let modifications: [ItemModification]
}

struct RestaurantCatalog: Codable, Sendable {
    let restaurants: [Restaurant]
    let items: [RestaurantItem]

    var activeRestaurants: [Restaurant] {
        restaurants.filter(\.active)
    }

    func restaurant(for id: String) -> Restaurant? {
        restaurants.first(where: { $0.id == id })
    }

    static var fallback: RestaurantCatalog {
        RestaurantCatalog(
            restaurants: [
                Restaurant(id: "chipotle", name: "Chipotle", region: "US/PR", active: true)
            ],
            items: [
                RestaurantItem(
                    id: "chipotle_chicken_bowl",
                    restaurantID: "chipotle",
                    name: "Chicken Burrito Bowl",
                    category: "Entree",
                    servingDescription: "Chicken, rice, fajita veggies, pico",
                    calories: 560,
                    protein: 42,
                    carbs: 52,
                    fat: 18,
                    sodium: 980,
                    sourceVersion: "2026-04-curated",
                    active: true,
                    contexts: [.lunch, .dinner, .postWorkout],
                    tags: ["high-protein", "filling"],
                    popularityPrior: 0.82,
                    sourceURL: "https://www.chipotle.com/nutrition-calculator",
                    modifications: [
                        ItemModification(
                            id: "extra_fajita",
                            modificationName: "Extra fajita veggies",
                            calorieDelta: 20,
                            proteinDelta: 1,
                            carbsDelta: 4,
                            fatDelta: 0
                        )
                    ]
                )
            ]
        )
    }
}

struct RecommendationQuery: Codable, Equatable, Hashable, Sendable {
    var targetCalories: Int
    var targetProtein: Int
    var targetCarbs: Int?
    var targetFat: Int?
    var context: MealContext?
    var restaurantIDs: [String]
}

struct RecommendationResult: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let restaurant: Restaurant
    let item: RestaurantItem
    let explanation: String
    let score: Double
    let isNearMatch: Bool
    let premiumFieldsLocked: Bool
    var servedID: UUID?
}

struct RecommendationResponse: Identifiable, Equatable, Hashable, Sendable {
    let id = UUID()
    let query: RecommendationQuery
    let topRecommendations: [RecommendationResult]
    let alternateRecommendations: [RecommendationResult]
    let guidance: String?
    let usedExpandedTolerance: Bool
}

struct SearchHistoryEntry: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let query: RecommendationQuery
    let topResultName: String
    let createdAt: Date
}

struct ServedRecommendation: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let queryID: UUID
    let restaurantItemID: String
    let finalScore: Double
    let explanationShort: String
    let rankPosition: Int
}

struct UserFeedback: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let itemID: String
    let recommendationID: UUID?
    let reason: FeedbackReason
    let createdAt: Date
}

enum PaywallReason: String, Identifiable, Sendable {
    case dailySearchLimit
    case favoritesLimit
    case advancedMacros
    case advancedFilters

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dailySearchLimit:
            "Unlock unlimited searches"
        case .favoritesLimit:
            "Unlock unlimited favorites"
        case .advancedMacros:
            "Unlock carbs and fat targeting"
        case .advancedFilters:
            "Unlock advanced recommendation controls"
        }
    }
}
