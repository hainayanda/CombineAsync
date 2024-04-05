//
//  Publisher+AutoReleaseSink.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 18/6/23.
//

import Foundation
import Combine
import Retain

public protocol RetainStateCancellable: Cancellable, DeallocateObservable {
    var state: RetainState { get }
    func eraseToAnyCancellable() -> AnyCancellable
}

public extension RetainStateCancellable {
    @inlinable func eraseToAnyCancellable() -> AnyCancellable {
        AnyCancellable(self)
    }
}

public enum RetainState {
    case retained
    case released
}

class EmptyCancellable: RetainStateCancellable {
    let state: RetainState = .released
    
    func cancel() { }
}

public extension TimeInterval {
    static let none: TimeInterval = -1
}

class AutoReleaseCancellable: RetainStateCancellable {
    
    @WeakSubject var cancellable: AnyCancellable?
    
    var state: RetainState { cancellable == nil ? .released: .retained }
    
    init(cancellable: AnyCancellable?) {
        self.cancellable = cancellable
    }
    
    func cancel() {
        cancellable?.cancel()
        cancellable = nil
    }
    
    var deallocatePublisher: AnyPublisher<Void, Never> { $cancellable.deallocatePublisher }
    
    func whenDeallocate(do operation: @escaping () -> Void) -> AnyCancellable {
        $cancellable.whenDeallocate(do: operation)
    }
    
}

extension Publisher {
    
    /// Sink while ignoring the cancellable. The cancellable then will be retained by the subscriber.
    /// and will be released when the publisher emit completion or when the given object is being released, whichever happens first
    /// - Parameters:
    ///   - object: object where the cancellable will be retained to
    ///   - receiveCompletion: The closure to execute on completion.
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: AutoReleaseCancellable
    @discardableResult
    public func autoReleaseSink(
        retainedTo object: AnyObject,
        receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void),
        receiveValue: @escaping ((Output) -> Void)) -> RetainStateCancellable {
            let objectDeallocatePublisher = deallocatePublisher(of: object).map { _ in true }
                .setFailureType(to: Failure.self)
                .prepend(false)
            var cancellable: AnyCancellable?
            cancellable = Publishers.CombineLatest(self, objectDeallocatePublisher)
                .autoReleaseSink(receiveCompletion: receiveCompletion) { output, deallocated in
                    guard !deallocated else {
                        cancellable?.cancel()
                        cancellable = nil
                        return
                    }
                    receiveValue(output)
                }
            guard let cancellable else { return EmptyCancellable() }
            return AutoReleaseCancellable(cancellable: cancellable)
        }
    
    /// Sink while ignoring the cancellable. The cancellable then will be retained by the subscriber,
    /// and will be released when the publisher emit completion or when the timeout has been reach whichever happens first
    /// - Parameters:
    ///   - timeout: object where the cancellable will be retained to. Default value is 30 seconds
    ///   - receiveCompletion: The closure to execute on completion.
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: AutoReleaseCancellable
    @discardableResult
    public func autoReleaseSink(
        timeout: TimeInterval,
        receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void),
        receiveValue: @escaping ((Output) -> Void)) -> RetainStateCancellable {
            guard timeout > 0 else {
                receiveCompletion(.finished)
                return EmptyCancellable()
            }
            let cancellable = self.timeout(.seconds(timeout), scheduler: DispatchQueue.main)
                .autoReleaseSink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
            return AutoReleaseCancellable(cancellable: cancellable)
        }
    
    /// Sink while ignoring the cancellable. The cancellable then will be retained by the subscriber,
    /// and will be released when the publisher emit completion.
    /// Be advised that using this might leak the publisher unless you are sure that it will emit completion in the future.
    /// - Parameters:
    ///   - receiveCompletion: The closure to execute on completion.
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: AnyCancellable
    @discardableResult
    public func autoReleaseSink(
        receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void),
        receiveValue: @escaping ((Output) -> Void)) -> AnyCancellable {
            var cancellable: AnyCancellable?
            
            let completionPublisher = justCompletion().map { _ in true }.prepend(false)
            let waitingPublisher = self.map { WaitingOutput.published($0) }.prepend(.unpublished)
            
            cancellable = Publishers.CombineLatest(waitingPublisher, completionPublisher)
                .sink { completion in
                    cancellable?.cancel()
                    cancellable = nil
                    receiveCompletion(completion)
                } receiveValue: { published, invalidated in
                    guard !invalidated else {
                        cancellable?.cancel()
                        cancellable = nil
                        receiveCompletion(.finished)
                        return
                    }
                    switch published {
                    case .published(let output):
                        receiveValue(output)
                    case .unpublished:
                        return
                    }
                }
            return cancellable ?? EmptyCancellable().eraseToAnyCancellable()
        }
    
}

extension Publisher where Failure == Never {
    
    /// Sink while ignoring the cancellable. The cancellable then will be retained by the subscriber, timeout if given and object,
    /// and will be released when the publisher emit completion or when the given object is being released, whichever happens first
    /// - Parameters:
    ///   - object: object where the cancellable will be retained to
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: AutoReleaseCancellable
    @discardableResult
    @inlinable public func autoReleaseSink(
        retainedTo object: AnyObject,
        receiveValue: @escaping ((Output) -> Void)) -> RetainStateCancellable {
            autoReleaseSink(retainedTo: object, receiveCompletion: { _ in }, receiveValue: receiveValue)
        }
    
    /// Sink while ignoring the cancellable. The cancellable then will be retained by the subscriber and timeout,
    /// and will be released when the publisher emit completion or when the timeout has been reach whichever happens first
    /// - Parameters:
    ///   - timeout: object where the cancellable will be retained to. Default value is 30 seconds
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: AutoReleaseCancellable
    @discardableResult
    @inlinable public func autoReleaseSink(
        timeout: TimeInterval,
        receiveValue: @escaping ((Output) -> Void)) -> RetainStateCancellable {
            autoReleaseSink(timeout: timeout, receiveCompletion: { _ in }, receiveValue: receiveValue)
        }
}

// MARK: Private extensions

private enum WaitingOutput<Output> {
    case unpublished
    case published(Output)
}
