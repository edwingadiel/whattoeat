import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var targetCalories: String
    @Published var targetProtein: String
    @Published var targetCarbs: String = ""
    @Published var targetFat: String = ""
    @Published var selectedContext: MealContext?
    @Published var selectedRestaurantIDs: Set<String> = []
    @Published var latestResponse: RecommendationResponse?

    // Validation state
    @Published var calorieError: String?
    @Published var proteinError: String?
    @Published var searchError: String?

    private let store: AppStore

    init(store: AppStore, prefillQuery: RecommendationQuery? = nil) {
        self.store = store

        if let query = prefillQuery {
            targetCalories = "\(query.targetCalories)"
            targetProtein = "\(query.targetProtein)"
            targetCarbs = query.targetCarbs.map { "\($0)" } ?? ""
            targetFat = query.targetFat.map { "\($0)" } ?? ""
            selectedContext = query.context
            selectedRestaurantIDs = Set(query.restaurantIDs)
        } else {
            targetCalories = "\(store.profile.calorieTargetDefault)"
            targetProtein = "\(store.profile.proteinTargetDefault)"
        }
    }

    var canUseAdvancedMacros: Bool {
        store.entitlement.isPlus
    }

    func toggleRestaurant(_ id: String) {
        if selectedRestaurantIDs.contains(id) {
            selectedRestaurantIDs.remove(id)
        } else {
            selectedRestaurantIDs.insert(id)
        }
    }

    func runSearch() {
        // Clear previous errors
        calorieError = nil
        proteinError = nil
        searchError = nil

        // Validate inputs
        guard validate() else { return }

        let calories = Int(targetCalories) ?? store.profile.calorieTargetDefault
        let protein = Int(targetProtein) ?? store.profile.proteinTargetDefault

        let query = RecommendationQuery(
            targetCalories: calories,
            targetProtein: protein,
            targetCarbs: store.entitlement.isPlus ? Int(targetCarbs) : nil,
            targetFat: store.entitlement.isPlus ? Int(targetFat) : nil,
            context: selectedContext,
            restaurantIDs: Array(selectedRestaurantIDs)
        )

        let response = store.search(query: query)
        if let response {
            latestResponse = response
        } else if store.activePaywallReason == nil {
            searchError = "Something went wrong. Please try again."
        }
    }

    func askForAdvancedMacros() {
        store.requestAdvancedMacros()
    }

    func dismissError() {
        searchError = nil
    }

    // MARK: - Validation

    private func validate() -> Bool {
        var isValid = true

        if targetCalories.isEmpty {
            calorieError = "Required"
            isValid = false
        } else if let cal = Int(targetCalories) {
            if cal < 50 {
                calorieError = "Min 50 cal"
                isValid = false
            } else if cal > 5000 {
                calorieError = "Max 5000 cal"
                isValid = false
            }
        } else {
            calorieError = "Enter a number"
            isValid = false
        }

        if targetProtein.isEmpty {
            proteinError = "Required"
            isValid = false
        } else if let prot = Int(targetProtein) {
            if prot < 0 {
                proteinError = "Can't be negative"
                isValid = false
            } else if prot > 300 {
                proteinError = "Max 300g"
                isValid = false
            }
        } else {
            proteinError = "Enter a number"
            isValid = false
        }

        return isValid
    }
}
