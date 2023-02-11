//
//  Request.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 08.02.2023.
//

import Foundation

extension Network {
    struct Request {
        let requestConvertible: RequestConvertible
        var urlRequest: URLRequest

        init(requestConvertible: RequestConvertible, baseURL: URL) throws {
            self.requestConvertible = requestConvertible
            self.urlRequest = try .makeURLRequest(from: requestConvertible, baseURL: baseURL)
        }
    }
}

private extension URLRequest {
    static func makeURLRequest(from requestConvertible: RequestConvertible, baseURL: URL) throws -> URLRequest {
        let url = (requestConvertible.baseURL ?? baseURL).appendingPathComponent(requestConvertible.path)
        var request = URLRequest(url: url)
        request = try request.encoded(for: requestConvertible, with: url)
        request.httpMethod = requestConvertible.method.rawValue
        request.timeoutInterval = requestConvertible.timeout
        requestConvertible.headers.forEach { request.setValue("\($1)", forHTTPHeaderField: $0) }
        return request
    }
}
