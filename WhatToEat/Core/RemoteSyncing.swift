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
    func saveServedRecommendations(_ recommendations: [ServedRecommendation]) async throws

    /// Returns the currently published catalog version from the backend, or
    /// nil when the backend does not support versioning yet. The client
    /// compares this to the locally cached version to decide whether to
    /// pull a fresh catalog. Default implementation returns nil so existing
    /// conformers (e.g. tests, mock syncers) don't break.
    func fetchCatalogVersion() async throws -> String?
}

extension RemoteUserSyncing {
    func fetchCatalogVersion() async throws -> String? { nil }
}
