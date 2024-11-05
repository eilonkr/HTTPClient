//
//  String+QueryParams.swift
//  HTTPClient
//
//  Created by Eilon Krauthammer on 05/11/2024.
//

import Foundation

extension String {
    func buildURL(queryParams: QueryParams?) throws -> URL {
        guard var urlComponents = URLComponents(string: self) else {
            throw URLError(.badURL)
        }
        
        if let queryParams {
            urlComponents.queryItems = queryParams.map(URLQueryItem.init)
        }
        
        let url = urlComponents.url!
        
        return url
    }
}
