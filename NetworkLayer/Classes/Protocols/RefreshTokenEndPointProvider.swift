//
//  RefreshTokenEndPointProvider.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 08.02.2023.
//

import Foundation

public protocol RefreshTokenEndPointProvider {
    var endPoint: RequestConvertible { get }
}
