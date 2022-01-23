//
//  AnyEncodable.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 30.12.2021.
//

import Foundation

extension Network {
    struct AnyEncodable: Encodable {
        let encodable: Encodable

        func encode(to encoder: Encoder) throws {
            try encodable.encode(to: encoder)
        }
    }
}
