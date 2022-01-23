//
//  Operator+Task.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 6/29/21.
//

import Foundation

public extension Network.Operator {
    enum Task {
        /// A request with no additional data.
        case requestPlain
        /// A requests body set with encoded parameters combined with url parameters.
        case requestCompositeParameters(bodyParameters: [String: Any], bodyEncoding: Network.ParameterEncoding, urlParameters: [String: Any] = [:])
        /// A request body set with `Encodable` type combined with url parameters
        case requestJSONEncodable(Encodable, urlParameters: [String: Any] = [:])
        /// A `multipart/form-data` upload task  combined with url parameters
        case uploadMultipart(bodyParameters: [String: Any], multipartData: [Network.Multipart.Data], urlParameters: [String: Any] = [:])
    }
}
