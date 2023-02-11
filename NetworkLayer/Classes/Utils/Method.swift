//
//  Method.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 6/29/21.
//

import Foundation

public extension Network {
    enum Method: String {
        case get = "GET"
        case put = "PUT"
        case patch = "PATCH"
        case post = "POST"
        case delete = "DELETE"
    }
}
