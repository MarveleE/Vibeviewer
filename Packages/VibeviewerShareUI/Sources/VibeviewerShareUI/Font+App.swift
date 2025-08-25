import SwiftUI

public enum AppFont: String, CaseIterable {
    case satoshiRegular = "Satoshi-Regular"
    case satoshiMedium = "Satoshi-Medium"
    case satoshiBold = "Satoshi-Bold"
    case satoshiItalic = "Satoshi-Italic"
}

public extension Font {
    /// Create a Font from AppFont with given size and optional relative weight.
    static func app(_ font: AppFont, size: CGFloat, weight: Weight? = nil) -> Font {
        FontsRegistrar.registerAllFonts()
        let f = Font.custom(font.rawValue, size: size)
        if let weight {
            return f.weight(weight)
        }
        return f
    }

    /// Convenience semantic fonts
    static func appTitle(_ size: CGFloat = 20) -> Font { .app(.satoshiBold, size: size) }
    static func appBody(_ size: CGFloat = 15) -> Font { .app(.satoshiRegular, size: size) }
    static func appEmphasis(_ size: CGFloat = 15) -> Font { .app(.satoshiMedium, size: size) }
    static func appCaption(_ size: CGFloat = 12) -> Font { .app(.satoshiRegular, size: size) }
}
