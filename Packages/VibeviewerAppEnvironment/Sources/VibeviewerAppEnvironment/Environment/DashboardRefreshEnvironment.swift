import SwiftUI

private struct DashboardRefreshServiceKey: EnvironmentKey {
    static let defaultValue: any DashboardRefreshService = NoopDashboardRefreshService()
}

private struct ScreenPowerStateServiceKey: EnvironmentKey {
    static let defaultValue: any ScreenPowerStateService = NoopScreenPowerStateService()
}

public extension EnvironmentValues {
    var dashboardRefreshService: any DashboardRefreshService {
        get { self[DashboardRefreshServiceKey.self] }
        set { self[DashboardRefreshServiceKey.self] = newValue }
    }
    
    var screenPowerStateService: any ScreenPowerStateService {
        get { self[ScreenPowerStateServiceKey.self] }
        set { self[ScreenPowerStateServiceKey.self] = newValue }
    }
}


