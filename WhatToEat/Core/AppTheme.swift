import SwiftUI

enum AppTheme {
    // MARK: - Adaptive palette (light/dark)
    static let background = Color.adaptive(light: "F5EFE6", dark: "1A1A1E")
    static let surface = Color.adaptive(light: "FFFFFF", dark: "2C2C30", lightAlpha: 0.82, darkAlpha: 1.0)
    static let surfaceElevated = Color.adaptive(light: "FFFFFF", dark: "3A3A3E", lightAlpha: 0.9, darkAlpha: 1.0)
    static let ink = Color.adaptive(light: "1E2A2F", dark: "F0F0F2")
    static let mutedInk = Color.adaptive(light: "6B7B80", dark: "9CA3A8")
    static let border = Color.adaptive(light: "000000", dark: "FFFFFF", lightAlpha: 0.06, darkAlpha: 0.08)

    // MARK: - Brand colors (constant across modes)
    static let accent = Color(hex: "E86A33")
    static let accentSoft = Color(hex: "FDE8D8")
    static let teal = Color(hex: "2D8C7F")
    static let tealSoft = Color(hex: "D6EBE4")
    static let warning = Color(hex: "A64B2A")
    static let gold = Color(hex: "C79A3B")
    static let goldSoft = Color(hex: "FDF4E3")

    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        colors: [
            Color.adaptive(light: "F7F1E8", dark: "1A1A1E"),
            Color.adaptive(light: "E7EFEA", dark: "1E2024")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color(hex: "E86A33"), Color(hex: "D4522A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tealGradient = LinearGradient(
        colors: [Color(hex: "2D8C7F"), Color(hex: "1F6B61")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let premiumGradient = LinearGradient(
        colors: [Color(hex: "C79A3B"), Color(hex: "A67C2E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Shadows
    static let cardShadow: Color = Color.black.opacity(0.06)
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowY: CGFloat = 4

    // MARK: - Radii
    static let cardRadius: CGFloat = 20
    static let pillRadius: CGFloat = 14
    static let buttonRadius: CGFloat = 16
}

// MARK: - Color Helpers

extension Color {
    init(hex: String) {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        let value = UInt64(sanitized, radix: 16) ?? 0
        let red = Double((value & 0xFF0000) >> 16) / 255
        let green = Double((value & 0x00FF00) >> 8) / 255
        let blue = Double(value & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    /// Adaptive color that uses one hex value in light mode and another in dark mode
    static func adaptive(light: String, dark: String, lightAlpha: Double = 1.0, darkAlpha: Double = 1.0) -> Color {
        Color(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            let alpha = traits.userInterfaceStyle == .dark ? darkAlpha : lightAlpha
            let sanitized = hex.replacingOccurrences(of: "#", with: "")
            let value = UInt64(sanitized, radix: 16) ?? 0
            let r = CGFloat((value & 0xFF0000) >> 16) / 255
            let g = CGFloat((value & 0x00FF00) >> 8) / 255
            let b = CGFloat(value & 0x0000FF) / 255
            return UIColor(red: r, green: g, blue: b, alpha: alpha)
        })
    }
}

// MARK: - View Modifiers

extension View {
    func cardStyle(fill: Color = AppTheme.surface) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .fill(fill)
                    .shadow(color: AppTheme.cardShadow, radius: AppTheme.cardShadowRadius, x: 0, y: AppTheme.cardShadowY)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }

    func glassCard() -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .shadow(color: AppTheme.cardShadow, radius: AppTheme.cardShadowRadius, x: 0, y: AppTheme.cardShadowY)
    }
}
