@testable import VibeviewerAPI
import XCTest

final class CursorTeamSpendAPITests: XCTestCase {
    func test_teamSpend_target_path_and_task() throws {
        let api = CursorTeamSpendAPI(teamId: 15_113_845, cookieHeader: "cookie")
        XCTAssertEqual(api.path, "/api/dashboard/get-team-spend")
        // Verify query params encoding contains teamId
        if case let .requestParameters(parameters, _) = api.task {
            XCTAssertEqual(parameters["teamId"] as? Int, 15_113_845)
        } else {
            XCTFail("Unexpected task type")
        }
    }

    func test_fetchTeamSpend_mapping_success() async throws {
        // Given a sample JSON from get_team_spend.txt
        let sampleJSON = """
        {
          "teamMemberSpend": [
            {"userId": 190534072, "email": "a@x.com", "role": "TEAM_ROLE_MEMBER", "hardLimitOverrideDollars": 20},
            {"userId": 190525724, "spendCents": 875, "fastPremiumRequests": 500, "email": "me@x.com", "role": "TEAM_ROLE_MEMBER", "hardLimitOverrideDollars": 20}
          ],
          "subscriptionCycleStart": "1754879994000",
          "totalMembers": 2,
          "totalPages": 1,
          "totalByRole": [{"role": "TEAM_ROLE_MEMBER", "count": 2}]
        }
        """.data(using: .utf8)!

        // Inject a mock network client via internal initializer
        struct MockClient: CursorNetworkClient {
            let data: Data
            func decodableRequest<T>(
                _ target: T,
                decodingStrategy: JSONDecoder.KeyDecodingStrategy
            ) async throws -> T.ResultType where T: DecodableTargetType {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = decodingStrategy
                return try decoder.decode(T.ResultType.self, from: self.data)
            }
        }

        let service = DefaultCursorService(network: MockClient(data: sampleJSON))
        let overview = try await service.fetchTeamSpend(teamId: 1, cookieHeader: "c")

        XCTAssertEqual(overview.subscriptionCycleStartMs, "1754879994000")
        XCTAssertEqual(overview.totalMembers, 2)
        XCTAssertEqual(overview.totalPages, 1)
        XCTAssertEqual(overview.totalByRole.count, 1)
        XCTAssertEqual(overview.totalByRole.first?.role, "TEAM_ROLE_MEMBER")
        XCTAssertEqual(overview.totalByRole.first?.count, 2)

        XCTAssertEqual(overview.members.count, 2)
        let me = overview.members.first { $0.email == "me@x.com" }
        XCTAssertNotNil(me)
        XCTAssertEqual(me?.spendCents, 875)
        XCTAssertEqual(me?.fastPremiumRequests, 500)
        XCTAssertEqual(me?.hardLimitOverrideDollars, 20)
    }
}
