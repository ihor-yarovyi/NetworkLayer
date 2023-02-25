//
//  HTTPOperatorDelegate.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 25.02.2023.
//

import Foundation

public protocol HTTPOperatorDelegate: AnyObject {
    func didRefresh(_ operator: HTTPOperator, from oldToken: String, to newToken: String)
}
