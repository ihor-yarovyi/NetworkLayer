//
//  Operator+Request.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 6/29/21.
//

import Foundation

public extension Network.Operator {
    final class Request {
        
        // MARK: - Public Properties
        public let id: UUID
        
        // MARK: - Internal Properties
        let api: RequestConvertible
        var urlRequest: URLRequest
        var completion: ((Result<Data, Error>) -> Void)?
        let progress: ((Progress) -> Void)?
        
        // MARK: - Lifecycle
        init(id: UUID,
             baseURL: URL,
             api: RequestConvertible,
             completion: ((Result<Data, Error>) -> Void)? = nil,
             progress: ((Progress) -> Void)? = nil) throws {
            self.id = id
            self.api = api
            self.urlRequest = try Request.makeURLRequest(for: api, baseURL: baseURL)
            self.completion = completion
            self.progress = progress
        }
        
        func onComplete(with result: Result<Data, Error>) {
            completion?(result)
        }
        
        private static func makeURLRequest(for target: RequestConvertible, baseURL: URL) throws -> URLRequest {
            let url = (target.baseURL ?? baseURL).appendingPathComponent(target.path)
            var request = URLRequest(url: url)
            request = try request.encoded(for: target, with: url)
            request.httpMethod = target.method.rawValue
            request.timeoutInterval = target.timeout
            target.headers.forEach { request.setValue("\($1)", forHTTPHeaderField: $0) }
            return request
        }
    }
}
