//
//  Error+Diagnostics.swift
//  HTTPClient
//
//  Created by Eilon Krauthammer on 06/09/2026.
//

import Foundation

extension Error {
    /// A description intended for logs, preserving details that `localizedDescription` drops.
    ///
    /// `DecodingError` does not conform to `LocalizedError`, so it bridges to a generic
    /// Cocoa error message such as "The data couldn't be read because it is missing",
    /// hiding the coding path and the offending key.
    var diagnosticDescription: String {
        if let decodingError = self as? DecodingError {
            return decodingError.diagnosticDescription
        }

        return localizedDescription
    }
}

extension DecodingError {
    var diagnosticDescription: String {
        switch self {
        case let .keyNotFound(key, context):
            return "Decoding failed: missing key '\(key.stringValue)' at \(context.codingPath.formattedPath). \(context.debugDescription)"
        case let .valueNotFound(type, context):
            return "Decoding failed: missing value of type \(type) at \(context.codingPath.formattedPath). \(context.debugDescription)"
        case let .typeMismatch(type, context):
            return "Decoding failed: type mismatch, expected \(type) at \(context.codingPath.formattedPath). \(context.debugDescription)"
        case let .dataCorrupted(context):
            return "Decoding failed: data corrupted at \(context.codingPath.formattedPath). \(context.debugDescription)"
        @unknown default:
            return "Decoding failed: \(localizedDescription)"
        }
    }
}

private extension [CodingKey] {
    /// The coding path as a key path string, e.g. `templateSections[0].templates[0]`.
    var formattedPath: String {
        guard !isEmpty else {
            return "root"
        }

        return reduce(into: "") { path, key in
            if let index = key.intValue {
                path += "[\(index)]"
            } else {
                path += path.isEmpty ? key.stringValue : ".\(key.stringValue)"
            }
        }
    }
}
