//
//  Network.Multipart+Data.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 11/18/21.
//

import Foundation

public extension Network.Multipart {
    struct Data {
        public let name: String
        public let fileData: Foundation.Data
        public let fileName: String
        public let mimeType: String
        
        public init(name: String, fileData: Foundation.Data, fileName: String, mimeType: String) {
            self.name = name
            self.fileData = fileData
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }
}
