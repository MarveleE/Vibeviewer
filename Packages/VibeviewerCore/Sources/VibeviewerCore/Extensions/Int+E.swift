import Foundation

public extension Int {
    var dollarStringFromCents: String {
        "$" + String(format: "%.2f", Double(self) / 100.0)
    }
}
