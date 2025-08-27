import Foundation
import Observation

/// 集成刷新服务和屏幕电源状态的协调器
@MainActor
@Observable
public final class PowerAwareDashboardRefreshService: DashboardRefreshService {
    private let refreshService: DefaultDashboardRefreshService
    private let screenPowerService: DefaultScreenPowerStateService
    
    public var isRefreshing: Bool { refreshService.isRefreshing }
    public var isPaused: Bool { refreshService.isPaused }
    
    public init(
        refreshService: DefaultDashboardRefreshService,
        screenPowerService: DefaultScreenPowerStateService
    ) {
        self.refreshService = refreshService
        self.screenPowerService = screenPowerService
        
        // 设置屏幕睡眠和唤醒回调
        screenPowerService.setOnScreenSleep { [weak self] in
            Task { @MainActor in
                self?.refreshService.pause()
            }
        }
        
        screenPowerService.setOnScreenWake { [weak self] in
            Task { @MainActor in
                await self?.refreshService.resume()
            }
        }
    }
    
    public func start() async {
        // 启动屏幕电源状态监控
        screenPowerService.startMonitoring()
        
        // 启动刷新服务
        await refreshService.start()
    }
    
    public func stop() {
        refreshService.stop()
        screenPowerService.stopMonitoring()
    }
    
    public func pause() {
        refreshService.pause()
    }
    
    public func resume() async {
        await refreshService.resume()
    }
    
    public func refreshNow() async {
        await refreshService.refreshNow()
    }
}