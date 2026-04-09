import Foundation

protocol AnalyticsTracking {
    func track(_ event: String, properties: [String: String])
}

protocol CrashReporting {
    func capture(_ message: String)
}

protocol AuthProviding {
    func anonymousUserID() -> String
}

protocol SubscriptionProviding {
    func currentEntitlement() -> UserEntitlement
    func purchasePlus() -> UserEntitlement
    func restorePurchases() -> UserEntitlement
}

protocol CatalogProviding {
    func loadCatalog() throws -> RestaurantCatalog
}

struct AppEnvironment {
    let analytics: AnalyticsTracking
    let crashReporter: CrashReporting
    let auth: AuthProviding
    let subscriptions: SubscriptionProviding
    let catalog: CatalogProviding
    let remoteSync: (any RemoteUserSyncing)?
}

struct ConsoleAnalyticsService: AnalyticsTracking {
    func track(_ event: String, properties: [String: String] = [:]) {
        print("[analytics]", event, properties)
    }
}

struct ConsoleCrashReporter: CrashReporting {
    func capture(_ message: String) {
        print("[crash]", message)
    }
}

final class LocalAuthService: AuthProviding {
    private let key = "whattoeat.userID"

    func anonymousUserID() -> String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: key)
        return created
    }
}

struct LocalSubscriptionService: SubscriptionProviding {
    private let key = "whattoeat.entitlement"

    func currentEntitlement() -> UserEntitlement {
        if let data = UserDefaults.standard.data(forKey: key),
           let entitlement = try? JSONDecoder().decode(UserEntitlement.self, from: data) {
            return entitlement
        }
        return .free
    }

    func purchasePlus() -> UserEntitlement {
        save(.plus)
        return .plus
    }

    func restorePurchases() -> UserEntitlement {
        currentEntitlement()
    }

    private func save(_ entitlement: UserEntitlement) {
        if let data = try? JSONEncoder().encode(entitlement) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct BundleCatalogService: CatalogProviding {
    func loadCatalog() throws -> RestaurantCatalog {
        guard let url = Bundle.main.url(forResource: "restaurant_seed", withExtension: "json") else {
            return .fallback
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(RestaurantCatalog.self, from: data)
    }
}

enum AppEnvironmentFactory {
    static func live() -> AppEnvironment {
        AppEnvironment(
            analytics: ConsoleAnalyticsService(),
            crashReporter: ConsoleCrashReporter(),
            auth: LocalAuthService(),
            subscriptions: LocalSubscriptionService(),
            catalog: BundleCatalogService(),
            remoteSync: SupabaseSyncService(configuration: SupabaseConfiguration.load())
        )
    }
}
