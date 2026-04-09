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

    init(store: AppStore) {
        self.store = store
        targetCalories = "\(store.profile.calorieTargetDefault)"
        targetProtein = "\(store.profile.proteinTargetDefault)"
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
