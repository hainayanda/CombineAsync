//
//  Publisher+Extensions.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 24/5/23.
//

import Foundation
import Combine

public typealias Infallible<Output> = AnyPublisher<Output, Never>

enum Ignorable<Output> {
    case ignore
    case passthrough(Output)
}

extension Publisher {
    
    /// Return this publisher first output asynchronously or rethrow error if occurss
    /// and throw error if its finished without value
    /// or reach timeout
    /// or fail to produce an output
    /// - Parameter timeout: timeout in second, by default is 30 seconds
    /// - Returns: first output
    public func sinkAsynchronously(timeout: TimeInterval = 30) async throws -> Output {
        return try await sinkAsync(with: timeout)
    }
    
    /// Return a new publisher will ignore the error
    /// - Returns: publisher that will never emit an error
    public func ignoreError() -> Infallible<Output> {
        map { Ignorable.passthrough($0) }
            .catch { _ in Just(Ignorable.ignore) }
            .compactMap { ignorable in
                switch ignorable {
                case .passthrough(let output):
                    return output
                case .ignore:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Return new publisher that can recover from error by using a closure that will return new output when error occurs
    /// - Parameter recovery: A closure that accept failure and return output as its replacement
    /// - Returns: publisher that will never emit an error
    @inlinable public func replaceError(with recovery: @escaping (Failure) -> Output) -> Infallible<Output> {
        self.catch { error in
            Just(recovery(error))
        }.eraseToAnyPublisher()
    }
    
    /// Return new publisher that can recover from error by using a closure that will return new output if needed when error occurs
    /// - Parameter recovery: A closure that accept failure and return output as its replacement. It will pass through the error if the output is nil.
    /// - Returns: publisher with the same type
    @inlinable public func replaceErrorIfNeeded(with recovery: @escaping (Failure) -> Output?) -> AnyPublisher<Output, Failure> {
        tryCatch { error in
            guard let recover = recovery(error) else {
                throw error
            }
            return Just(recover)
        }
        // swiftlint:disable:next force_cast
        .mapError { $0 as! Failure }
        .eraseToAnyPublisher()
    }
    
    // MARK: Internal methods
    
    func autoReleaseSinkAsync(timeout: TimeInterval) async throws -> Self.Output {
        try await withCheckedThrowingContinuation { continuation in
            var valueReceived = false
            first().autoReleaseSink(timeout: timeout) { result in
                switch result {
                case .finished:
                    if !valueReceived {
                        continuation.resume(throwing: CombineAsyncError.finishedButNoValue)
                    }
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            } receiveValue: { value in
                valueReceived = true
                continuation.resume(returning: value)
            }
        }
    }
    
    func sinkAsync(with timeout: TimeInterval) async throws -> Self.Output {
        try await withThrowingTaskGroup(of: Output.self) { group in
            group.addTask {
                try await autoReleaseSinkAsync(timeout: timeout)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw CombineAsyncError.timeout
            }
            guard let success = try await group.next() else {
                throw CombineAsyncError.failToProduceAnOutput
            }
            group.cancelAll()
            return success
        }
    }
}

extension Publisher where Failure == Never {
    
    /// Return this publisher first output asynchronously and return nil if its finished without value
    /// - Parameter timeout: timeout in second, by default is 30 seconds
    /// - Returns: first output
    public func sinkAsynchronously(timeout: TimeInterval = 30) async -> Output? {
        return try? await sinkAsync(with: timeout)
    }
    
    /// Assigns each element from a publisher to a property on an class instances object. Different from assign, it will store the object using weak variable so it will not retain the object.
    /// - Parameters:
    ///   - keyPath: A key path that indicates the property to assign.
    ///   - object: The object that contains the property. The subscriber assigns the object’s property every time it receives a new value.
    /// - Returns: An ``AnyCancellable`` instance.
    @inlinable public func weakAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root) -> AnyCancellable {
        sink { [weak object] output in
            object?[keyPath: keyPath] = output
        }
    }
    
    @discardableResult
    /// Assigns each element from a publisher to a property on an class instances object. Different from assign, it will store the object using weak variable so it will not retain the object. It will automatically cancel the cancellable when object is released
    /// - Parameters:
    ///   - keyPath: A key path that indicates the property to assign.
    ///   - object: The object that contains the property. The subscriber assigns the object’s property every time it receives a new value.
    /// - Returns: An ``AnyCancellable`` instance.
    @inlinable public func autoReleaseAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root) -> RetainStateCancellable {
        autoReleaseSink(retainedTo: object) { [weak object] output in
            object?[keyPath: keyPath] = output
        }
    }
}
