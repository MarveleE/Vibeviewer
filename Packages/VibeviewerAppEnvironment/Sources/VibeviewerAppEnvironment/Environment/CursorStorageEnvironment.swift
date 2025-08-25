import SwiftUI
import VibeviewerModel

private struct CursorStorageKey: EnvironmentKey {
    static let defaultValue: CursorStorage = .shared
}

public extension EnvironmentValues {
    var cursorStorage: CursorStorage {
        get { self[CursorStorageKey.self] }
        set { self[CursorStorageKey.self] = newValue }
    }
}
