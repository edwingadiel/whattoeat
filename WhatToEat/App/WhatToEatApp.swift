import SwiftUI

@main
struct WhatToEatApp: App {
    @StateObject private var store = AppStore.live()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .preferredColorScheme(.light)
        }
    }
}
