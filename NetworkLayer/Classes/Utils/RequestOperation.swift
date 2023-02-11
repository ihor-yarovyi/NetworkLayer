//
//  RequestOperation.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 09.02.2023.
//

import Foundation

final class RequestOperation: AsyncOperation {
    private let requestItem: Network.RequestItem
    private let executionQueue: DispatchQueue
    private let onExecute: (Network.RequestItem) async -> Void

    init(
        requestItem: Network.RequestItem,
        executionQueue: DispatchQueue,
        onExecute: @escaping (Network.RequestItem) async -> Void
    ) {
        self.requestItem = requestItem
        self.executionQueue = executionQueue
        self.onExecute = onExecute
    }

    override func main() {
        dispatchPrecondition(condition: .onQueue(executionQueue))
        Task {
            await onExecute(requestItem)
            finish()
        }
    }

    override func cancel() {
        super.cancel()
        finish()
    }
}
