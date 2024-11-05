//
//  Data+Extensions.swift
//  HTTPClient
//
//  Created by Eilon Krauthammer on 05/11/2024.
//

import Foundation

extension Data {
    func prettyJSON() -> String? {
        let json = try? JSONSerialization.jsonObject(with: self) as? [String: Any]
        if let json {
            let jsonString = String(data: try! JSONSerialization.data(withJSONObject: json,
                                                                      options: .prettyPrinted),
                                    encoding: .utf8)!
            return jsonString
        }
        
        return nil
    }
}
