import SwiftUI

private struct LoginWindowManagerKey: EnvironmentKey {
    static let defaultValue: LoginWindowManager = .shared
}

public extension EnvironmentValues {
    var loginWindowManager: LoginWindowManager {
        get { self[LoginWindowManagerKey.self] }
        set { self[LoginWindowManagerKey.self] = newValue }
    }
}
