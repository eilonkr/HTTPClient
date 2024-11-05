//
//  Headers+Extensions.swift
//  HTTPClient
//
//  Created by Eilon Krauthammer on 05/11/2024.
//

extension Headers {
    func formatted() -> String {
        reduce("") { partialResult, keyValuePair in
            return partialResult.appending("\(keyValuePair.key): \(keyValuePair.value)\n")
        }
    }
}
