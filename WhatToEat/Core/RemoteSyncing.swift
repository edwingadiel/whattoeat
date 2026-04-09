import Foundation

struct RemoteBootstrapSnapshot: Sendable {
    let userID: String
    let profile: UserProfile?
    let favoriteItemIDs: [String]
    let historyEntries: [SearchHistoryEntry]
    let feedbackEntries: [UserFeedback]
}

protocol RemoteUserSyncing: Actor {
    func bootstrap(localProfile: UserProfile) async throws -> RemoteBootstrapSnapshot
    func saveProfile(_ profile: UserProfile) async throws
    func replaceFavorites(userID: String, itemIDs: [String]) async throws
    func saveHistoryEntry(userID: String, entry: SearchHistoryEntry) async throws
    func saveFeedbackEntry(userID: String, entry: UserFeedback) async throws
}
