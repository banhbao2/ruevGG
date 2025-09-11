import SwiftUI

struct DesignSystem {
    struct Colors {
        static let primaryBackground = Color(hex: "0F2E2E")
        static let primaryAccent = Color(hex: "00D2FF")
        static let amber = Color(hex: "FFB547")
        static let victoryGreen = Color(hex: "28D17C")
        static let lossRed = Color(hex: "FF4D4D")
        static let cardBackground = Color(hex: "1C1C1C")
        static let secondaryText = Color(hex: "A5B2B8")
        static let darkGray = Color(hex: "2A2A2A")
    }
    
    struct Spacing {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 16
        static let md: CGFloat = 24
        static let lg: CGFloat = 32
        static let xl: CGFloat = 48
    }
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 24
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.large)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(DesignSystem.Colors.primaryAccent)
            .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}
