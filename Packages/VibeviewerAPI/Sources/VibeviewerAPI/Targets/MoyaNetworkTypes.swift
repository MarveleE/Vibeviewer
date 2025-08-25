import Foundation
import Moya

protocol DecodableTargetType: TargetType {
    associatedtype ResultType: Decodable

    var decodeAtKeyPath: String? { get }
}

extension DecodableTargetType {
    var decodeAtKeyPath: String? { nil }

    var validationType: ValidationType {
        .successCodes
    }
}
