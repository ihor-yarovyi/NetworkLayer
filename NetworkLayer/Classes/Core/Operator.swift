//
//  Operator.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 6/29/21.
//

import Foundation
import Combine

public extension Network {
    final class Operator: NSObject {
        
        typealias DataTaskOutput = URLSession.DataTaskPublisher.Output
        typealias DataTaskResult = Result<DataTaskOutput, Error>
        
        // MARK: - Public Properties
        public let baseURL: URL
        public var token: TokenProvider?
        public let queue: DispatchQueue
        
        // MARK: - Internal Properties
        let configuration: URLSessionConfiguration
        let progressPublisher = PassthroughSubject<Progress, Error>()

        // MARK: - Private Properties
        private(set) lazy var session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        private var subscriptions = Set<AnyCancellable>()
        private var activeRequests: [UUID: (request: Request, task: AnyCancellable)] = [:]
        private var completedRequests: Set<UUID> = []
        
        // MARK: - Lifecycle
        public init(baseURL: URL,
                    configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                    queue: DispatchQueue = DispatchQueue(label: "Network operator")) {
            self.baseURL = baseURL
            self.configuration = configuration
            self.queue = queue
            super.init()
        }
        
        // MARK: - Create Request
        /// Create the instance of the `Request`. Result of the request available in the `completion`
        public func createRequest(id: UUID,
                                  from api: RequestConvertible,
                                  completion: ((Result<Data, Error>) -> Void)?,
                                  progress: ((Progress) -> Void)? = nil) throws -> Request {
            try Request(id: id, baseURL: baseURL, api: api, completion: completion, progress: progress)
        }
        
        // MARK: - Process Requests
        public func process(requests: [Request]) {
            var remainedActiveRequestsIds = Set(activeRequests.keys)
            
            for request in requests {
                perform(request)
                remainedActiveRequestsIds.remove(request.id)
            }
            
            for cancelledRequestID in remainedActiveRequestsIds {
                cancel(requestId: cancelledRequestID)
            }
        }
        
        // MARK: - Cancel Request
        private func cancel(requestId: UUID) {
            guard let (_, task) = activeRequests[requestId] else {
                preconditionFailure("Request not found")
            }
            task.cancel()
        }
        
        // MARK: - Complete Request
        private func complete(_ request: Request, with result: Result<Data, Error>) {
            guard let currentRequst = activeRequests[request.id] else {
                preconditionFailure("Request not found")
            }
            activeRequests[request.id] = nil
            completedRequests.insert(request.id)
            currentRequst.request.onComplete(with: result)
        }
        
        // MARK: - Perform Request
        private func performData(_ request: Request) {
            let descriptor = performDataTask(for: request)
                .subscribe(on: DispatchQueue.global())
                .receive(on: queue)
                .sink(receiveCompletion: { [weak self] completion in
                    guard case let .failure(error) = completion else { return }
                    self?.complete(request, with: .failure(error))
                }, receiveValue: { [weak self] value in
                    self?.complete(request, with: .success(value.data))
                })
            
            activeRequests[request.id] = (request, descriptor)
        }
        
        // MARK: - Perform Upload
        private func performUpload(_ request: Request) {
            let progressPublisher2: AnyPublisher<(DataTaskOutput?, Progress), Error> = progressPublisher
                .map { progress -> (DataTaskOutput?, Progress) in
                    return (nil, progress)
                }.eraseToAnyPublisher()
            
            let descriptor = Publishers.Merge(
                performDataTask(for: request).map { data -> (DataTaskOutput?, Progress) in
                    (data, Progress())
                },
                progressPublisher2
            )
            .subscribe(on: DispatchQueue.global())
            .receive(on: queue)
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.complete(request, with: .failure(error))
            }, receiveValue: { [weak self] output, progress in
                if let data = output?.data {
                    self?.complete(request, with: .success(data))
                }
                request.progress?(progress)
            })
            
            activeRequests[request.id] = (request, descriptor)
        }
        
        // MARK: - Perform Data Task
        private func performDataTask(for request: Request) -> AnyPublisher<Operator.DataTaskOutput, Error> {
            session.dataTaskPublisher(for: request.urlRequest)
                .tryMap { dataTaskOutput -> DataTaskResult in
                    guard let response = dataTaskOutput.response as? HTTPURLResponse else {
                        throw NetworkError(status: .badServerResponse)
                    }
                    
                    if dataTaskOutput.data.isEmpty && response.statusCode >= 400 {
                        throw NetworkError(errorCode: response.statusCode)
                    }
                    return .success(dataTaskOutput)
                }
                .catch { error -> AnyPublisher<DataTaskResult, Error> in
                    let networkError = NetworkError(error: error)
                    switch networkError.status {
                    case .tooManyRequests, .serviceUnavailable:
                        return Fail(error: networkError)
                            .delay(for: .seconds(request.api.retryInterval), scheduler: DispatchQueue.main)
                            .eraseToAnyPublisher()
                    default:
                        return Just(.failure(networkError))
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                }
                .retry(request.api.retryEnabled ? request.api.maxRetryCount : .zero)
                .tryMap { result in
                    try result.get()
                }
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - Execute Helpers
private extension Network.Operator {
    private func perform(_ request: Request) {
        queue.async {
            self.executeIfPossible(request)
        }
    }
    
    private func executeIfPossible(_ request: Request) {
        guard !completedRequests.contains(request.id) else { return }
        checkToken(for: request)
    }
    
    private func checkToken(for request: Request) {
        guard request.api.authorizationStrategy == .token else {
            updateIfNeededAndExecute(request)
            return
        }
        
        if let token = token {
            token.authorization.forEach {
                request.urlRequest.setValue($0.value, forHTTPHeaderField: $0.key)
            }
            updateIfNeededAndExecute(request)
        } else {
            request.onComplete(with: .failure(Network.NetworkError(status: .sessionIsRequired)))
        }
    }
    
    private func updateIfNeededAndExecute(_ request: Request) {
        if activeRequests.keys.contains(request.id) {
            activeRequests[request.id]?.request = request
        } else {
            execute(request)
        }
    }
    
    private func execute(_ request: Request) {
        switch request.api.task {
        case .requestPlain:
            performData(request)
        case .requestCompositeParameters:
            performData(request)
        case .uploadMultipart:
            performData(request)
        case .requestJSONEncodable:
            performData(request)
        }
    }
}

// MARK: - URLSessionTaskDelegate
extension Network.Operator: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        let progress = Progress(totalUnitCount: totalBytesExpectedToSend)
        progress.completedUnitCount = totalBytesSent
        progressPublisher.send(progress)
    }
}
