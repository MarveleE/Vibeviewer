import SwiftUI
import VibeviewerAPI

private struct CursorServiceKey: EnvironmentKey {
    static let defaultValue: CursorService = DefaultCursorService()
}

public extension EnvironmentValues {
    var cursorService: CursorService {
        get { self[CursorServiceKey.self] }
        set { self[CursorServiceKey.self] = newValue }
    }
}
