import SwiftUI
import VibeviewerAPI
import VibeviewerLoginUI

private struct CursorServiceKey: EnvironmentKey {
    static let defaultValue: CursorService = DefaultCursorService()
}

private struct LoginWindowManagerKey: EnvironmentKey {
    static let defaultValue: LoginWindowManager = .shared
}

public extension EnvironmentValues {
    var cursorService: CursorService {
        get { self[CursorServiceKey.self] }
        set { self[CursorServiceKey.self] = newValue }
    }

    var loginWindowManager: LoginWindowManager {
        get { self[LoginWindowManagerKey.self] }
        set { self[LoginWindowManagerKey.self] = newValue }
    }
}
