import Alamofire
import Foundation
import Moya

@available(iOS 13, macOS 10.15, tvOS 13, *)
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
    plugins.append(SimpleNetworkLoggerPlugin())
    plugins.append(RequestErrorHandlingPlugin())

    // 创建完全不验证 SSL 的配置
    let configuration = URLSessionConfiguration.af.default
    let session = Session(
      configuration: configuration,
      serverTrustManager: nil
    )

    return MoyaProvider<MultiTarget>(session: session, plugins: plugins)
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
    decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
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
      target,
      decodingStrategy: decodingStrategy,
      callbackQueue: callbackQueue,
      completion: completion
    )
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

  @discardableResult
  static func request(
    providerType: ProviderType = .normal,
    _ target: some TargetType,
    callbackQueue: DispatchQueue? = nil,
    progressHandler: ProgressBlock? = nil,
    completion: @escaping (_ result: Result<Response, Error>) -> Void
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
          completion(.success(rsp))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  // Async

  static func decodableRequest<T: DecodableTargetType>(
    _ target: T,
    decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
  ) async throws -> T.ResultType {
    try await withCheckedThrowingContinuation { continuation in
      GroNetwork.decodableRequest(decodingStrategy: decodingStrategy, target, callbackQueue: nil) {
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

  @discardableResult
  public static func request(_ target: some TargetType, progressHandler: ProgressBlock? = nil)
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
