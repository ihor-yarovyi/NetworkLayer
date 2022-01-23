//
//  Dictionary+HttpBodyConvertible.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 11/18/21.
//

import Foundation

extension Dictionary: HttpBodyConvertible where Key == String, Value == CustomStringConvertible {
    public func buildHttpBodyPart(boundary: String) -> Data {
        let httpBody = NSMutableData()
        forEach { (name, value) in
            httpBody.appendString("--\(boundary)\r\n")
            httpBody.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            httpBody.appendString(value.description)
            httpBody.appendString("\r\n")
        }
        return httpBody as Data
    }
}
