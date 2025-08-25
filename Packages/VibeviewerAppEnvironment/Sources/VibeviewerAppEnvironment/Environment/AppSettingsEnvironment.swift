import VibeviewerModel
import SwiftUI

public struct AppSettingsEnvironmentKey: EnvironmentKey {
    public static let defaultValue: AppSettings = AppSettings()
}

public extension EnvironmentValues {
    var appSettings: AppSettings {
        get { self[AppSettingsEnvironmentKey.self] }
        set { self[AppSettingsEnvironmentKey.self] = newValue }
    }
}