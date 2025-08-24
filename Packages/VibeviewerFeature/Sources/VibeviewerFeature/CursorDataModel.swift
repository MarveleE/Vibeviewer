import Foundation
import Observation
import VibeviewerModel
import VibeviewerAPI

@MainActor
@Observable
public final class CursorDataModel {
    // Inputs
    private let service: CursorService
    private let storage = CursorStorage.shared

    // Persisted creds (nil means not logged in)
    public var credentials: CursorCredentials?

    // Derived UI snapshot
    public var snapshot: CursorDashboardSnapshot?

    // Loading/error states
    public var isLoading: Bool = false
    public var lastErrorMessage: String?

    // Timer management
    private var refreshTask: Task<Void, Never>?

    // Internal designated initializer allowing injection
    init(service: CursorService = DefaultCursorService()) {
        self.service = service
        Task { [weak self] in
            guard let self else { return }
            self.credentials = await storage.loadCredentials()
            if self.credentials != nil {
                await self.refresh()
                self.startAutoRefresh()
            }
        }
    }

    // Public convenience initializer for app usage
    public convenience init() {
        self.init(service: DefaultCursorService())
    }

    public func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refresh()
                try? await Task.sleep(for: .seconds(5 * 60))
            }
        }
    }

    public func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    public func setLoggedOut() async {
        await storage.clearCredentials()
        credentials = nil
        snapshot = nil
        stopAutoRefresh()
    }

    public func completeLogin(cookieHeader: String) async {
        // 1) fetch me
        isLoading = true
        lastErrorMessage = nil
        do {
            let me = try await service.fetchMe(cookieHeader: cookieHeader)

            // 2) fetch usage and spend
            let usage = try await service.fetchUsage(workosUserId: me.workosId, cookieHeader: cookieHeader)
            let spend = try await service.fetchTeamSpend(teamId: me.teamId, cookieHeader: cookieHeader)

            // 3) derive snapshot
            let planRequestsUsed = usage.models.values.map { $0.numRequests }.reduce(0, +)
            let totalAll = usage.models.values.map { $0.numRequestsTotal }.reduce(0, +)
            let mySpend = spend.teamMemberSpend.first { $0.userId == me.userId }
            let snapshot = CursorDashboardSnapshot(
                email: me.email,
                planRequestsUsed: planRequestsUsed,
                totalRequestsAllModels: totalAll,
                spendingCents: mySpend?.spendCents ?? 0,
                hardLimitDollars: mySpend?.hardLimitOverrideDollars ?? 0
            )

            // 4) persist creds
            let creds = CursorCredentials(
                userId: me.userId,
                workosId: me.workosId,
                email: me.email,
                teamId: me.teamId,
                cookieHeader: cookieHeader
            )
            try await storage.saveCredentials(creds)

            // 5) update state
            self.credentials = creds
            self.snapshot = snapshot
            self.startAutoRefresh()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func refresh() async {
        guard let creds = credentials else { return }
        isLoading = true
        lastErrorMessage = nil
        do {
            let usage = try await service.fetchUsage(workosUserId: creds.workosId, cookieHeader: creds.cookieHeader)
            let spend = try await service.fetchTeamSpend(teamId: creds.teamId, cookieHeader: creds.cookieHeader)

            let planRequestsUsed = usage.models.values.map { $0.numRequests }.reduce(0, +)
            let totalAll = usage.models.values.map { $0.numRequestsTotal }.reduce(0, +)
            let mySpend = spend.teamMemberSpend.first { $0.userId == creds.userId }
            self.snapshot = CursorDashboardSnapshot(
                email: creds.email,
                planRequestsUsed: planRequestsUsed,
                totalRequestsAllModels: totalAll,
                spendingCents: mySpend?.spendCents ?? 0,
                hardLimitDollars: mySpend?.hardLimitOverrideDollars ?? 0
            )
        } catch {
            if case CursorServiceError.sessionExpired = error {
                await setLoggedOut()
                lastErrorMessage = "会话已过期，请重新登录"
            } else {
                lastErrorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}


