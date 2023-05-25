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
    /// - Parameter timeout: timeout in second
    /// - Returns: first output
    public func sinkAsynchronously(timeout: TimeInterval = 0) async throws -> Output {
        guard timeout > 0 else {
            return try await sinkAsyncWithNoTimeout()
        }
        return try await sinkAsync(with: timeout)
    }
    
    /// Return a new publisher will ignore the error
    /// - Returns: publisher that will never emit an error
    public func ignoreError() -> Infallible<Output> {
        map { Ignorable.passthrough($0) }
            .replaceError(with: .ignore)
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
    public func replaceError(with recovery: @escaping (Failure) -> Output) -> Infallible<Output> {
        self.catch { error in
            Just(recovery(error))
        }
        .eraseToAnyPublisher()
    }
    
    /// Return new publisher that can recover from error by using a closure that will return new output if needed when error occurs
    /// - Parameter recovery: A closure that accept failure and return output as its replacement. It will pass through the error if the output is nil.
    /// - Returns: publisher with the same type
    public func replaceErrorIfNeeded(with recovery: @escaping (Failure) -> Output?) -> AnyPublisher<Output, Failure> {
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
    
    func sinkAsyncWithNoTimeout() async throws -> Self.Output {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var valueReceived = false
            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        if !valueReceived {
                            continuation.resume(throwing: PublisherToAsyncError.finishedButNoValue)
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    valueReceived = true
                    continuation.resume(returning: value)
                }
        }
    }
    
    func sinkAsync(with timeout: TimeInterval) async throws -> Self.Output {
        return try await withThrowingTaskGroup(of: Output.self) { group in
            group.addTask {
                try await sinkAsynchronously()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw PublisherToAsyncError.timeout
            }
            guard let success = try await group.next() else {
                throw PublisherToAsyncError.failToProduceAnOutput
            }
            group.cancelAll()
            return success
        }
    }
}

extension Publisher where Failure == Never {
    
    /// Return this publisher first output asynchronously and return nil if its finished without value
    /// - Parameter timeout: timeout in second
    /// - Returns: first output
    public func sinkAsynchronously(timeout: TimeInterval = 0) async -> Output? {
        guard timeout > 0 else {
            return try? await sinkAsyncWithNoTimeout()
        }
        return try? await sinkAsync(with: timeout)
    }
}
