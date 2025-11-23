import Foundation

/// Cursor API 返回的当前计费周期响应 DTO
struct CursorCurrentBillingCycleResponse: Decodable, Sendable, Equatable {
    let startDateEpochMillis: String
    let endDateEpochMillis: String
    
    init(
        startDateEpochMillis: String,
        endDateEpochMillis: String
    ) {
        self.startDateEpochMillis = startDateEpochMillis
        self.endDateEpochMillis = endDateEpochMillis
    }
}

