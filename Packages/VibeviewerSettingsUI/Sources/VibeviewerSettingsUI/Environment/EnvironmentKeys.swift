import SwiftUI

private struct SettingsWindowManagerKey: EnvironmentKey {
    static let defaultValue: SettingsWindowManager = .shared
}

public extension EnvironmentValues {
    var settingsWindowManager: SettingsWindowManager {
        get { self[SettingsWindowManagerKey.self] }
        set { self[SettingsWindowManagerKey.self] = newValue }
    }
}
