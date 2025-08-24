import Alamofire
import Combine
import Foundation
import Moya

enum GroNetwork {
    private static var _provider: MoyaProvider<MultiTarget>?

    static var provider: MoyaProvider<MultiTarget> {
        if _provider == nil {
            _provider = createProvider()
        }
        return _provider!
    }

    private static func createProvider() -> MoyaProvider<MultiTarget> {
        var plugins: [PluginType] = []
//        plugins.append(SimpleNetworkLoggerPlugin())
        plugins.append(RequestErrorHandlingPlugin())

        let session = createSession()
        return MoyaProvider<MultiTarget>(session: session, plugins: plugins)
    }

    private static func createSession() -> Session {
        let manager = ServerTrustManager(
            evaluators: ServerAccountManager.shared.serverTrustEvaluators)
        let configuration = URLSessionConfiguration.af.default
        return Session(configuration: configuration, serverTrustManager: manager)
    }

    static func updateSession() {
        _provider = createProvider()
    }

    // 用来防止mockprovider释放
    private static var _mockProvider: MoyaProvider<MultiTarget>!

    static func mockProvider(_ reponseType: MockResponseType) -> MoyaProvider<MultiTarget> {
        let plugins = [NetworkLoggerPlugin(configuration: .init(logOptions: .successResponseBody))]
        let endpointClosure: (MultiTarget) -> Endpoint =
            switch reponseType {
            case let .success(data):
                { (target: MultiTarget) -> Endpoint in
                    Endpoint(
                        url: URL(target: target).absoluteString,
                        sampleResponseClosure: { .networkResponse(200, data ?? target.sampleData) },
                        method: target.method,
                        task: target.task,
                        httpHeaderFields: target.headers
                    )
                }
            case let .failure(error):
                { (target: MultiTarget) -> Endpoint in
                    Endpoint(
                        url: URL(target: target).absoluteString,
                        sampleResponseClosure: {
                            .networkError(error ?? NSError(domain: "mock error", code: -1))
                        },
                        method: target.method,
                        task: target.task,
                        httpHeaderFields: target.headers
                    )
                }
            }
        let provider = MoyaProvider<MultiTarget>(
            endpointClosure: endpointClosure,
            stubClosure: MoyaProvider.delayedStub(2),
            plugins: plugins
        )
        _mockProvider = provider
        return provider
    }

    enum MockResponseType {
        case success(Data?)
        case failure(NSError?)
    }

    enum ProviderType {
        case normal
        case mockSuccess(Data?)
        case mockFailure(NSError?)
    }

    @discardableResult
    static func decodableRequest<T: DecodableTargetType>(
        providerType: ProviderType = .normal,
        _ target: T,
        callbackQueue: DispatchQueue? = nil,
        completion: @escaping (_ result: Result<T.ResultType, Error>) -> Void
    ) -> Moya.Cancellable {
        let provider: MoyaProvider<MultiTarget> =
            switch providerType {
            case .normal:
                self.provider
            case let .mockSuccess(data):
                mockProvider(.success(data))
            case let .mockFailure(error):
                mockProvider(.failure(error))
            }
        return provider.decodableRequest(
            target, callbackQueue: callbackQueue, completion: completion)
    }

    static func decodableRequest<T: DecodableTargetType>(
        providerType: ProviderType = .normal,
        _ target: T,
        callbackQueue: DispatchQueue? = nil
    ) -> AnyPublisher<T.ResultType, Error> {
        let provider: MoyaProvider<MultiTarget> =
            switch providerType {
            case .normal:
                self.provider
            case let .mockSuccess(data):
                mockProvider(.success(data))
            case let .mockFailure(error):
                mockProvider(.failure(error))
            }
        return provider.decodableRequest(target, callbackQueue: callbackQueue)
    }

    @discardableResult
    static func request(
        providerType: ProviderType = .normal,
        _ target: some TargetType,
        callbackQueue: DispatchQueue? = nil,
        progressHandler: ProgressBlock? = nil,
        completion: @escaping (_ result: Result<Data, Error>) -> Void
    ) -> Moya.Cancellable {
        let provider: MoyaProvider<MultiTarget> =
            switch providerType {
            case .normal:
                self.provider
            case let .mockSuccess(data):
                mockProvider(.success(data))
            case let .mockFailure(error):
                mockProvider(.failure(error))
            }
        return
            provider
            .request(MultiTarget(target), callbackQueue: callbackQueue, progress: progressHandler) {
                result in
                switch result {
                case let .success(rsp):
                    completion(.success(rsp.data))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
    }

    // Async

    static func decodableRequest<T: DecodableTargetType>(_ target: T) async throws -> T.ResultType {
        try await withCheckedThrowingContinuation { continuation in
            GroNetwork.decodableRequest(target, callbackQueue: nil) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    @discardableResult
    static func request(_ target: some TargetType, progressHandler: ProgressBlock? = nil)
        async throws -> Data?
    {
        try await withCheckedThrowingContinuation { continuation in
            GroNetwork.request(target, callbackQueue: nil, progressHandler: progressHandler) {
                result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
