import Foundation

/// Extracts remote sync orchestration from AppStore, keeping the store focused on state management.
@MainActor
final class SyncCoordinator {
    private let remoteSync: (any RemoteUserSyncing)?
    private let crashReporter: CrashReporting
    private(set) var isRemoteSyncEnabled = false

    init(remoteSync: (any RemoteUserSyncing)?, crashReporter: CrashReporting) {
        self.remoteSync = remoteSync
        self.crashReporter = crashReporter
    }

    var hasRemoteSync: Bool {
        remoteSync != nil
    }

    // MARK: - Bootstrap

    func bootstrap(localProfile: UserProfile) async -> RemoteBootstrapSnapshot? {
        guard let remoteSync else { return nil }

        do {
            let snapshot = try await remoteSync.bootstrap(localProfile: localProfile)
            isRemoteSyncEnabled = true
            return snapshot
        } catch {
            crashReporter.capture("Supabase bootstrap failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Probes the backend for the latest catalog version. Returns nil when
    /// remote sync is unavailable or the server hasn't been upgraded yet.
    /// Callers compare the result to the locally cached version to decide
    /// whether a fresh catalog pull is needed.
    func fetchCatalogVersion() async -> String? {
        guard let remoteSync, isRemoteSyncEnabled else { return nil }
        do {
            return try await remoteSync.fetchCatalogVersion()
        } catch {
            crashReporter.capture("Catalog version probe failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Sync operations

    func syncProfile(_ profile: UserProfile) {
        guard let remoteSync, isRemoteSyncEnabled else { return }
        let profileToSave = profile
        Task {
            do {
                try await remoteSync.saveProfile(profileToSave)
            } catch {
                self.crashReporter.capture("Failed saving remote profile: \(error.localizedDescription)")
            }
        }
    }

    func syncFavorites(userID: String, itemIDs: [String]) {
        guard let remoteSync, isRemoteSyncEnabled else { return }
        Task {
            do {
                try await remoteSync.replaceFavorites(userID: userID, itemIDs: itemIDs)
            } catch {
                self.crashReporter.capture("Failed syncing favorites: \(error.localizedDescription)")
            }
        }
    }

    func syncHistoryEntry(userID: String, entry: SearchHistoryEntry) {
        guard let remoteSync, isRemoteSyncEnabled else { return }
        Task {
            do {
                try await remoteSync.saveHistoryEntry(userID: userID, entry: entry)
            } catch {
                self.crashReporter.capture("Failed syncing history entry: \(error.localizedDescription)")
            }
        }
    }

    func syncFeedbackEntry(userID: String, entry: UserFeedback) {
        guard let remoteSync, isRemoteSyncEnabled else { return }
        Task {
            do {
                try await remoteSync.saveFeedbackEntry(userID: userID, entry: entry)
            } catch {
                self.crashReporter.capture("Failed syncing feedback entry: \(error.localizedDescription)")
            }
        }
    }

    func syncServedRecommendations(_ recommendations: [ServedRecommendation]) {
        guard let remoteSync, isRemoteSyncEnabled else { return }
        Task {
            do {
                try await remoteSync.saveServedRecommendations(recommendations)
            } catch {
                self.crashReporter.capture("Failed syncing served recommendations: \(error.localizedDescription)")
            }
        }
    }

    func seedRemoteStateIfNeeded(
        snapshot: RemoteBootstrapSnapshot,
        userID: String,
        favorites: [String],
        history: [SearchHistoryEntry],
        feedback: [UserFeedback]
    ) async {
        guard let remoteSync else { return }

        do {
            if snapshot.favoriteItemIDs.isEmpty, !favorites.isEmpty {
                try await remoteSync.replaceFavorites(userID: userID, itemIDs: favorites)
            }

            if snapshot.historyEntries.isEmpty, !history.isEmpty {
                for entry in history {
                    try await remoteSync.saveHistoryEntry(userID: userID, entry: entry)
                }
            }

            if snapshot.feedbackEntries.isEmpty, !feedback.isEmpty {
                for entry in feedback {
                    try await remoteSync.saveFeedbackEntry(userID: userID, entry: entry)
                }
            }
        } catch {
            crashReporter.capture("Failed seeding remote state: \(error.localizedDescription)")
        }
    }
}
