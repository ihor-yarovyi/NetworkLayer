//
//  HttpBodyConvertible.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 11/18/21.
//

import Foundation

public protocol HttpBodyConvertible {
    func buildHttpBodyPart(boundary: String) -> Data
}
