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
                           keyDecodingStrategry: KeyDecodingStrategy = .useDefaultKeys,
                           cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                           enableLogging: Bool = true) async throws -> T {
        let url = try urlString.buildURL(queryParams: queryParams)
        let urlRequest = createURLRequest(url: url, method: "GET", cachePolicy: cachePolicy, headers: headers)
        
        if enableLogging {
            logger.logRequest(urlRequest)
        }
        
        do {
            let (data, response) = try await self.data(for: urlRequest)
            if enableLogging {
                logger.logResponse(response, data: data)
            }
            
            try response.checkValidity()
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
            
            try response.checkValidity()
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
    
    func post<T: Encodable>(_ urlString: String,
                            body: T,
                            headers: Headers,
                            queryParams: QueryParams? = nil,
                            keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys,
                            enableLogging: Bool = true) async throws {
        let url = try urlString.buildURL(queryParams: queryParams)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        let body = try encoder.encode(body)
        let urlRequest = createURLRequest(url: url, method: "POST", body: body, headers: headers)
        
        if enableLogging {
            logger.logRequest(urlRequest)
        }
        
        do {
            let (_, response) = try await self.data(for: urlRequest)
            
            if enableLogging {
                logger.logResponse(response, data: Data())
            }
            
            try response.checkValidity()
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
            
            try response.checkValidity()
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
                                  cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                  headers: Headers) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.httpBody = body
        urlRequest.cachePolicy = cachePolicy
        urlRequest.set(headers: headers)
        
        return urlRequest
    }
}
