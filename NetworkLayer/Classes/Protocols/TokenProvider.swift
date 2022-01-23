//
//  TokenProvider.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 7/12/21.
//

import Foundation

public protocol TokenProvider {
    var authorization: [String: String] { get set }
}
