//
//  DefaultHTTPOperator.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 07.02.2023.
//

import Foundation
import os

public final class DefaultHTTPOperator: HTTPOperator {
    public typealias URLSessionProcessData = (URLRequest, URLSessionTaskDelegate?) async throws -> (Data, URLResponse)

    private let baseURL: URL
    private let processData: URLSessionProcessData
    private var token: String?
    private let operationQueue = OperationQueue()
    private let processingQueue: DispatchQueue
    private let logger = Logger(subsystem: "\(DefaultHTTPOperator.self)", category: "\(DefaultHTTPOperator.self)")
    public let refreshTokenEndPointProvider: RefreshTokenEndPointProvider
    public let tokenDecorator: TokenDecorator
    public let tokenInterpreter: TokenInterpreter.Type

    public init(
        baseURL: URL,
        processData: @escaping URLSessionProcessData = URLSession.shared.data,
        refreshTokenEndPointProvider: RefreshTokenEndPointProvider,
        tokenDecorator: TokenDecorator,
        tokenInterpreter: TokenInterpreter.Type,
        processingQueue: DispatchQueue
    ) {
        self.baseURL = baseURL
        self.processData = processData
        self.refreshTokenEndPointProvider = refreshTokenEndPointProvider
        self.tokenDecorator = tokenDecorator
        self.tokenInterpreter = tokenInterpreter
        self.processingQueue = processingQueue
        operationQueue.maxConcurrentOperationCount = Defaults.Queue.maxConcurrentOperationCount
        operationQueue.underlyingQueue = processingQueue
        operationQueue.name = Defaults.Queue.name
    }

    public func sendRequest(_ request: Network.RequestItem) {
        dispatchPrecondition(condition: .onQueue(processingQueue))
        logger.info("receive request: \(request.request.method.rawValue) \(request.request.path)")

        let operation = RequestOperation(
            requestItem: request,
            executionQueue: processingQueue
        ) { [weak self] requestItem in
            guard let self else { return }
            do {
                let request = try self.createRequest(for: requestItem.request)
                let result = await self.sendRequestHelper(request)
                requestItem.completion(result)
            } catch {
                requestItem.completion(.failure(.init(error: error)))
            }
        }

        operationQueue.addOperation(operation)
    }

    public func cancelAllRequests() {
        logger.info("cancel all requests")
        operationQueue.cancelAllOperations()
    }

    public func setToken(_ rawToken: String) {
        logger.info("set token: \(rawToken)")
        token = tokenDecorator.decorate(rawToken: rawToken)
    }

    public func clearToken() {
        logger.info("clear token")
        token = nil
    }
}

// MARK: - Private Helpers
private extension DefaultHTTPOperator {
    func createRequest(for requestConvertible: RequestConvertible) throws -> Network.Request {
        logger.info("create the Request instance for the folling path: \(requestConvertible.path)")
        return try Network.Request(
            requestConvertible: requestConvertible,
            baseURL: baseURL
        )
    }

    func sendRequestHelper(
        _ request: Network.Request,
        numberOfCalls: Int = 0,
        status: Network.NetworkError.Status? = nil
    ) async -> Result<Data, Network.NetworkError> {
        logger.info("try to send request [\(request.requestConvertible.method.rawValue) \(request.requestConvertible.path)]; attempts: \(numberOfCalls)")
        guard numberOfCalls < Defaults.maxNumberOfCalls else {
            logger.error("exceed request attempts for the [\(request.requestConvertible.method.rawValue) \(request.requestConvertible.path)]")
            return .failure(Network.NetworkError(status: status ?? .tooManyRequests))
        }

        var request = request
        if request.requestConvertible.authorizationStrategy == .token {
            updateToken(for: &request)
        }

        do {
            let (data, response) = try await processData(request.urlRequest, nil)
            guard let response = response as? HTTPURLResponse else {
                logger.error("failed to cast response for the [\(request.requestConvertible.method.rawValue) \(request.requestConvertible.path)]")
                return .failure(Network.NetworkError(status: .badServerResponse))
            }
            logger.info("receive response for the [\(request.requestConvertible.method.rawValue) \(request.requestConvertible.path)] - status code: \(response.statusCode)")
            switch response.statusCode {
            case 200...299:
                return .success(data)
            case 401:
                guard status != .unauthorized else { return .failure(Network.NetworkError(status: .unauthorized)) }
                try await refreshToken()
                updateToken(for: &request)
                return await sendRequestHelper(request, numberOfCalls: numberOfCalls + 1)
            case 502, 503, 504, -1001:
                try await Task.sleep(until: .now + .seconds(1), clock: .continuous)
                return await sendRequestHelper(
                    request,
                    numberOfCalls: numberOfCalls + 1,
                    status: .init(rawValue: response.statusCode) ?? .internalServerError
                )
            default:
                return .failure(Network.NetworkError(errorCode: response.statusCode))
            }
        } catch {
            logger.error("failed to perform the request [\(request.requestConvertible.method.rawValue) \(request.requestConvertible.path)]")
            return .failure(.init(error: error))
        }
    }

    func refreshToken() async throws {
        logger.info("try to refresh token")
        let request = try createRequest(for: refreshTokenEndPointProvider.endPoint)
        let data = try await sendRequestHelper(request, status: .unauthorized).get()
        let value = try JSONDecoder().decode(tokenInterpreter.self, from: data)
        setToken(value.token)
    }

    func updateToken(for request: inout Network.Request) {
        let method = request.requestConvertible.method.rawValue
        let path = request.requestConvertible.path
        logger.info("update token for request: [\(method) \(path)]")
        request.urlRequest.setValue(token, forHTTPHeaderField: Defaults.authorization)
    }
}

// MARK: - Defaults
private extension DefaultHTTPOperator {
    enum Defaults {
        static let authorization: String = "Authorization"
        static let maxNumberOfCalls: Int = 3
        enum Queue {
            static let maxConcurrentOperationCount: Int = 1
            static let name = "default.http.operator.queue"
        }
    }
}
