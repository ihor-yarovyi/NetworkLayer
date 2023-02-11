//
//  RequestConvertible.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 6/29/21.
//

import Foundation

public protocol RequestConvertible {
    /// Base URL for request, takes precedence over `baseURL` in `Network` if specified.
    var baseURL: URL? { get }
    
    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String { get }
    
    /// The HTTP method used in the request.
    var method: Network.Method { get }

    /// The type of HTTP task to be performed.
    var task: Network.Task { get }
    
    /// The headers to be used in the request.
    var headers: [String: Any] { get }
    
    /// The timeout of request executing
    var timeout: TimeInterval { get }
    
    /// Specify the authorization strategy for requests
    var authorizationStrategy: Network.AuthorizationStrategy? { get }
}

public extension RequestConvertible {
    var baseURL: URL? { nil }
    var headers: [String: Any] { [:] }
    var timeout: TimeInterval { 30 }
    var authorizationStrategy: Network.AuthorizationStrategy? { .token }
}
