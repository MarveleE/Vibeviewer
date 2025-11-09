import SwiftUI

private struct SettingsWindowManagerKey: EnvironmentKey {
    @MainActor
    static var defaultValue: SettingsWindowManager {
        SettingsWindowManager.shared
    }
}

public extension EnvironmentValues {
    var settingsWindowManager: SettingsWindowManager {
        get { self[SettingsWindowManagerKey.self] }
        set { self[SettingsWindowManagerKey.self] = newValue }
    }
}
