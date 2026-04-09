import Foundation

struct RecommendationEngine {
    private let catalog: RestaurantCatalog

    init(catalog: RestaurantCatalog) {
        self.catalog = catalog
    }

    func recommend(
        query: RecommendationQuery,
        profile: UserProfile,
        favorites: Set<String>,
        feedback: [UserFeedback],
        isPlus: Bool
    ) -> RecommendationResponse {
        let filteredRestaurants = query.restaurantIDs.isEmpty ? Set(catalog.activeRestaurants.map(\.id)) : Set(query.restaurantIDs)
        let exactMatches = scoreItems(
            items: eligibleItems(for: filteredRestaurants, profile: profile),
            query: query,
            favorites: favorites,
            feedback: feedback,
            calorieTolerance: 0.10,
            proteinShortfall: 5,
            isExpanded: false,
            isPlus: isPlus
        )

        let useExpandedTolerance = exactMatches.count < 3
        let ranked = useExpandedTolerance
            ? scoreItems(
                items: eligibleItems(for: filteredRestaurants, profile: profile),
                query: query,
                favorites: favorites,
                feedback: feedback,
                calorieTolerance: 0.15,
                proteinShortfall: 8,
                isExpanded: true,
                isPlus: isPlus
            )
            : exactMatches

        let top = Array(ranked.prefix(3))
        let alternates = Array(ranked.dropFirst(3).prefix(3))

        let guidance: String? = top.isEmpty
            ? "No strong matches hit that target. Try widening calories or lowering protein slightly."
            : useExpandedTolerance
            ? "No exact hits matched your target, so these are the closest fits."
            : nil

        return RecommendationResponse(
            query: query,
            topRecommendations: top,
            alternateRecommendations: alternates,
            guidance: guidance,
            usedExpandedTolerance: useExpandedTolerance
        )
    }

    private func eligibleItems(for restaurantIDs: Set<String>, profile: UserProfile) -> [RestaurantItem] {
        catalog.items.filter { item in
            guard item.active, restaurantIDs.contains(item.restaurantID) else { return false }
            if profile.dietFlags.contains(.vegetarian), item.tags.contains("vegetarian") == false {
                return false
            }
            if profile.dietFlags.contains(.dairyFree), item.tags.contains("contains-dairy") {
                return false
            }
            if profile.dislikedFoods.isEmpty {
                return true
            }
            let normalizedName = item.name.lowercased()
            return !profile.dislikedFoods.contains(where: { normalizedName.contains($0.lowercased()) })
        }
    }

    private func scoreItems(
        items: [RestaurantItem],
        query: RecommendationQuery,
        favorites: Set<String>,
        feedback: [UserFeedback],
        calorieTolerance: Double,
        proteinShortfall: Int,
        isExpanded: Bool,
        isPlus: Bool
    ) -> [RecommendationResult] {
        items.compactMap { item in
            let calorieLowerBound = Int(Double(query.targetCalories) * (1 - calorieTolerance))
            let calorieUpperBound = Int(Double(query.targetCalories) * (1 + calorieTolerance))
            let proteinLowerBound = query.targetProtein - proteinShortfall

            guard item.calories >= calorieLowerBound,
                  item.calories <= calorieUpperBound,
                  item.protein >= proteinLowerBound else {
                return nil
            }

            guard let restaurant = catalog.restaurant(for: item.restaurantID) else {
                return nil
            }

            let calorieScore = normalizedDistance(from: item.calories, target: query.targetCalories)
            let proteinScore = normalizedDistance(from: item.protein, target: query.targetProtein)
            let contextScore = contextFit(item: item, context: query.context)
            let preferenceScore = preferenceFit(item: item, favorites: favorites, feedback: feedback)
            let popularityScore = item.popularityPrior
            let macroBonus = macroBonus(item: item, query: query, isPlus: isPlus)

            let totalScore = (0.40 * calorieScore)
                + (0.35 * proteinScore)
                + (0.10 * contextScore)
                + (0.10 * preferenceScore)
                + (0.05 * popularityScore)
                + macroBonus

            return RecommendationResult(
                id: item.id,
                restaurant: restaurant,
                item: item,
                explanation: buildExplanation(
                    item: item,
                    query: query,
                    favorites: favorites,
                    feedback: feedback,
                    isExpanded: isExpanded
                ),
                score: totalScore,
                isNearMatch: isExpanded && !(withinExactTolerance(item: item, query: query)),
                premiumFieldsLocked: !isPlus,
                servedID: nil
            )
        }
        .sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.item.protein > rhs.item.protein
            }
            return lhs.score > rhs.score
        }
    }

    private func normalizedDistance(from value: Int, target: Int) -> Double {
        guard target > 0 else { return 0 }
        let difference = abs(Double(value - target))
        let normalized = max(0, 1 - (difference / Double(target)))
        return normalized
    }

    private func contextFit(item: RestaurantItem, context: MealContext?) -> Double {
        guard let context else { return 1 }
        return item.contexts.contains(context) ? 1 : 0.35
    }

    private func preferenceFit(item: RestaurantItem, favorites: Set<String>, feedback: [UserFeedback]) -> Double {
        var score = 0.45
        if favorites.contains(item.id) {
            score += 0.35
        }
        let relevantFeedback = feedback.filter { $0.itemID == item.id }
        for entry in relevantFeedback.prefix(3) {
            switch entry.reason {
            case .goodPick:
                score += 0.12
            case .tooManyCalories, .notEnoughProtein, .wouldNotEat:
                score -= 0.12
            }
        }
        return min(max(score, 0), 1)
    }

    private func macroBonus(item: RestaurantItem, query: RecommendationQuery, isPlus: Bool) -> Double {
        guard isPlus else { return 0 }
        var bonus = 0.0
        if let targetCarbs = query.targetCarbs {
            bonus += 0.03 * normalizedDistance(from: item.carbs, target: targetCarbs)
        }
        if let targetFat = query.targetFat {
            bonus += 0.02 * normalizedDistance(from: item.fat, target: targetFat)
        }
        return bonus
    }

    private func buildExplanation(
        item: RestaurantItem,
        query: RecommendationQuery,
        favorites: Set<String>,
        feedback: [UserFeedback],
        isExpanded: Bool
    ) -> String {
        if favorites.contains(item.id) {
            return "Close to your target and matches a pick you already trust."
        }
        if let context = query.context, context == .postWorkout, item.protein >= query.targetProtein {
            return "Good post-workout option with strong protein and moderate calories."
        }
        if feedback.contains(where: { $0.itemID == item.id && $0.reason == .goodPick }) {
            return "You reacted well to this before, and it still fits today's target."
        }
        if isExpanded {
            return "This is one of the closest fits after widening the calorie and protein range."
        }
        return "Fits your calories closely and gives strong protein for this meal."
    }

    private func withinExactTolerance(item: RestaurantItem, query: RecommendationQuery) -> Bool {
        let calorieLowerBound = Int(Double(query.targetCalories) * 0.90)
        let calorieUpperBound = Int(Double(query.targetCalories) * 1.10)
        return item.calories >= calorieLowerBound
            && item.calories <= calorieUpperBound
            && item.protein >= query.targetProtein - 5
    }
}
