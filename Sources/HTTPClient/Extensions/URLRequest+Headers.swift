//
//  URLRequest+Headers.swift
//  HTTPClient
//
//  Created by Eilon Krauthammer on 05/11/2024.
//

import Foundation

extension URLRequest {
    mutating func set(headers: Headers) {
        headers.forEach { name, value in
            setValue(value, forHTTPHeaderField: name)
        }
    }
}
