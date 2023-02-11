//
//  TokenDecorator.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 08.02.2023.
//

import Foundation

public protocol TokenDecorator {
    func decorate(rawToken: String) -> String
}
