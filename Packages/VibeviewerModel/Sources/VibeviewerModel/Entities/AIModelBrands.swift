import Foundation

public enum AIModelBrands: String, CaseIterable {
    case gpt
    case claude
    case deepseek
    case gemini
    case grok
    case kimi
    case `default`

    public static func brand(for modelName: String) -> AIModelBrands {
        for brand in AIModelBrands.allCases {
            if modelName.hasPrefix(brand.rawValue) {
                return brand
            }
        }
        return .default
    }
}