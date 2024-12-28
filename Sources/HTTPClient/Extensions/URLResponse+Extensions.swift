//
//  URLResponse+Extensions.swift
//  HTTPClient
//
//  Created by Eilon Krauthammer on 28/12/2024.
//

import Foundation

extension URLResponse {
    var code: Int {
        return (self as? HTTPURLResponse)?.statusCode ?? -1
    }
    
    var isSuccess: Bool {
        return (200..<299) ~= code
    }
    
    func checkValidity() throws {
        if !isSuccess {
            throw NSError(domain: "", code: code)
        }
    }
}
