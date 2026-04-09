import Foundation

struct LocalPersistenceStore {
    private let profilePrefix = "whattoeat.profile."
    private let favoritesKey = "whattoeat.favorites"
    private let feedbackKey = "whattoeat.feedback"
    private let historyKey = "whattoeat.history"
    private let searchesKey = "whattoeat.searches"
    private let onboardingKey = "whattoeat.onboarding.done"

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadProfile(for userID: String) -> UserProfile? {
        guard let data = defaults.data(forKey: profilePrefix + userID) else { return nil }
        return try? decoder.decode(UserProfile.self, from: data)
    }

    func saveProfile(_ profile: UserProfile) {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: profilePrefix + profile.userID)
        }
    }

    func loadFavorites() -> [String] {
        defaults.stringArray(forKey: favoritesKey) ?? []
    }

    func saveFavorites(_ favorites: [String]) {
        defaults.set(favorites.sorted(), forKey: favoritesKey)
    }

    func loadFeedback() -> [UserFeedback] {
        guard let data = defaults.data(forKey: feedbackKey),
              let decoded = try? decoder.decode([UserFeedback].self, from: data) else {
            return []
        }
        return decoded
    }

    func saveFeedback(_ feedback: [UserFeedback]) {
        if let data = try? encoder.encode(feedback) {
            defaults.set(data, forKey: feedbackKey)
        }
    }

    func loadHistory() -> [SearchHistoryEntry] {
        guard let data = defaults.data(forKey: historyKey),
              let decoded = try? decoder.decode([SearchHistoryEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    func saveHistory(_ history: [SearchHistoryEntry]) {
        if let data = try? encoder.encode(history) {
            defaults.set(data, forKey: historyKey)
        }
    }

    func loadSearchesToday() -> [Date] {
        guard let data = defaults.data(forKey: searchesKey),
              let decoded = try? decoder.decode([Date].self, from: data) else {
            return []
        }
        return decoded.filter { Calendar.current.isDateInToday($0) }
    }

    func recordSearch(_ date: Date) {
        var searches = loadSearchesToday()
        searches.append(date)
        if let data = try? encoder.encode(searches) {
            defaults.set(data, forKey: searchesKey)
        }
    }

    func loadHasCompletedOnboarding() -> Bool {
        defaults.bool(forKey: onboardingKey)
    }

    func saveHasCompletedOnboarding(_ value: Bool) {
        defaults.set(value, forKey: onboardingKey)
    }
}
