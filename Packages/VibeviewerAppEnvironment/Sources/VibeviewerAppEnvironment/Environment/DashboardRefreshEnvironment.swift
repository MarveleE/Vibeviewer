import SwiftUI

private struct DashboardRefreshServiceKey: EnvironmentKey {
    static let defaultValue: any DashboardRefreshService = NoopDashboardRefreshService()
}

public extension EnvironmentValues {
    var dashboardRefreshService: any DashboardRefreshService {
        get { self[DashboardRefreshServiceKey.self] }
        set { self[DashboardRefreshServiceKey.self] = newValue }
    }
}


