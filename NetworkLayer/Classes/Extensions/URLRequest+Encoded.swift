//
//  URLRequest+Encoded.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 6/30/21.
//

import Foundation

extension URLRequest {
    mutating func encoded(for target: RequestConvertible, with baseURL: URL) throws -> URLRequest {
        switch target.task {
        case let .requestCompositeParameters(bodyParameters, bodyEncoding, urlParameters):
            var request = encodeURLParams(urlParameters, with: baseURL)
            return try request.encodeBodyParams(bodyParameters, encoding: bodyEncoding)
        case let .requestJSONEncodable(bodyEncodable, urlParameters):
            var request = encodeURLParams(urlParameters, with: baseURL)
            return try request.setBodyData(with: bodyEncodable)
        case let .uploadMultipart(bodyParameters, multipartData, urlParameters):
            var request = encodeURLParams(urlParameters, with: baseURL)
            return request.buildMultipartHttpBody(params: bodyParameters, multiparts: multipartData)
        default:
            return self
        }
    }
}

// MARK: - Private Helpers
private extension URLRequest {
    mutating func encodeURLParams(_ params: [String: Any], with baseURL: URL) -> URLRequest {
        if var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) {
            var queryItems = urlComponents.queryItems ?? []
            params.forEach { key, value in
                if let array = value as? [CustomStringConvertible] {
                    array.forEach {
                        queryItems.append(URLQueryItem(name: "\(key)[]", value: "\($0)"))
                    }
                } else {
                    queryItems.append(URLQueryItem(name: "\(key)", value: "\(value)"))
                }
            }
            if !queryItems.isEmpty {
                urlComponents.queryItems = queryItems
            }
            return URLRequest(url: urlComponents.url ?? baseURL)
        } else {
            return self
        }
    }
    
    mutating func encodeBodyParams(_ params: [String: Any], encoding: Network.ParameterEncoding) throws -> URLRequest {
        guard !params.isEmpty else { return self }
        switch encoding {
        case .urlEncoded:
            setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            httpBody = percentEncodedString(params).data(using: .utf8)
        case .json:
            let jsonData = try JSONSerialization.data(withJSONObject: params)
            setJSONBody(with: jsonData)
        }
        return self
    }
    
    mutating func setBodyData(with encodable: Encodable) throws -> URLRequest {
        let anyEncodable = Network.AnyEncodable(encodable: encodable)
        let data = try JSONEncoder().encode(anyEncodable)
        setJSONBody(with: data)
        return self
    }
    
    mutating func setJSONBody(with data: Data) {
        setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpBody = data
    }
    
    func percentEncodedString(_ params: [String: Any]) -> String {
        params.map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            if let array = value as? [CustomStringConvertible] {
                return array.map { entry in
                    let escapedValue = "\(entry)"
                        .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
                    return "\(key)[]=\(escapedValue)" }.joined(separator: "&")
            } else {
                let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
                return "\(escapedKey)=\(escapedValue)"
            }
        }
        .joined(separator: "&")
    }
    
    mutating func buildMultipartHttpBody(params: [String: Any], multiparts: [Network.Multipart.Data]) -> URLRequest {
        let boundary = "Boundary-\(UUID().uuidString)"
        let params = params.compactMapValues { $0 as? CustomStringConvertible }
        let allMultiparts: [HttpBodyConvertible] = [params] + multiparts
        let boundaryEnding = "--\(boundary)--".data(using: .utf8).unsafelyUnwrapped
        
        setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        httpBody = allMultiparts.map { (multipart: HttpBodyConvertible) -> Data in
            multipart.buildHttpBodyPart(boundary: boundary)
        }
        .reduce(Data.init(), +)
        + boundaryEnding
        
        return self
    }
}
