//
//  HTTPOperatorDelegate.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 25.02.2023.
//

import Foundation

public protocol HTTPOperatorDelegate: AnyObject {
    func didUpdateTokens(_ operator: HTTPOperator, from oldAccessToken: String, to newAccessToken: String, new refreshToken: String)
}
