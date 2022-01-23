//
//  NetworkError+Common.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 6/29/21.
//

import Foundation

extension Network.NetworkError {
    
    public static var unableToParseResponse: Network.NetworkError {
        Network.NetworkError(status: .unableToParseResponse)
    }
    
    public static var unableToParseRequest: Network.NetworkError {
        Network.NetworkError(status: .unableToParseRequest)
    }
    
    public static var unknownError: Network.NetworkError {
        Network.NetworkError(status: .unknown)
    }
}
