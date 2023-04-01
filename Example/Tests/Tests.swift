//
//  Tests.swift
//  Tests
//
//  Created by Ihor Yarovyi on 10.02.2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest
@testable import NetworkLayer

final class Tests: XCTestCase {
    var url: URL!
    var processData: MockURLSessionProcessData!
    var processingQueue: DispatchQueue!
    var testModel: TestModel!
    var sut: HTTPOperator!

    override func setUp() {
        super.setUp()
        url = URL(string: "https://example.com/")
        processData = MockURLSessionProcessData()
        processingQueue = DispatchQueue(label: "test.queue")
        testModel = TestModel(id: 3)
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))
    }

    override func tearDown() {
        url = nil
        processData = nil
        processingQueue = nil
        testModel = nil
        sut = nil
        super.tearDown()
    }

    func testSuccessRequest() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        processData.data = try JSONEncoder().encode(testModel)
        processData.response = SuccessTestResponse()
        processData.expectation = responseExpectation

        let requestItem = Network.RequestItem(request: TestRequest()) { [unowned self] result in
            do {
                let data = try result.get()
                let model = try JSONDecoder().decode(TestModel.self, from: data)
                XCTAssertEqual(testModel, model)
                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 1)
    }

    func testBadRequest() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        processData.data = try JSONEncoder().encode(testModel)
        processData.response = FailTestResponse()
        processData.expectation = responseExpectation

        let requestItem = Network.RequestItem(request: TestRequest()) { result in
            guard case let .failure(error) = result else {
                XCTFail("Expect failure")
                return
            }

            XCTAssertEqual(error.status, .badRequest)
            expectation.fulfill()
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 1)
    }

    func testBadGatewayRequest() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse()
        processData.isSuccessResponseAvailable = { $0 == 2 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 2
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { [unowned self] result in
            do {
                let data = try result.get()
                let model = try JSONDecoder().decode(TestModel.self, from: data)
                XCTAssertEqual(testModel, model)
                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 2)
    }

    func testBadGatewayRequestWithThreeAttemps() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse()
        processData.isSuccessResponseAvailable = { $0 == 3 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 3
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { [unowned self] result in
            do {
                let data = try result.get()
                let model = try JSONDecoder().decode(TestModel.self, from: data)
                XCTAssertEqual(testModel, model)
                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 3)
    }

    func testBadGatewayRequestWithThreeFailedAttemps() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse()
        processData.isSuccessResponseAvailable = { $0 == 4 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 3
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { result in
            guard case let .failure(error) = result else {
                XCTFail("Expect failure")
                return
            }

            XCTAssertEqual(error.status, .badGateway)
            expectation.fulfill()
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 3)
    }

    func testServiceUnavailableRequest() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse(statusCode: 503)
        processData.isSuccessResponseAvailable = { $0 == 2 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 2
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { [unowned self] result in
            do {
                let data = try result.get()
                let model = try JSONDecoder().decode(TestModel.self, from: data)
                XCTAssertEqual(testModel, model)
                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 2)
    }

    func testServiceUnavailableRequestWithThreeAttemps() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse(statusCode: 503)
        processData.isSuccessResponseAvailable = { $0 == 3 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 3
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { [unowned self] result in
            do {
                let data = try result.get()
                let model = try JSONDecoder().decode(TestModel.self, from: data)
                XCTAssertEqual(testModel, model)
                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 3)
    }

    func testServiceUnavailableRequestWithThreeFailedAttemps() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse(statusCode: 503)
        processData.isSuccessResponseAvailable = { $0 == 4 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 3
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { result in
            guard case let .failure(error) = result else {
                XCTFail("Expect failure")
                return
            }

            XCTAssertEqual(error.status, .serviceUnavailable)
            expectation.fulfill()
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 3)
    }

    func testGatewayTimeoutRequest() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse(statusCode: 504)
        processData.isSuccessResponseAvailable = { $0 == 2 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 2
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { [unowned self] result in
            do {
                let data = try result.get()
                let model = try JSONDecoder().decode(TestModel.self, from: data)
                XCTAssertEqual(testModel, model)
                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 2)
    }

    func testGatewayTimeoutRequestWithThreeAttemps() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse(statusCode: 504)
        processData.isSuccessResponseAvailable = { $0 == 3 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 3
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { [unowned self] result in
            do {
                let data = try result.get()
                let model = try JSONDecoder().decode(TestModel.self, from: data)
                XCTAssertEqual(testModel, model)
                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 3)
    }

    func testGatewayTimeoutRequestWithThreeFailedAttemps() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse(statusCode: 504)
        processData.isSuccessResponseAvailable = { $0 == 4 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 3
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { result in
            guard case let .failure(error) = result else {
                XCTFail("Expect failure")
                return
            }

            XCTAssertEqual(error.status, .gatewayTimeout)
            expectation.fulfill()
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 3)
    }

    func testTimeoutRequest() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse(statusCode: -1001)
        processData.isSuccessResponseAvailable = { $0 == 2 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 2
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { [unowned self] result in
            do {
                let data = try result.get()
                let model = try JSONDecoder().decode(TestModel.self, from: data)
                XCTAssertEqual(testModel, model)
                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 2)
    }

    func testTimeoutRequestWithThreeAttemps() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse(statusCode: -1001)
        processData.isSuccessResponseAvailable = { $0 == 3 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 3
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { [unowned self] result in
            do {
                let data = try result.get()
                let model = try JSONDecoder().decode(TestModel.self, from: data)
                XCTAssertEqual(testModel, model)
                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 3)
    }

    func testTimeoutRequestWithThreeFailedAttemps() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        let processData = MockAgileURLSessionProcessData()
        processData.data = try JSONEncoder().encode(testModel)
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = ServerErrorTestResponse(statusCode: -1001)
        processData.isSuccessResponseAvailable = { $0 == 4 }
        processData.expectation = responseExpectation
        responseExpectation.expectedFulfillmentCount = 3
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { result in
            guard case let .failure(error) = result else {
                XCTFail("Expect failure")
                return
            }

            XCTAssertEqual(error.status, .timedOut)
            expectation.fulfill()
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 3)
    }

    func testUnauthorizedSuccessRequest() throws {
        let refreshTokenExpectation = expectation(description: "refresh token should be called")
        let responseExpectation = expectation(description: "should be called in response")
        let resultExpectation = expectation(description: "should be called in result")
        let processData = MockRefreshTokenURLSessionProcessData()
        refreshTokenExpectation.expectedFulfillmentCount = 1
        responseExpectation.expectedFulfillmentCount = 2
        processData.data = try JSONEncoder().encode(testModel)
        processData.refreshTokenData = try JSONEncoder().encode(
            MockTokenInterpreter(accessToken: "access_token_string", refreshToken: "refresh_token_string")
        )
        processData.processingQueue = processingQueue
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = UnauthorizeErrorTestResponse()
        processData.refreshTokenSuccessResponse = SuccessTestResponse()
        processData.refreshTokenFailureResponse = FailTestResponse()
        processData.expectation = responseExpectation
        processData.refreshTokenExpectation = refreshTokenExpectation
        processData.isSuccessResponseAvailable = { $0 == 2 }
        processData.isSuccessRefreshTokenResponseAvailable = { $0 == 1 }
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { [unowned self] result in
            do {
                let data = try result.get()
                let model = try JSONDecoder().decode(TestModel.self, from: data)
                XCTAssertEqual(testModel, model)
                resultExpectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [refreshTokenExpectation, resultExpectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 2)
        XCTAssertEqual(processData.numberOfRefreshTokenCall, 1)
    }

    func testUnauthorizedRequestWithRepeatedUnauthorizedError() throws {
        let refreshTokenExpectation = expectation(description: "refresh token should be called")
        let responseExpectation = expectation(description: "should be called in response")
        let resultExpectation = expectation(description: "should be called in result")
        let processData = MockRefreshTokenURLSessionProcessData()
        refreshTokenExpectation.expectedFulfillmentCount = 1
        responseExpectation.expectedFulfillmentCount = 1
        processData.data = try JSONEncoder().encode(testModel)
        processData.refreshTokenData = try JSONEncoder().encode(
            MockTokenInterpreter(accessToken: "access_token_string", refreshToken: "refresh_token_string")
        )
        processData.processingQueue = processingQueue
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = UnauthorizeErrorTestResponse()
        processData.refreshTokenSuccessResponse = SuccessTestResponse()
        processData.refreshTokenFailureResponse = UnauthorizeErrorTestResponse()
        processData.expectation = responseExpectation
        processData.refreshTokenExpectation = refreshTokenExpectation
        processData.isSuccessResponseAvailable = { $0 == 2 }
        processData.isSuccessRefreshTokenResponseAvailable = { $0 == 3 }
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { result in
            guard case let .failure(error) = result else {
                XCTFail("Expect failure")
                return
            }

            XCTAssertEqual(error.status, .unauthorized)
            resultExpectation.fulfill()
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [refreshTokenExpectation, resultExpectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 1)
        XCTAssertEqual(processData.numberOfRefreshTokenCall, 1)
    }

    func testUnauthorizedFailedRequest() throws {
        let refreshTokenExpectation = expectation(description: "refresh token should be called")
        let responseExpectation = expectation(description: "should be called in response")
        let resultExpectation = expectation(description: "should be called in result")
        let processData = MockRefreshTokenURLSessionProcessData()
        refreshTokenExpectation.expectedFulfillmentCount = 1
        responseExpectation.expectedFulfillmentCount = 1
        processData.data = try JSONEncoder().encode(testModel)
        processData.refreshTokenData = try JSONEncoder().encode(
            MockTokenInterpreter(accessToken: "access_token_string", refreshToken: "refresh_token_string")
        )
        processData.processingQueue = processingQueue
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = UnauthorizeErrorTestResponse()
        processData.refreshTokenSuccessResponse = SuccessTestResponse()
        processData.refreshTokenFailureResponse = FailTestResponse()
        processData.expectation = responseExpectation
        processData.refreshTokenExpectation = refreshTokenExpectation
        processData.isSuccessResponseAvailable = { $0 == 2 }
        processData.isSuccessRefreshTokenResponseAvailable = { $0 == 3 }
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))

        let requestItem = Network.RequestItem(request: TestRequest()) { result in
            guard case let .failure(error) = result else {
                XCTFail("Expect failure")
                return
            }

            XCTAssertEqual(error.status, .badRequest)
            resultExpectation.fulfill()
        }

        processingQueue.sync {
            sut.sendRequest(requestItem)
        }

        wait(for: [refreshTokenExpectation, resultExpectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 1)
        XCTAssertEqual(processData.numberOfRefreshTokenCall, 1)
    }

    func testRequestSequence() throws {
        let responseExpectation = expectation(description: "should be called in response")
        let expectation = expectation(description: "should be called in result")
        responseExpectation.expectedFulfillmentCount = 10
        expectation.expectedFulfillmentCount = 10
        processData.data = try JSONEncoder().encode(testModel)
        processData.response = SuccessTestResponse()
        processData.expectation = responseExpectation
        var requests: [Network.RequestItem] = []

        for i in 0..<10 {
            let requestItem = Network.RequestItem(request: TestRequest(id: i)) { [unowned self] result in
                do {
                    let data = try result.get()
                    let model = try JSONDecoder().decode(TestModel.self, from: data)
                    XCTAssertEqual(testModel, model)
                    expectation.fulfill()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }

            requests.append(requestItem)
        }

        requests.forEach { request in
            processingQueue.sync {
                sut.sendRequest(request)
            }
        }

        wait(for: [expectation, responseExpectation], timeout: Defaults.timeout)
        XCTAssertEqual(processData.numberOfCall, 10)
    }

    func testRefreshTokenInRequestSequence() throws {
        var requests: [Network.RequestItem] = []
        let token = "initial_token"
        let newToken = "new_access_token"
        let authField = MockTokenDecorator().decorate(rawToken: newToken)
        let responseExpectation = expectation(description: "should be called in response")
        let resultExpectation = expectation(description: "should be called in result")
        let refreshTokenExpectation = expectation(description: "refresh token should be called")
        let authorizationExpectation = expectation(description: "should be called in check of auth fields")
        let processData = MockRefreshTokenInSequenceURLSessionProcessData()
        responseExpectation.expectedFulfillmentCount = 11
        resultExpectation.expectedFulfillmentCount = 10
        authorizationExpectation.expectedFulfillmentCount = 7
        processData.data = try JSONEncoder().encode(testModel)
        processData.refreshTokenData = try JSONEncoder().encode(
            MockTokenInterpreter(accessToken: newToken, refreshToken: "refresh_token_string")
        )
        processData.processingQueue = processingQueue
        processData.successResponse = SuccessTestResponse()
        processData.failureResponse = UnauthorizeErrorTestResponse()
        processData.refreshTokenSuccessResponse = SuccessTestResponse()
        processData.expectation = responseExpectation
        processData.refreshTokenExpectation = refreshTokenExpectation
        sut = makeDefaultPoperator(processData: processData.data(for:delegate:))
        sut.setToken(token)

        for i in 0..<10 {
            let requestItem = Network.RequestItem(request: TestRequest(id: i)) { [unowned self] result in
                do {
                    let data = try result.get()
                    let model = try JSONDecoder().decode(TestModel.self, from: data)
                    XCTAssertEqual(testModel, model)
                    resultExpectation.fulfill()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }

            requests.append(requestItem)
        }

        processData.authorizationHanlder = { auth in
            XCTAssertEqual(auth, authField)
            authorizationExpectation.fulfill()
        }

        requests.forEach { request in
            processingQueue.sync {
                sut.sendRequest(request)
            }
        }

        wait(for: [responseExpectation, resultExpectation, refreshTokenExpectation, authorizationExpectation], timeout: Defaults.timeout)
    }
}

private extension Tests {
    enum Defaults {
        static let timeout: TimeInterval = 5
    }
}

private extension Tests {
    func makeDefaultPoperator(processData: @escaping (URLRequest, URLSessionTaskDelegate?) async throws -> (Data, URLResponse)) -> HTTPOperator {
        DefaultHTTPOperator(
            baseURL: url,
            processData: processData,
            refreshTokenEndPointProvider: MockRefreshTokenEndPointProvider(),
            tokenDecorator: MockTokenDecorator(),
            tokenInterpreter: MockTokenInterpreter.self,
            processingQueue: processingQueue
        )
    }
}
