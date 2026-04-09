import SwiftUI

enum AppTheme {
    // MARK: - Core palette
    static let background = Color(hex: "F5EFE6")
    static let surface = Color.white.opacity(0.82)
    static let ink = Color(hex: "1E2A2F")
    static let mutedInk = Color(hex: "6B7B80")
    static let accent = Color(hex: "E86A33")
    static let accentSoft = Color(hex: "FDE8D8")
    static let teal = Color(hex: "2D8C7F")
    static let tealSoft = Color(hex: "D6EBE4")
    static let border = Color.black.opacity(0.06)
    static let warning = Color(hex: "A64B2A")
    static let gold = Color(hex: "C79A3B")
    static let goldSoft = Color(hex: "FDF4E3")

    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "F7F1E8"), Color(hex: "E7EFEA")],
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

extension Color {
    init(hex: String) {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        let value = UInt64(sanitized, radix: 16) ?? 0
        let red = Double((value & 0xFF0000) >> 16) / 255
        let green = Double((value & 0x00FF00) >> 8) / 255
        let blue = Double(value & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

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
