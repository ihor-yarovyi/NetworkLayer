//
//  NSMutableData+AppendString.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 11/18/21.
//

import Foundation

extension NSMutableData {
    func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}
