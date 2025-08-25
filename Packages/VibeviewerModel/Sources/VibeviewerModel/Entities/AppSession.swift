import Foundation
import Observation

@MainActor
@Observable
public final class AppSession {
    public var credentials: Credentials?
    public var snapshot: DashboardSnapshot?

    public init(credentials: Credentials? = nil, snapshot: DashboardSnapshot? = nil) {
        self.credentials = credentials
        self.snapshot = snapshot
    }
}
