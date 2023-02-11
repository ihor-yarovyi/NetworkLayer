//
//  AsyncOperation.swift
//  NetworkLayer
//
//  Created by Ihor Yarovyi on 09.02.2023.
//

import Foundation

class AsyncOperation: Operation {
    override var isAsynchronous: Bool { true }

    override var isExecuting: Bool {
        lockQueue.sync {
            state == .executing
        }
    }

    override var isFinished: Bool {
        lockQueue.sync {
            state == .finished
        }
    }

    private let lockQueue = DispatchQueue(label: "com.network.asyncoperation")
    private var state: State = .initialized

    override func start() {
        setStateToExecuting()

        guard !isCancelled else {
            finish()
            return
        }

        main()
    }

    override func main() {
        fatalError("Subclasses must implement `main`")
    }

    override func cancel() {
        guard !isCancelled else { return }
        super.cancel()
    }

    func onFinish() {}

    func finish() {
        guard setStateToFinished() else { return }
        onFinish()
    }
}

// MARK: - Private Methods
private extension AsyncOperation {
    func setStateToFinished() -> Bool {
        willChangeValue(forKey: Defaults.Key.isExecuting)
        willChangeValue(forKey: Defaults.Key.isFinished)

        var shouldCallOnFinish = false
        lockQueue.sync { [weak self] in
            guard self?.state == .executing else { return }
            self?.state = .finished
            shouldCallOnFinish = true
        }

        didChangeValue(forKey: Defaults.Key.isExecuting)
        didChangeValue(forKey: Defaults.Key.isFinished)

        return shouldCallOnFinish
    }

    func setStateToExecuting() {
        willChangeValue(forKey: Defaults.Key.isExecuting)
        lockQueue.sync { [weak self] in
            self?.state = .executing
        }
        didChangeValue(forKey: Defaults.Key.isExecuting)
    }
}

// MARK: - AsyncOperation.State
private extension AsyncOperation {
    enum State {
        case initialized
        case executing
        case finished
    }
}

// MARK: - Defaults
private extension AsyncOperation {
    enum Defaults {
        enum Key {
            static let isExecuting = "isExecuting"
            static let isFinished = "isFinished"
        }
    }
}
