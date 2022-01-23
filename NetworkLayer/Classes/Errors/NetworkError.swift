//
//  NetworkError.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 6/29/21.
//

import Foundation

public extension Network {
    struct NetworkError: Error, LocalizedError {        
        public var status: Status
        public var code: Int { status.rawValue }
        public var jsonPayload: Any?
        
        public init(errorCode: Int) {
            status = Status(rawValue: errorCode) ?? .unknown
        }
        
        public init(status: Status) {
            self.status = status
        }
        
        public init(error: Error) {
            if let networkingError = error as? NetworkError {
                status = networkingError.status
                jsonPayload = networkingError.jsonPayload
            } else {
                if let theError = error as? URLError {
                    status = Status(rawValue: theError.errorCode) ?? .unknown
                } else {
                    status = .unknown
                }
            }
        }
        
        // for LocalizedError protocol
        public var errorDescription: String? {
            "\(status)"
        }
    }
}
