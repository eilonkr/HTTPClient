//
//  Logger+Extensions.swift
//  HTTPClient
//
//  Created by Eilon Krauthammer on 05/11/2024.
//

import OSLog

extension Logger {
    func logRequest(_ request: URLRequest) {
        guard let url = request.url else {
            error("Request has no URL")
            return
        }
        
        info("""
        [🛫 Request Starting]:
        URL: \(url.absoluteString)
        Headers: \(request.allHTTPHeaderFields?.formatted() ?? "None")
        Body: \(request.httpBody?.prettyJSON() ?? "None")
        """)
    }
    
    func logResponse(_ response: URLResponse, data: Data) {
        guard let response = response as? HTTPURLResponse else {
            error("Response is not an HTTPURLResponse")
            return
        }
        
        guard let url = response.url else {
            error("Response has no URL")
            return
        }
        
        info("""
        [🛬 Request Response]:
        URL: \(url.absoluteString)
        Status: \(response.statusCode)
        Headers: \((response.allHeaderFields as? Headers)?.formatted() ?? "None")
        Data: \(data.prettyJSON() ?? "None")
        """)
    }
    
    func logError(_ error: Error) {
        self.error("""
        [🚫 Error]:
        \(error.localizedDescription)
        """)
    }
}
