import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    private let store: AppStore

    init(store: AppStore) {
        self.store = store
    }

    var planName: String {
        store.entitlement.planName
    }

    var isPlus: Bool {
        store.entitlement.isPlus
    }

    var isPurchasing: Bool {
        store.isPurchasing
    }

    func purchase() {
        Task { await store.purchase(.plusMonthly) }
    }

    func restore() {
        Task { await store.restorePurchases() }
    }
}
