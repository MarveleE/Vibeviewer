import SwiftUI

public enum AppFont: String, CaseIterable {
  case satoshiRegular = "Satoshi-Regular"
  case satoshiMedium = "Satoshi-Medium"
  case satoshiBold = "Satoshi-Bold"
  case satoshiItalic = "Satoshi-Italic"
}

extension Font {
  /// Create a Font from AppFont with given size and optional relative weight.
  public static func app(_ font: AppFont, size: CGFloat, weight: Weight? = nil) -> Font {
    FontsRegistrar.registerAllFonts()
    let f = Font.custom(font.rawValue, size: size)
    if let weight {
      return f.weight(weight)
    }
    return f
  }

  /// Convenience semantic fonts
  public static func appTitle(_ size: CGFloat = 20) -> Font { .app(.satoshiBold, size: size) }
  public static func appBody(_ size: CGFloat = 15) -> Font { .app(.satoshiRegular, size: size) }
  public static func appEmphasis(_ size: CGFloat = 15) -> Font { .app(.satoshiMedium, size: size) }
  public static func appCaption(_ size: CGFloat = 12) -> Font { .app(.satoshiRegular, size: size) }
}
