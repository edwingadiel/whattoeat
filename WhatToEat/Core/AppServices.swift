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

protocol SubscriptionProviding: Sendable {
    func currentEntitlement() -> UserEntitlement
    func fetchOfferings() async -> [ProductOffering]
    func purchase(_ product: PurchaseProduct) async throws -> UserEntitlement
    func restorePurchases() async throws -> UserEntitlement
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

final class LocalSubscriptionService: SubscriptionProviding, @unchecked Sendable {
    private let key = "whattoeat.entitlement"

    func currentEntitlement() -> UserEntitlement {
        if let data = UserDefaults.standard.data(forKey: key),
           let entitlement = try? JSONDecoder().decode(UserEntitlement.self, from: data) {
            return entitlement
        }
        return .free
    }

    func fetchOfferings() async -> [ProductOffering] {
        [.defaultMonthly, .defaultAnnual]
    }

    func purchase(_ product: PurchaseProduct) async throws -> UserEntitlement {
        let entitlement = UserEntitlement(
            isPlus: true,
            planName: "Plus",
            providerCustomerID: "local-plus-user",
            periodType: product == .plusAnnual ? "annual" : "monthly"
        )
        save(entitlement)
        return entitlement
    }

    func restorePurchases() async throws -> UserEntitlement {
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
        let subscriptions: SubscriptionProviding = {
            if let apiKey = configValue("REVENUECAT_API_KEY") {
                return RevenueCatSubscriptionService(apiKey: apiKey)
            }
            return LocalSubscriptionService()
        }()

        let analytics: AnalyticsTracking = {
            if let apiKey = configValue("POSTHOG_API_KEY") {
                let host = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_HOST") as? String
                return PostHogAnalyticsService(apiKey: apiKey, host: host)
            }
            return ConsoleAnalyticsService()
        }()

        let crashReporter: CrashReporting = {
            if let dsn = configValue("SENTRY_DSN") {
                return SentryCrashReporter(dsn: dsn)
            }
            return ConsoleCrashReporter()
        }()

        return AppEnvironment(
            analytics: analytics,
            crashReporter: crashReporter,
            auth: LocalAuthService(),
            subscriptions: subscriptions,
            catalog: BundleCatalogService(),
            remoteSync: SupabaseSyncService(configuration: SupabaseConfiguration.load())
        )
    }

    private static func configValue(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
