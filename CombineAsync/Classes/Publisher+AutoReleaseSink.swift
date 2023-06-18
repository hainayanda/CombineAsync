//
//  Publisher+AutoReleaseSink.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 18/6/23.
//

import Foundation
import Combine
import Retain

public protocol RetainStateCancellable: Cancellable {
    var state: RetainState { get }
    func eraseToAnyCancellable() -> AnyCancellable
}

public enum RetainState {
    case retained
    case released
}

public struct AutoReleaseCancellable: RetainStateCancellable {
    
    weak var cancellable: AnyCancellable?
    weak var timer: Timer?
    var cancelTask: (() -> Void)?
    
    init(cancellable: AnyCancellable?, timer: Timer?, cancelTask: (() -> Void)?) {
        self.cancellable = cancellable
        self.timer = timer
        self.cancelTask = cancelTask
    }
    
    public var state: RetainState { cancellable == nil ? .released: .retained }
    
    public func cancel() {
        cancelTask?()
    }
    
    public func eraseToAnyCancellable() -> AnyCancellable {
        AnyCancellable(self)
    }
}

extension Publisher {
    
    @discardableResult
    /// Sink while ignoring the cancellable. The cancellable then will be retained by the subscriber, timeout if given and object if given,
    /// and will be released when the publisher emit completion or when the given timeout has been reach  or the when the given object is being released, whichever happens first
    /// - Parameters:
    ///   - object: object where the cancellable will be retained to
    ///   - timeout: object where the cancellable will be retained to
    ///   - receiveCompletion: The closure to execute on completion.
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: AutoReleaseCancellable
    public func autoReleaseSink(
        retainedTo object: AnyObject? = nil,
        timeout: TimeInterval? = nil,
        receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void),
        receiveValue: @escaping ((Output) -> Void)) -> RetainStateCancellable {
            var cancellable: AnyCancellable?
            var timer: Timer?
            func release() {
                timer?.invalidate()
                timer = nil
                cancellable?.cancel()
                cancellable = nil
            }
            cancellable = sink { completion in
                receiveCompletion(completion)
                release()
            } receiveValue: { value in
                receiveValue(value)
            }
            if let object {
                deallocatePublisher(of: object).autoReleaseSink(timeout: timeout) {
                    release()
                }
            }
            if let timeout = timeout {
                timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
                    release()
                }
            }
            return AutoReleaseCancellable(cancellable: cancellable, timer: timer, cancelTask: release)
        }
}

extension Publisher where Failure == Never {
    
    @discardableResult
    /// Sink while ignoring the cancellable. The cancellable then will be retained by the subscriber, timeout if given and object if given,
    /// and will be released when the publisher emit completion or when the given timeout has been reach  or the when the given object is being released, whichever happens first
    /// - Parameters:
    ///   - object: object where the cancellable will be retained to
    ///   - timeout: object where the cancellable will be retained to
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: AutoReleaseCancellable
    public func autoReleaseSink(
        retainedTo object: AnyObject? = nil,
        timeout: TimeInterval? = nil,
        receiveValue: @escaping ((Output) -> Void)) -> RetainStateCancellable {
            autoReleaseSink(retainedTo: object, receiveCompletion: { _ in }, receiveValue: receiveValue)
        }
}
