import Foundation
import Moya

public protocol DecodableTargetType: TargetType {
    associatedtype ResultType: Decodable

    var decodeAtKeyPath: String? { get }
}

public extension DecodableTargetType {
    var decodeAtKeyPath: String? { nil }

    var validationType: ValidationType {
        .successCodes
    }
}
