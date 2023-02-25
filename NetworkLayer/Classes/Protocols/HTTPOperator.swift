//
//  HTTPOperator.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 07.02.2023.
//

import Foundation

public protocol HTTPOperator {
    var refreshTokenEndPointProvider: RefreshTokenEndPointProvider { get }
    var tokenDecorator: TokenDecorator { get }
    var tokenInterpreter: TokenInterpreter.Type { get }
    var delegate: HTTPOperatorDelegate? { get set }

    func sendRequest(_ request: Network.RequestItem)
    func cancelAllRequests()
    func setToken(_ rawToken: String)
    func clearToken()
}
