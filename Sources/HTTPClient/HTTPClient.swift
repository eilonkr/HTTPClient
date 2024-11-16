//
//  HTTPClient.swift
//  HTTPClient
//
//  Created by Eilon Krauthammer on 14/07/2023.
//

import Foundation
import OSLog

public extension URLSession {
    private var logger: Logger {
        Logger(subsystem: "http-client", category: "http-client")
    }
    
    // MARK: - Public
    func get<T: Decodable>(_ urlString: String,
                           headers: Headers = [:],
                           queryParams: QueryParams? = nil,
                           keyDecodingStrategry: KeyDecodingStrategy = .useDefaultKeys, enableLogging: Bool = true) async throws -> T {
        let url = try urlString.buildURL(queryParams: queryParams)
        let urlRequest = createURLRequest(url: url, method: "GET", headers: headers)
        
        if enableLogging {
            logger.logRequest(urlRequest)
        }
        
        do {
            let (data, response) = try await self.data(for: urlRequest)
            if enableLogging {
                logger.logResponse(response, data: data)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = keyDecodingStrategry
            let result = try decoder.decode(T.self, from: data)
            return result
        } catch {
            if enableLogging {
                logger.logError(error)
            }
            
            throw error
        }
    }
    
    func post<T: Decodable, U: Encodable>(_ urlString: String,
                                          body: U,
                                          headers: Headers,
                                          queryParams: QueryParams? = nil,
                                          keyDecodingStrategry: KeyDecodingStrategy = .useDefaultKeys,
                                          keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys,
                                          enableLogging: Bool = true) async throws -> T {
        let url = try urlString.buildURL(queryParams: queryParams)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        let body = try encoder.encode(body)
        let urlRequest = createURLRequest(url: url, method: "POST", body: body, headers: headers)
        
        if enableLogging {
            logger.logRequest(urlRequest)
        }
        
        do {
            let (data, response) = try await self.data(for: urlRequest)
            
            if enableLogging {
                logger.logResponse(response, data: data)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = keyDecodingStrategry
            let result = try decoder.decode(T.self, from: data)
            return result
        } catch {
            if enableLogging {
                logger.logError(error)
            }
            
            throw error
        }
    }
    
    func delete(_ urlString: String,
                headers: Headers,
                enableLogging: Bool = true) async throws {
        let url = try urlString.buildURL(queryParams: nil)
        let urlRequest = createURLRequest(url: url, method: "DELETE", headers: headers)
        
        if enableLogging {
            logger.logRequest(urlRequest)
        }
        
        do {
            let (data, response) = try await self.data(for: urlRequest)
            if enableLogging {
                logger.logResponse(response, data: data)
            }
        } catch {
            if enableLogging {
                logger.logError(error)
            }
            
            throw error
        }
    }
    
    // MARK: - Private
    private func createURLRequest(url: URL,
                                  method: String,
                                  body: Data? = nil,
                                  headers: Headers) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.httpBody = body
        urlRequest.set(headers: headers)
        
        return urlRequest
    }
}
