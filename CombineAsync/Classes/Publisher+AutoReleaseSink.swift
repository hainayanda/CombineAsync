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
    var cancelTask: (() -> Void)?
    
    var state: RetainState { cancellable == nil ? .released: .retained }
    
    init(cancellable: AnyCancellable?, cancelTask: (() -> Void)?) {
        self.cancellable = cancellable
        self.cancelTask = cancelTask
    }
    
    func cancel() {
        cancelTask?()
    }
    
    var deallocatePublisher: AnyPublisher<Void, Never> { $cancellable.deallocatePublisher }
    
    func whenDeallocate(do operation: @escaping () -> Void) -> AnyCancellable {
        $cancellable.whenDeallocate(do: operation)
    }
    
}

extension Publisher {
    
    @discardableResult
    /// Sink while ignoring the cancellable. The cancellable then will be retained by the subscriber, timeout if given and object,
    /// and will be released when the publisher emit completion or when the given timeout has been reach  or when the given object is being released, whichever happens first
    /// - Parameters:
    ///   - object: object where the cancellable will be retained to
    ///   - timeout: object where the cancellable will be retained to
    ///   - receiveCompletion: The closure to execute on completion.
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: AutoReleaseCancellable
    public func autoReleaseSink(
        retainedTo object: AnyObject,
        timeout: TimeInterval? = nil,
        receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void),
        receiveValue: @escaping ((Output) -> Void)) -> RetainStateCancellable {
            guard timeout != 0 else {
                defer { receiveCompletion(.finished) }
                return EmptyCancellable()
            }
            var cancellable: AnyCancellable?
            var deallocateCancellable: AnyCancellable?
            var timerCancellable: AnyCancellable?
            var isReleased: Bool = false
            func release() {
                guard !isReleased else { return }
                isReleased = true
                deallocateCancellable?.cancel()
                timerCancellable?.cancel()
                cancellable?.cancel()
                deallocateCancellable = nil
                timerCancellable = nil
                cancellable = nil
            }
            cancellable = sink { completion in
                guard !isReleased else { return }
                release()
                receiveCompletion(completion)
            } receiveValue: { value in
                receiveValue(value)
            }
            deallocateCancellable = deallocatePublisher(of: object)
                .sink(receiveValue: release)
            if let timeout, timeout > 0 {
                timerCancellable = Timer.publish(every: timeout, on: .main, in: .default)
                    .autoconnect()
                    .sink { _ in
                        release()
                        receiveCompletion(.finished)
                    }
            }
            return AutoReleaseCancellable(cancellable: cancellable, cancelTask: release)
        }
    
    @discardableResult
    /// Sink while ignoring the cancellable. The cancellable then will be retained by the subscriber and timeout,
    /// and will be released when the publisher emit completion or when the timeout has been reach whichever happens first
    /// - Parameters:
    ///   - timeout: object where the cancellable will be retained to. Default value is 30 seconds
    ///   - receiveCompletion: The closure to execute on completion.
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: AutoReleaseCancellable
    public func autoReleaseSink(
        timeout: TimeInterval = 30,
        receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void),
        receiveValue: @escaping ((Output) -> Void)) -> RetainStateCancellable {
            guard timeout != 0 else {
                defer { receiveCompletion(.finished) }
                return EmptyCancellable()
            }
            var cancellable: AnyCancellable?
            var timerCancellable: AnyCancellable?
            var isReleased: Bool = false
            func release() {
                guard !isReleased else { return }
                isReleased = true
                timerCancellable?.cancel()
                cancellable?.cancel()
                timerCancellable = nil
                cancellable = nil
            }
            cancellable = sink { completion in
                guard !isReleased else { return }
                release()
                receiveCompletion(completion)
            } receiveValue: { value in
                receiveValue(value)
            }
            if timeout > 0 {
                timerCancellable = Timer.publish(every: timeout, on: .main, in: .default)
                    .autoconnect()
                    .sink { _ in
                        release()
                        receiveCompletion(.finished)
                    }
            }
            return AutoReleaseCancellable(cancellable: cancellable, cancelTask: release)
        }
}

extension Publisher where Failure == Never {
    
    @discardableResult
    /// Sink while ignoring the cancellable. The cancellable then will be retained by the subscriber, timeout if given and object,
    /// and will be released when the publisher emit completion or when the given timeout has been reach  or when the given object is being released, whichever happens first
    /// - Parameters:
    ///   - object: object where the cancellable will be retained to
    ///   - timeout: object where the cancellable will be retained to
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: AutoReleaseCancellable
    @inlinable public func autoReleaseSink(
        retainedTo object: AnyObject,
        timeout: TimeInterval? = nil,
        receiveValue: @escaping ((Output) -> Void)) -> RetainStateCancellable {
            autoReleaseSink(retainedTo: object, timeout: timeout, receiveCompletion: { _ in }, receiveValue: receiveValue)
        }
    
    @discardableResult
    /// Sink while ignoring the cancellable. The cancellable then will be retained by the subscriber and timeout,
    /// and will be released when the publisher emit completion or when the timeout has been reach whichever happens first
    /// - Parameters:
    ///   - timeout: object where the cancellable will be retained to. Default value is 30 seconds
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: AutoReleaseCancellable
    @inlinable public func autoReleaseSink(
        timeout: TimeInterval = 30,
        receiveValue: @escaping ((Output) -> Void)) -> RetainStateCancellable {
            autoReleaseSink(timeout: timeout, receiveCompletion: { _ in }, receiveValue: receiveValue)
        }
}
