//
//  HTTPClient.swift
//  HTTPClient
//
//  Created by Eilon Krauthammer on 14/07/2023.
//

import Foundation
import OSLog

public class HTTPClient {
    private static let logger = Logger(subsystem: "http-client", category: "http-client")
    
    // MARK: - Public
    public static func get<T: Decodable>(_ urlString: String,
                                         urlSession: URLSession = .shared,
                                         headers: Headers = [:],
                                         queryParams: QueryParams? = nil,
                                         keyDecodingStrategry: KeyDecodingStrategy = .useDefaultKeys, enableLogging: Bool = true) async throws -> T {
        let url = try urlString.buildURL(queryParams: queryParams)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.set(headers: headers)
        
        if enableLogging {
            logger.logRequest(urlRequest)
        }
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
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
    
    public static func post<T: Decodable, U: Encodable>(_ urlString: String,
                                                        urlSession: URLSession = .shared,
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
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body
        urlRequest.set(headers: headers)
        
        if enableLogging {
            logger.logRequest(urlRequest)
        }
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
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
    
    public static func delete(_ urlString: String,
                              urlSession: URLSession = .shared,
                              headers: Headers,
                              enableLogging: Bool = true) async throws {
        let url = try urlString.buildURL(queryParams: nil)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.set(headers: headers)
        
        if enableLogging {
            logger.logRequest(urlRequest)
        }
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
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
}
