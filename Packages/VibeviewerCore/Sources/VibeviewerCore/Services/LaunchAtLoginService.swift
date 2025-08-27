import Foundation
import ServiceManagement

public protocol LaunchAtLoginService {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) -> Bool
}

public final class DefaultLaunchAtLoginService: LaunchAtLoginService {
    public init() {}
    
    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    public func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled {
                    return true
                }
                try SMAppService.mainApp.register()
                return true
            } else {
                if SMAppService.mainApp.status != .enabled {
                    return true  
                }
                try SMAppService.mainApp.unregister()
                return true
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            return false
        }
    }
}