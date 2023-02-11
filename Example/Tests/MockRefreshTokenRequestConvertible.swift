//
//  MockRefreshTokenRequestConvertible.swift
//  Tests
//
//  Created by Ihor Yarovyi on 10.02.2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
@testable import NetworkLayer

struct MockRefreshTokenRequestConvertible: RequestConvertible {
    var path: String { "refresh/token" }
    var method: NetworkLayer.Network.Method { .post }
    var task: NetworkLayer.Network.Task { .requestPlain }
}
