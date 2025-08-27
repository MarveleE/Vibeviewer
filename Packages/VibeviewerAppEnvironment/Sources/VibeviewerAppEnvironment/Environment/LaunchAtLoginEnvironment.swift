import SwiftUI
import VibeviewerCore

private struct LaunchAtLoginServiceKey: EnvironmentKey {
    static let defaultValue: any LaunchAtLoginService = DefaultLaunchAtLoginService()
}

public extension EnvironmentValues {
    var launchAtLoginService: any LaunchAtLoginService {
        get { self[LaunchAtLoginServiceKey.self] }
        set { self[LaunchAtLoginServiceKey.self] = newValue }
    }
}