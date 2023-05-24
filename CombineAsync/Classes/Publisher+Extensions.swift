//
//  Publisher+Extensions.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 24/5/23.
//

import Foundation
import Combine

public typealias Infallible<Output> = AnyPublisher<Output, Never>

extension Publisher {
    
    /// Return this publisher first output asynchronously or rethrow error if occurss and throw error if its finished without value
    /// - Returns: first output
    public func asynchronously() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
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
    
    /// Return this publisher first output asynchronously or rethrow error if occurss
    /// and throw error if its finished without value
    /// or reach timeout
    /// or fail to produce an output
    /// - Parameter timeout: timeout in second
    /// - Returns: first output
    public func asynchronously(timeout: TimeInterval) async throws -> Output {
        try await withThrowingTaskGroup(of: Output.self) { group in
            group.addTask {
                try await asynchronously()
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
    
    /// Return a new publisher will ignore the error
    /// - Returns: publisher that will never emit an error
    public func ignoreError() -> Infallible<Output> {
        let subject = PassthroughSubject<Output, Never>()
        var cancellable: AnyCancellable?
        cancellable = sink { _ in
            subject.send(completion: .finished)
            cancellable?.cancel()
        } receiveValue: { output in
            subject.send(output)
        }
        return subject.eraseToAnyPublisher()
    }
    
    /// Return new publisher that can recover from error by using a closure that will return new output when error occurs
    /// - Parameter recovery: A closure that accept failure and return output as its replacement
    /// - Returns: publisher that will never emit an error
    public func recoverOnError(with recovery: @escaping (Failure) -> Output) -> Infallible<Output> {
        let subject = PassthroughSubject<Output, Never>()
        var cancellable: AnyCancellable?
        cancellable = sink { completion in
            switch completion {
            case .finished:
                subject.send(completion: .finished)
            case .failure(let error):
                subject.send(recovery(error))
                subject.send(completion: .finished)
            }
            cancellable?.cancel()
        } receiveValue: { output in
            subject.send(output)
        }
        return subject.eraseToAnyPublisher()
    }
    
    /// Return new publisher that can recover from error by using a closure that will return new output if needed when error occurs
    /// - Parameter recovery: A closure that accept failure and return output as its replacement. It will pass through the error if the output is nil.
    /// - Returns: publisher with the same type
    public func recoverOnErrorIfNeeded(with recovery: @escaping (Failure) -> Output?) -> AnyPublisher<Output, Failure> {
        let subject = PassthroughSubject<Output, Failure>()
        var cancellable: AnyCancellable?
        cancellable = sink { completion in
            defer { cancellable?.cancel() }
            switch completion {
            case .finished:
                subject.send(completion: .finished)
            case .failure(let error):
                guard let recover = recovery(error) else {
                    subject.send(completion: completion)
                    return
                }
                subject.send(recover)
                subject.send(completion: .finished)
            }
        } receiveValue: { output in
            subject.send(output)
        }
        return subject.eraseToAnyPublisher()
        
    }
}

extension Publisher where Failure == Never {
    
    /// Return this publisher first output asynchronously and return nil if its finished without value
    /// - Returns: first output
    public func asynchronously() async -> Output? {
        try? await asynchronously()
    }
    
    /// Return this publisher first output asynchronously and return nil if its finished without value
    /// - Returns: first output
    public func asynchronously(timeout: TimeInterval) async -> Output? {
        try? await asynchronously(timeout: timeout)
    }
}
