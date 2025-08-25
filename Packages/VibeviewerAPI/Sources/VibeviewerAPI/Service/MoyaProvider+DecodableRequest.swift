import Foundation
import Moya

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MoyaProvider where Target == MultiTarget {
    func decodableRequest<T: DecodableTargetType>(
        _ target: T,
        decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        callbackQueue: DispatchQueue? = nil,
        completion: @escaping (_ result: Result<T.ResultType, Error>) -> Void
    ) -> Moya.Cancellable {
        request(MultiTarget(target), callbackQueue: callbackQueue) { [weak self] result in
            switch result {
            case let .success(response):
                do {
                    let JSONDecoder = JSONDecoder()
                    JSONDecoder.keyDecodingStrategy = decodingStrategy
                    let responseObject = try response.map(
                        T.ResultType.self,
                        atKeyPath: target.decodeAtKeyPath,
                        using: JSONDecoder
                    )
                    completion(.success(responseObject))
                } catch {
                    completion(.failure(error))
                    self?.logDecodeError(error)
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func logDecodeError(_ error: Error) {
        print("===================================================================")
        print("🔴 Decode Error: \(error)")
        print("===================================================================")
    }
}
