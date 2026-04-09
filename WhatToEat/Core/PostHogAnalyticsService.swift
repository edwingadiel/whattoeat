import Foundation
import PostHog

final class PostHogAnalyticsService: AnalyticsTracking {
    init(apiKey: String, host: String?) {
        let config = PostHogConfig(apiKey: apiKey, host: host ?? "https://us.i.posthog.com")
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = true
        PostHogSDK.shared.setup(config)
    }

    func identify(userID: String, properties: [String: String] = [:]) {
        var userProperties: [String: Any] = [:]
        for (key, value) in properties {
            userProperties[key] = value
        }
        PostHogSDK.shared.identify(userID, userProperties: userProperties)
    }

    func track(_ event: String, properties: [String: String] = [:]) {
        var eventProperties: [String: Any] = [:]
        for (key, value) in properties {
            eventProperties[key] = value
        }
        PostHogSDK.shared.capture(event, properties: eventProperties)
    }

    func setUserProperties(_ properties: [String: String]) {
        var props: [String: Any] = [:]
        for (key, value) in properties {
            props[key] = value
        }
        PostHogSDK.shared.capture("$set", userProperties: props)
    }

    func flush() {
        PostHogSDK.shared.flush()
    }
}
