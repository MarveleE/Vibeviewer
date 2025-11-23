import SwiftUI

private struct LoginServiceKey: EnvironmentKey {
    static let defaultValue: any LoginService = NoopLoginService()
}

public extension EnvironmentValues {
    var loginService: any LoginService {
        get { self[LoginServiceKey.self] }
        set { self[LoginServiceKey.self] = newValue }
    }
}


