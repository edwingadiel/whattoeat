import SwiftUI

enum AppTheme {
    static let background = Color(hex: "F5EFE6")
    static let surface = Color.white.opacity(0.8)
    static let ink = Color(hex: "1E2A2F")
    static let mutedInk = Color(hex: "536166")
    static let accent = Color(hex: "E86A33")
    static let accentSoft = Color(hex: "F5C9A9")
    static let teal = Color(hex: "3C7A71")
    static let tealSoft = Color(hex: "D6EBE4")
    static let border = Color.black.opacity(0.08)
    static let warning = Color(hex: "A64B2A")
    static let gold = Color(hex: "C79A3B")

    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "F7F1E8"), Color(hex: "E7EFEA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
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
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
    }
}
