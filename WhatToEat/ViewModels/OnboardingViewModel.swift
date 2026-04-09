import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var goal: NutritionGoal = .maintenance
    @Published var calorieTarget = "550"
    @Published var proteinTarget = "35"
    @Published var selectedDietFlags: Set<DietFlag> = []
    @Published var dislikedFoods = ""

    private let store: AppStore

    init(store: AppStore) {
        self.store = store
        let profile = store.profile
        goal = profile.goal
        calorieTarget = "\(profile.calorieTargetDefault)"
        proteinTarget = "\(profile.proteinTargetDefault)"
        selectedDietFlags = Set(profile.dietFlags)
        dislikedFoods = profile.dislikedFoods.joined(separator: ", ")
    }

    func submit() {
        let foods = dislikedFoods
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let profile = UserProfile(
            userID: store.profile.userID,
            goal: goal,
            calorieTargetDefault: Int(calorieTarget) ?? 550,
            proteinTargetDefault: Int(proteinTarget) ?? 35,
            dietFlags: Array(selectedDietFlags).sorted { $0.rawValue < $1.rawValue },
            dislikedFoods: foods
        )

        store.saveProfile(profile)
    }
}
