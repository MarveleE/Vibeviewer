import SwiftUI

private struct SettingsWindowManagerKey: EnvironmentKey {
  static let defaultValue: SettingsWindowManager = .shared
}

extension EnvironmentValues {
  public var settingsWindowManager: SettingsWindowManager {
    get { self[SettingsWindowManagerKey.self] }
    set { self[SettingsWindowManagerKey.self] = newValue }
  }
}
