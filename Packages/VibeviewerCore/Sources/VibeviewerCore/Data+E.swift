//
//  Data+E.swift
//  GroNetwork
//
//  Created by Groot chen on 2024/9/6.
//

import Foundation

extension Data {
    func toPrettyPrintedJSONString() -> String? {
        if let json = try? JSONSerialization.jsonObject(with: self),
           let data = try? JSONSerialization.data(
               withJSONObject: json,
               options: [.prettyPrinted, .withoutEscapingSlashes]
           )
        {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
