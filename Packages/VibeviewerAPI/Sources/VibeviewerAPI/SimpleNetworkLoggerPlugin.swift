import Foundation
import Moya

final class SimpleNetworkLoggerPlugin {}

// MARK: - PluginType

extension SimpleNetworkLoggerPlugin: PluginType {
  func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
    var loggings: [String] = []

    let targetType: TargetType.Type
    if let multiTarget = target as? MultiTarget {
      targetType = type(of: multiTarget.target)
    } else {
      targetType = type(of: target)
    }

    loggings.append("Request: \(targetType) [\(Date())]")

    switch result {
    case let .success(success):
      loggings
        .append(
          "URL: \(success.request?.url?.absoluteString ?? target.baseURL.absoluteString + target.path)"
        )
      loggings.append("Method: \(target.method.rawValue)")
      if let output = success.request?.httpBody?.toPrettyPrintedJSONString() {
        loggings.append("Request body: \n\(output)")
      }
      loggings.append("Status Code: \(success.statusCode)")

      if let output = success.data.toPrettyPrintedJSONString() {
        loggings.append("Response: \n\(output)")
      } else if let string = String(data: success.data, encoding: .utf8) {
        loggings.append("Response: \(string)")
      } else {
        loggings.append("Response: \(success.data)")
      }

    case let .failure(failure):
      loggings
        .append(
          "URL: \(failure.response?.request?.url?.absoluteString ?? target.baseURL.absoluteString + target.path)"
        )
      loggings.append("Method: \(target.method.rawValue)")
      if let output = failure.response?.request?.httpBody?.toPrettyPrintedJSONString() {
        loggings.append("Request body: \n\(output)")
      }
      if let errorResponseCode = failure.response?.statusCode {
        loggings.append("Error Code: \(errorResponseCode)")
      } else {
        loggings.append("Error Code: \(failure.errorCode)")
      }

      if let errorOutput = failure.response?.data.toPrettyPrintedJSONString() {
        loggings.append("Error Response: \n\(errorOutput)")
      }

      loggings.append("Error detail: \(failure.localizedDescription)")
    }

    loggings = loggings.map { "🔵 " + $0 }
    let seperator = "==================================================================="
    loggings.insert(seperator, at: 0)
    loggings.append(seperator)
    loggings.forEach { print($0) }
  }
}
