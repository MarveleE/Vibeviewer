import Alamofire
import Foundation
import Moya

struct RequestErrorWrapper {
    let moyaError: MoyaError

    var afError: AFError? {
        if case let .underlying(error as AFError, _) = moyaError {
            return error
        }
        return nil
    }

    var nsError: NSError? {
        if case let .underlying(error as NSError, _) = moyaError {
            return error
        } else if let afError {
            return afError.underlyingError as? NSError
        }
        return nil
    }

    var isRequestCancelled: Bool {
        if case .explicitlyCancelled = self.afError {
            return true
        }
        return false
    }

    var defaultErrorMessage: String? {
        if self.nsError?.code == NSURLErrorTimedOut {
            "加载数据失败，请稍后重试"
        } else if self.nsError?.code == NSURLErrorNotConnectedToInternet {
            "无网络连接，请检查网络"
        } else {
            "加载数据失败，请稍后重试"
        }
    }
}

protocol RequestErrorHandlable {
    var errorHandlingType: RequestErrorHandlingPlugin.RequestErrorHandlingType { get }
}

extension RequestErrorHandlable {
    var errorHandlingType: RequestErrorHandlingPlugin.RequestErrorHandlingType {
        .all
    }
}

class RequestErrorHandlingPlugin {
    enum RequestErrorHandlingType {
        enum FilterResult {
            case handledByPlugin(message: String?)
            case shouldNotHandledByPlugin
        }

        case connectionError // 现在包括超时和断网错误
        case all
        case allWithFilter(filter: (RequestErrorWrapper) -> FilterResult)

        func handleError(_ error: RequestErrorWrapper, handler: (_ shouldHandle: Bool, _ message: String?) -> Void) {
            switch self {
            case .connectionError:
                if error.nsError?.code == NSURLErrorTimedOut {
                    handler(true, error.defaultErrorMessage)
                } else if error.nsError?.code == NSURLErrorNotConnectedToInternet {
                    handler(true, error.defaultErrorMessage)
                }
            case .all:
                handler(true, error.defaultErrorMessage)
            case let .allWithFilter(filter):
                switch filter(error) {
                case let .handledByPlugin(messsage):
                    handler(true, messsage ?? error.defaultErrorMessage)
                case .shouldNotHandledByPlugin:
                    handler(false, nil)
                }
            }
            handler(false, nil)
        }
    }
}

extension RequestErrorHandlingPlugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        request.timeoutInterval = 30
        return request
    }

    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        let requestErrorHandleSubject: RequestErrorHandlable? =
            ((target as? MultiTarget)?.target as? RequestErrorHandlable)
                ?? (target as? RequestErrorHandlable)

        guard let requestErrorHandleSubject, case let .failure(moyaError) = result else { return }

        let errorWrapper = RequestErrorWrapper(moyaError: moyaError)
        if errorWrapper.isRequestCancelled {
            return
        }

        requestErrorHandleSubject.errorHandlingType.handleError(errorWrapper) { shouldHandle, message in
            if shouldHandle, let message, !message.isEmpty {
                // show error
            }
        }
    }
}
