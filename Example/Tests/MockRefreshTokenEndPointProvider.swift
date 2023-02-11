//
//  MockRefreshTokenEndPointProvider.swift
//  Tests
//
//  Created by Ihor Yarovyi on 10.02.2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
@testable import NetworkLayer

struct MockRefreshTokenEndPointProvider: RefreshTokenEndPointProvider {
    var endPoint: RequestConvertible {
        MockRefreshTokenRequestConvertible()
    }
}
