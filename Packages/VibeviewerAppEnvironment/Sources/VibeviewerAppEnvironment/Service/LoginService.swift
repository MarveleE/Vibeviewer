import Foundation
import VibeviewerAPI
import VibeviewerModel
import VibeviewerStorage

public enum LoginServiceError: Error, Equatable {
    case fetchAccountFailed
    case saveCredentialsFailed
    case initialRefreshFailed
}

public protocol LoginService: Sendable {
    /// 执行完整的登录流程：根据 Cookie 获取账号信息、保存凭据并触发 Dashboard 刷新
    @MainActor
    func login(with cookieHeader: String) async throws
}

/// 无操作实现，作为 Environment 的默认值
public struct NoopLoginService: LoginService {
    public init() {}
    @MainActor
    public func login(with cookieHeader: String) async throws {}
}

@MainActor
public final class DefaultLoginService: LoginService {
    private let api: CursorService
    private let storage: any CursorStorageService
    private let refresher: any DashboardRefreshService
    private let session: AppSession
    
    public init(
        api: CursorService,
        storage: any CursorStorageService,
        refresher: any DashboardRefreshService,
        session: AppSession
    ) {
        self.api = api
        self.storage = storage
        self.refresher = refresher
        self.session = session
    }
    
    public func login(with cookieHeader: String) async throws {
        // 记录登录前状态，用于首次登录失败时回滚
        let previousCredentials = self.session.credentials
        let previousSnapshot = self.session.snapshot
        
        // 1. 使用 Cookie 获取账号信息
        let me: Credentials
        do {
            me = try await self.api.fetchMe(cookieHeader: cookieHeader)
        } catch {
            throw LoginServiceError.fetchAccountFailed
        }
        
        // 2. 保存凭据并更新会话
        do {
            try await self.storage.saveCredentials(me)
            self.session.credentials = me
        } catch {
            throw LoginServiceError.saveCredentialsFailed
        }
        
        // 3. 启动后台刷新服务，让其负责拉取和写入 Dashboard 数据
        await self.refresher.start()
        
        // 4. 如果是首次登录且依然没有 snapshot，视为登录失败并回滚
        if previousCredentials == nil, previousSnapshot == nil, self.session.snapshot == nil {
            await self.storage.clearCredentials()
            await self.storage.clearDashboardSnapshot()
            self.session.credentials = nil
            self.session.snapshot = nil
            throw LoginServiceError.initialRefreshFailed
        }
    }
}


