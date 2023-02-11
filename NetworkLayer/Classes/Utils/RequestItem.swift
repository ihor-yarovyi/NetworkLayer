//
//  RequestItem.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 08.02.2023.
//

import Foundation

public extension Network {
    struct RequestItem {
        let request: RequestConvertible
        let completion: (Result<Data, NetworkError>) -> Void

        public init(request: RequestConvertible,
                    completion: @escaping (Result<Data, NetworkError>) -> Void) {
            self.request = request
            self.completion = completion
        }
    }
}
