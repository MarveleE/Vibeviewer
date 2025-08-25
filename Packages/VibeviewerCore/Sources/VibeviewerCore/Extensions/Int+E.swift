import Foundation

public extension Int {
    var dollarStringFromCents: String {
        return "$" + String(format: "%.2f", Double(self) / 100.0)
    }
}