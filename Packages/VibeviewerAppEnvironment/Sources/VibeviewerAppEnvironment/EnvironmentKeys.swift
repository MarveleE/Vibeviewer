import SwiftUI
import VibeviewerAPI
import VibeviewerLoginUI

private struct CursorServiceKey: EnvironmentKey {
  static let defaultValue: CursorService = DefaultCursorService()
}

private struct LoginWindowManagerKey: EnvironmentKey {
  static let defaultValue: LoginWindowManager = .shared
}

extension EnvironmentValues {
  public var cursorService: CursorService {
    get { self[CursorServiceKey.self] }
    set { self[CursorServiceKey.self] = newValue }
  }

  public var loginWindowManager: LoginWindowManager {
    get { self[LoginWindowManagerKey.self] }
    set { self[LoginWindowManagerKey.self] = newValue }
  }
}
