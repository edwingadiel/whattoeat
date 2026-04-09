import Foundation
import RevenueCat

final class RevenueCatSubscriptionService: SubscriptionProviding, @unchecked Sendable {
    static let entitlementID = "plus"
    private let fallback = LocalSubscriptionService()

    init(apiKey: String) {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey)
    }

    func currentEntitlement() -> UserEntitlement {
        guard let info = Purchases.shared.cachedCustomerInfo else {
            return fallback.currentEntitlement()
        }
        return entitlement(from: info)
    }

    func fetchOfferings() async -> [ProductOffering] {
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let current = offerings.current else {
                return [.defaultMonthly, .defaultAnnual]
            }

            var results: [ProductOffering] = []

            if let monthly = current.monthly {
                results.append(ProductOffering(
                    product: .plusMonthly,
                    localizedPrice: monthly.storeProduct.localizedPriceString,
                    localizedPeriod: "month"
                ))
            }

            if let annual = current.annual {
                results.append(ProductOffering(
                    product: .plusAnnual,
                    localizedPrice: annual.storeProduct.localizedPriceString,
                    localizedPeriod: "year"
                ))
            }

            return results.isEmpty ? [.defaultMonthly, .defaultAnnual] : results
        } catch {
            return [.defaultMonthly, .defaultAnnual]
        }
    }

    func purchase(_ product: PurchaseProduct) async throws -> UserEntitlement {
        let offerings = try await Purchases.shared.offerings()
        guard let current = offerings.current else {
            throw PurchaseError.notConfigured
        }

        let package: Package? = switch product {
        case .plusMonthly: current.monthly
        case .plusAnnual: current.annual
        }

        guard let package else {
            throw PurchaseError.notConfigured
        }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                throw PurchaseError.cancelled
            }
            return entitlement(from: result.customerInfo)
        } catch let error as PurchaseError {
            throw error
        } catch {
            throw PurchaseError.unknown(error.localizedDescription)
        }
    }

    func restorePurchases() async throws -> UserEntitlement {
        do {
            let info = try await Purchases.shared.restorePurchases()
            return entitlement(from: info)
        } catch {
            throw PurchaseError.unknown(error.localizedDescription)
        }
    }

    private func entitlement(from info: CustomerInfo) -> UserEntitlement {
        guard let plusEntitlement = info.entitlements[Self.entitlementID],
              plusEntitlement.isActive else {
            return .free
        }

        let periodType: String? = switch plusEntitlement.periodType {
        case .normal:
            plusEntitlement.productIdentifier.contains("annual") ? "annual" : "monthly"
        case .trial: "trial"
        case .intro: "intro"
        @unknown default: nil
        }

        return UserEntitlement(
            isPlus: true,
            planName: "Plus",
            providerCustomerID: info.originalAppUserId,
            expiresAt: plusEntitlement.expirationDate,
            periodType: periodType
        )
    }
}
