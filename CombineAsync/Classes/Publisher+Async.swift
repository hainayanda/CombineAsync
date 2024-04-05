//
//  Publisher+Async.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 28/9/23.
//

import Foundation
import Combine

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
        priority: TaskPriority? = nil,
        receiveCompletion: @Sendable @escaping (Subscribers.Completion<Failure>) async throws -> Void,
        receiveValue: @Sendable @escaping (Output) async throws -> Void) -> AnyCancellable {
            let semaphore = DispatchSemaphore(value: 1)
            let pendingWrappedOutput: Mutable<Output?> = .init(wrapped: nil)
            return self.sink { completion in
                semaphore.wait()
                Task(priority: priority) {
                    try? await receiveCompletion(completion)
                    semaphore.signal()
                }
            } receiveValue: { output in
                guard case .success = semaphore.wait(timeout: .now()) else {
                    pendingWrappedOutput.wrapped = output
                    return
                }
                Task(priority: priority) {
                    try? await receiveValue(output)
                    while let pendingOutput = pendingWrappedOutput.wrapped {
                        pendingWrappedOutput.wrapped = nil
                        try? await receiveValue(pendingOutput)
                    }
                    semaphore.signal()
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
        priority: TaskPriority? = nil,
        receiveCompletion: @Sendable @escaping (Subscribers.Completion<Failure>) async throws -> Void,
        receiveValue: @Sendable @escaping (Output) async throws -> Void) -> AnyCancellable {
            self.sink { completion in
                Task(priority: priority) {
                    try await receiveCompletion(completion)
                }
            } receiveValue: { output in
                Task(priority: priority) {
                    try await receiveValue(output)
                }
            }
        }
    
    /// Transforms all elements from the upstream publisher with a provided async throwable closure.
    /// - Parameter transform: An async throwable closure that takes one element as its parameter and returns a new element.
    /// - Returns: A publisher that uses the provided closure to map elements from the upstream publisher to new elements that it then publishes.
    @inlinable public func asyncTryMap<T>(priority: TaskPriority? = nil, _ transform: @Sendable @escaping (Output) async throws -> T) -> AnyPublisher<T, Error> {
        self.mapError { $0 }
            .flatMap { output in
                Future<T, Error>(priority: priority) {
                    try await transform(output)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Transforms all elements from the upstream publisher with a provided async closure.
    /// If your closure can throw an error, use asyncTryMap(_:) instead.
    /// - Parameter transform: An async closure that takes one element as its parameter and returns a new element.
    /// - Returns: A publisher that uses the provided closure to map elements from the upstream publisher to new elements that it then publishes.
    @inlinable public func asyncMap<T>(priority: TaskPriority? = nil, _ transform: @Sendable @escaping (Output) async -> T) -> AnyPublisher<T, Failure> {
        self.flatMap { output in
            Future<T, Never>(priority: priority) {
                await transform(output)
            }
            .setFailureType(to: Failure.self)
        }
        .eraseToAnyPublisher()
    }
    
    /// Calls an async throwable closure with each received element and publishes any returned optional that has a value.
    /// - Parameter transform: An async closure that receives a value and returns an optional value.
    /// - Returns: Any non-`nil` optional results of the calling the supplied closure.
    @inlinable public func asyncTryCompactMap<T>(priority: TaskPriority? = nil, _ transform: @Sendable @escaping (Output) async throws -> T?) -> AnyPublisher<T, Error> {
        self.asyncTryMap(priority: priority, transform)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    /// Calls an async closure with each received element and publishes any returned optional that has a value.
    /// If your closure can throw an error, use asyncTryCompactMap(_:) instead.
    /// - Parameter transform: An async closure that receives a value and returns an optional value.
    /// - Returns: Any non-`nil` optional results of the calling the supplied closure.
    @inlinable public func asyncCompactMap<T>(priority: TaskPriority? = nil, _ transform: @Sendable @escaping (Output) async -> T?) -> AnyPublisher<T, Failure> {
        self.asyncMap(priority: priority, transform)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Never {
    
    /// Attaches a subscriber with async closure-based behavior.
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// The return value should be held, otherwise the stream will be canceled.
    /// If the output is generated when sink closure is still running, it will not execute next closure right away.
    /// It will store the value and wait until the current sink is finished.
    /// When the sink is finished, then it will only execute the closure using the latest output that stored.
    /// - parameter receiveValue: The async closure to execute on receipt of a value.
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    public func debounceAsyncSink(priority: TaskPriority? = nil, receiveValue: @Sendable @escaping (Output) async throws -> Void) -> AnyCancellable {
        self.debounceAsyncSink(priority: priority, receiveCompletion: { _ in }, receiveValue: receiveValue)
    }
    
    /// Attaches a subscriber with async closure-based behavior.
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// The return value should be held, otherwise the stream will be canceled.
    /// - parameter receiveValue: The async closure to execute on receipt of a value.
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    @inlinable public func asyncSink(priority: TaskPriority? = nil, receiveValue: @Sendable @escaping (Output) async throws -> Void) -> AnyCancellable {
        self.sink { output in
            Task(priority: priority) {
                try await receiveValue(output)
            }
        }
    }
}

private class Mutable<Wrapped> {
    var wrapped: Wrapped
    
    init(wrapped: Wrapped) {
        self.wrapped = wrapped
    }
}
