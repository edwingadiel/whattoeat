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
        let query = RecommendationQuery(
            targetCalories: Int(targetCalories) ?? store.profile.calorieTargetDefault,
            targetProtein: Int(targetProtein) ?? store.profile.proteinTargetDefault,
            targetCarbs: store.entitlement.isPlus ? Int(targetCarbs) : nil,
            targetFat: store.entitlement.isPlus ? Int(targetFat) : nil,
            context: selectedContext,
            restaurantIDs: Array(selectedRestaurantIDs)
        )
        latestResponse = store.search(query: query)
    }

    func askForAdvancedMacros() {
        store.requestAdvancedMacros()
    }
}
