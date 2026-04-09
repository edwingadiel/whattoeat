import Foundation
import Sentry

final class SentryCrashReporter: CrashReporting {
    init(dsn: String) {
        SentrySDK.start { options in
            options.dsn = dsn
            options.tracesSampleRate = 0.2
            options.attachScreenshot = true
            options.enableMetricKit = true
            options.environment = Self.currentEnvironment
        }
    }

    func identify(userID: String) {
        let user = User(userId: userID)
        SentrySDK.setUser(user)
    }

    func capture(_ message: String) {
        let event = Event(level: .error)
        event.message = SentryMessage(formatted: message)
        SentrySDK.capture(event: event)

        SentrySDK.addBreadcrumb(Breadcrumb(level: .error, category: "app.error"))
    }

    func addBreadcrumb(category: String, message: String) {
        let crumb = Breadcrumb(level: .info, category: category)
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb)
    }

    private static var currentEnvironment: String {
        #if DEBUG
        "debug"
        #else
        "production"
        #endif
    }
}
