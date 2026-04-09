import SwiftUI

struct RootView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                MainTabView(store: store)
            } else {
                OnboardingView(store: store)
            }
        }
        .sheet(item: $store.activePaywallReason) { reason in
            PaywallView(store: store, reason: reason)
        }
        .task {
            await store.bootstrap()
        }
    }
}

private struct MainTabView: View {
    @ObservedObject var store: AppStore

    init(store: AppStore) {
        self.store = store
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(AppTheme.background.opacity(0.95))
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            HomeView(store: store)
                .tabItem {
                    Label("Explore", systemImage: "sparkles")
                }

            FavoritesView(store: store)
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }

            ProfileView(store: store)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(AppTheme.accent)
    }
}
