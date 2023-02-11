//
//  MockURLSessionProcessData.swift
//  Tests
//
//  Created by Ihor Yarovyi on 10.02.2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
import NetworkLayer

final class MockURLSessionProcessData {
    var data: Data!
    var response: URLResponse!
    var expectation: XCTestExpectation!
    var numberOfCall: Int = 0

    func data(
        for request: URLRequest,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (Data, URLResponse) {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else { return }
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                continuation.resume(returning: (self.data, self.response))
                self.numberOfCall += 1
                self.expectation.fulfill()
            }
        }
    }
}

final class MockAgileURLSessionProcessData {
    var data: Data!
    var successResponse: URLResponse!
    var failureResponse: URLResponse!
    var expectation: XCTestExpectation!
    var numberOfCall: Int = 0
    var isSuccessResponseAvailable: ((Int) -> Bool)!

    func data(
        for request: URLRequest,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (Data, URLResponse) {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else { return }
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                self.numberOfCall += 1

                if self.isSuccessResponseAvailable(self.numberOfCall) {
                    continuation.resume(returning: (self.data, self.successResponse))
                } else {
                    continuation.resume(returning: (self.data, self.failureResponse))
                }
                self.expectation.fulfill()
            }
        }
    }
}

final class MockRefreshTokenURLSessionProcessData {
    var data: Data!
    var refreshTokenData: Data!
    var processingQueue: DispatchQueue!
    var successResponse: URLResponse!
    var failureResponse: URLResponse!
    var refreshTokenSuccessResponse: URLResponse!
    var refreshTokenFailureResponse: URLResponse!
    var expectation: XCTestExpectation!
    var refreshTokenExpectation: XCTestExpectation!
    var numberOfCall: Int = 0
    var numberOfRefreshTokenCall: Int = 0
    var isSuccessResponseAvailable: ((Int) -> Bool)!
    var isSuccessRefreshTokenResponseAvailable: ((Int) -> Bool)!

    func data(
        for request: URLRequest,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (Data, URLResponse) {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else { return }
            self.processingQueue.asyncAfter(deadline: .now() + 0.1) {

                if request.url?.relativeString.hasSuffix("refresh/token") == true {
                    self.numberOfRefreshTokenCall += 1
                    if self.isSuccessRefreshTokenResponseAvailable(self.numberOfRefreshTokenCall) {
                        continuation.resume(returning: (self.refreshTokenData, self.refreshTokenSuccessResponse))
                    } else {
                        continuation.resume(returning: (self.refreshTokenData, self.refreshTokenFailureResponse))
                    }
                    self.refreshTokenExpectation.fulfill()
                    return
                }

                self.numberOfCall += 1
                if self.isSuccessResponseAvailable(self.numberOfCall) {
                    continuation.resume(returning: (self.data, self.successResponse))
                } else {
                    continuation.resume(returning: (self.data, self.failureResponse))
                }
                self.expectation.fulfill()
            }
        }
    }
}

final class MockRefreshTokenInSequenceURLSessionProcessData {
    var data: Data!
    var refreshTokenData: Data!
    var processingQueue: DispatchQueue!
    var successResponse: URLResponse!
    var failureResponse: URLResponse!
    var refreshTokenSuccessResponse: URLResponse!
    var expectation: XCTestExpectation!
    var refreshTokenExpectation: XCTestExpectation!
    var numberOfCall: Int = 0
    var authorizationHanlder: ((String?) -> Void)!

    func data(
        for request: URLRequest,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (Data, URLResponse) {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else { return }
            self.processingQueue.asyncAfter(deadline: .now() + 0.1) {
                if self.numberOfCall == 3 {
                    continuation.resume(returning: (self.data, self.failureResponse))
                    self.numberOfCall += 1
                    self.expectation.fulfill()
                    return
                }

                if request.url?.relativeString.hasSuffix("refresh/token") == true {
                    continuation.resume(returning: (self.refreshTokenData, self.refreshTokenSuccessResponse))
                    self.refreshTokenExpectation.fulfill()
                    return
                }

                if self.numberOfCall > 3 {
                    self.authorizationHanlder(request.allHTTPHeaderFields?["Authorization"])
                }

                continuation.resume(returning: (self.data, self.successResponse))
                self.numberOfCall += 1
                self.expectation.fulfill()
            }
        }
    }
}

struct TestRequest: RequestConvertible {
    var path: String { "test/request/\(id)" }
    var method: NetworkLayer.Network.Method { .get }
    var task: NetworkLayer.Network.Task { .requestPlain }
    var id: Int

    init(id: Int = 0) {
        self.id = id
    }
}

struct TestModel: Codable, Equatable {
    let id: Int
}
