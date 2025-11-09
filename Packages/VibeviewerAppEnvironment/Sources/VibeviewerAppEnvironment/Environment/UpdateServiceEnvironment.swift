import SwiftUI

private struct UpdateServiceKey: EnvironmentKey {
    static let defaultValue: any UpdateService = NoopUpdateService()
}

public extension EnvironmentValues {
    var updateService: any UpdateService {
        get { self[UpdateServiceKey.self] }
        set { self[UpdateServiceKey.self] = newValue }
    }
}

