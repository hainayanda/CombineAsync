//
//  Publisher+Async.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 28/9/23.
//

import Foundation
import Combine

private actor AtomicRunner {
    var value: Bool = false
    
    func run(ifNotFree: () async -> Void, ifFree execute: () async -> Void) async {
        guard !value else {
            await ifNotFree()
            return
        }
        value = true
        await execute()
        value = false
    }
}

private actor Queued<Value> {
    var value: Value?
    
    func queue(_ value: Value) {
        self.value = value
    }
    
    func dequeue() -> Value? {
        let output = self.value
        self.value = nil
        return output
    }
}

extension Publisher {
    
    /// Attaches a subscriber with async closure-based behavior.
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// The return value should be held, otherwise the stream will be canceled.
    /// If the output is generated when sink closure is still running, it will not execute next closure right away.
    /// It will store the value and wait until the current sink is finished.
    /// When the sink is finished, then it will only execute the closure using the latest output that stored.
    /// - parameter receiveComplete: The async closure to execute on completion.
    /// - parameter receiveValue: The async closure to execute on receipt of a value.
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func debounceAsyncSink(
        receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) async -> Void),
        receiveValue: @escaping ((Self.Output) async -> Void)) -> AnyCancellable {
            let runner = AtomicRunner()
            let queued = Queued<Output>()
            return asyncSink(receiveCompletion: receiveCompletion) { output in
                await runner.run {
                    await queued.queue(output)
                } ifFree: {
                    await receiveValue(output)
                    if let pending = await queued.dequeue() {
                        await receiveValue(pending)
                    }
                }
            }
        }
    
    /// Attaches a subscriber with async closure-based behavior.
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// The return value should be held, otherwise the stream will be canceled.
    /// - parameter receiveComplete: The async closure to execute on completion.
    /// - parameter receiveValue: The async closure to execute on receipt of a value.
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    @inlinable public func asyncSink(
        receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) async throws -> Void),
        receiveValue: @escaping ((Self.Output) async throws -> Void)) -> AnyCancellable {
            self.sink { completion in
                Task {
                    try await receiveCompletion(completion)
                }
            } receiveValue: { output in
                Task {
                    try await receiveValue(output)
                }
            }
        }
    
    /// Transforms all elements from the upstream publisher with a provided async throwable closure.
    /// - Parameter transform: An async throwable closure that takes one element as its parameter and returns a new element.
    /// - Returns: A publisher that uses the provided closure to map elements from the upstream publisher to new elements that it then publishes.
    @inlinable public func asyncTryMap<T>(_ transform: @escaping (Output) async throws -> T) -> AnyPublisher<T, Error> {
        self.mapError { $0 }
            .flatMap { output in
                Future<T, Error> {
                    try await transform(output)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Transforms all elements from the upstream publisher with a provided async closure.
    /// If your closure can throw an error, use asyncTryMap(_:) instead.
    /// - Parameter transform: An async closure that takes one element as its parameter and returns a new element.
    /// - Returns: A publisher that uses the provided closure to map elements from the upstream publisher to new elements that it then publishes.
    @inlinable public func asyncMap<T>(_ transform: @escaping (Output) async -> T) -> AnyPublisher<T, Failure> {
        self.flatMap { output in
            Future<T, Never> {
                await transform(output)
            }
            .setFailureType(to: Failure.self)
        }
        .eraseToAnyPublisher()
    }
    
    /// Calls an async throwable closure with each received element and publishes any returned optional that has a value.
    /// - Parameter transform: An async closure that receives a value and returns an optional value.
    /// - Returns: Any non-`nil` optional results of the calling the supplied closure.
    @inlinable public func asyncTryCompactMap<T>(_ transform: @escaping (Output) async throws -> T?) -> AnyPublisher<T, Error> {
        self.asyncTryMap(transform)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    /// Calls an async closure with each received element and publishes any returned optional that has a value.
    /// If your closure can throw an error, use asyncTryCompactMap(_:) instead.
    /// - Parameter transform: An async closure that receives a value and returns an optional value.
    /// - Returns: Any non-`nil` optional results of the calling the supplied closure.
    @inlinable public func asyncCompactMap<T>(_ transform: @escaping (Output) async -> T?) -> AnyPublisher<T, Failure> {
        self.asyncMap(transform)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Never {
    
    /// Attaches a subscriber with async closure-based behavior.
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// The return value should be held, otherwise the stream will be canceled.
    /// - parameter receiveValue: The async closure to execute on receipt of a value.
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    @inlinable public func asyncSink(receiveValue: @escaping ((Self.Output) async throws -> Void)) -> AnyCancellable {
        self.sink { output in
            Task {
                try await receiveValue(output)
            }
        }
    }
}
