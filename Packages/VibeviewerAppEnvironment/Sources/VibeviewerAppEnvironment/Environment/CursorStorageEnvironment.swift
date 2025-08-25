import SwiftUI
import VibeviewerStorage

private struct CursorStorageKey: EnvironmentKey {
    static let defaultValue: any CursorStorageService = DefaultCursorStorageService()
}

public extension EnvironmentValues {
    var cursorStorage: any CursorStorageService {
        get { self[CursorStorageKey.self] }
        set { self[CursorStorageKey.self] = newValue }
    }
}
