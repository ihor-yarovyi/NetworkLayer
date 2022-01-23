//
//  NetworkError+CustomStringConvertible.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 6/29/21.
//

import Foundation

extension Network.NetworkError: CustomStringConvertible {
    public var description: String {
        String(describing: self.status)
            .replacingOccurrences(
                of: "(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])",
                with: " ",
                options: [.regularExpression]
            )
            .capitalized
    }
}
