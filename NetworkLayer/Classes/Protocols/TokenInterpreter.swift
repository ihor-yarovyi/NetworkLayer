//
//  TokenInterpreter.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 08.02.2023.
//

import Foundation

public protocol TokenInterpreter: Codable {
    var accessToken: String { get }
    var refreshToken: String { get }
}
